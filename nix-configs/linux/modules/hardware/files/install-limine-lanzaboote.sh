export LC_ALL=C

fail() {
  printf 'Limine: %s\n' "$*" >&2
  exit 1
}

partition=$(findmnt --mountpoint "$esp" --noheadings --output SOURCE) || fail "$esp is not mounted"
[[ $(findmnt --mountpoint "$esp" --noheadings --output FSTYPE) == vfat ]] || fail "$esp is not a FAT ESP"
exec 9>/run/lock/install-limine-lanzaboote.lock
flock 9
"$lanzaboote_hook" "$@"

profiles=/nix/var/nix/profiles
target=$(realpath -- "$1")
current=$(readlink "$profiles/system")
current=${current##*/}
entry_pattern='^nixos-generation-([0-9]+)(-specialisation-([[:alnum:]_.-]+))?-[a-z2-7]{52}\.efi$'
declare -A seen=()
entries=()

for uki in "$esp"/EFI/Linux/nixos-generation-*.efi; do
  name=${uki##*/}
  [[ $name =~ $entry_pattern ]] || continue
  generation=${BASH_REMATCH[1]}
  specialisation=${BASH_REMATCH[3]}
  system=$profiles/system-$generation-link
  if [[ -n $specialisation ]]; then
    system+=/specialisation/$specialisation
  fi
  [[ -e $system ]] || continue

  entry_id=$generation:$specialisation
  [[ ! -v seen[$entry_id] ]] || fail "multiple EFI images for $entry_id"
  seen[$entry_id]=1
  sbverify --cert "$cert" "$uki" >/dev/null
  entry_order=0
  [[ -z $specialisation ]] || entry_order=1
  entries+=("$generation $entry_order $name $system")
done

((${#entries[@]})) || fail 'no Lanzaboote EFI images found'
sorted_entries=$(printf '%s\n' "${entries[@]}" | sort -k1,1nr -k2,2n -k3,3)
menu=()
entry_number=0
default_entry=0
while read -r generation _ name system; do
  [[ $name =~ $entry_pattern ]]
  specialisation=${BASH_REMATCH[3]}
  menu+=("/NixOS generation $generation${specialisation:+ ($specialisation)}" '    protocol: efi' "    path: boot():/EFI/Linux/$name" '')
  ((entry_number += 1))
  if [[ $(realpath -e -- "$system") == "$target" ]] &&
    { ((default_entry == 0)) || [[ system-$generation-link == "$current" ]]; }; then
    default_entry=$entry_number
  fi
done <<< "$sorted_entries"
((default_entry > 0)) || fail 'no signed EFI image for the requested system'

destination=$esp/EFI/limine-lanzaboote
stage=$(mktemp -d "$esp/EFI/.limine-lanzaboote.XXXXXXXX")
trap 'if [[ -d $stage ]]; then rm -f -- "$stage/limine.conf" "$stage/BOOTX64.EFI" "$stage/unsigned.efi"; rmdir -- "$stage"; fi' EXIT

printf '%s\n' "timeout: $timeout" "default_entry: $default_entry" 'editor_enabled: no' '' "${menu[@]}" > "$stage/limine.conf"
checksum=$(b2sum < "$stage/limine.conf")
cat -- "$limine_efi" > "$stage/unsigned.efi"
limine enroll-config "$stage/unsigned.efi" "${checksum%% *}"
sbsign --key "$key" --cert "$cert" --output "$stage/BOOTX64.EFI" "$stage/unsigned.efi"
rm -- "$stage/unsigned.efi"
sbverify --cert "$cert" "$stage/BOOTX64.EFI" >/dev/null

# Publish the EFI application and its authenticated config together.
sync -f "$stage"
if [[ -d $destination ]]; then
  mv --exchange --no-copy -T -- "$stage" "$destination"
else
  mv -T -- "$stage" "$destination"
fi
sync -f "$destination"

if [[ ${NIXOS_INSTALL_BOOTLOADER:-0} == 1 ]]; then
  device=$(lsblk --nodeps --noheadings --output PKNAME,PARTN,PARTUUID "$partition")
  read -r disk partnum partuuid <<< "$device"
  [[ -n $disk && $partnum =~ ^[0-9]+$ && $partuuid =~ ^[[:xdigit:]-]{36}$ ]] || fail 'could not identify the GPT ESP'
  efi_path='\EFI\limine-lanzaboote\BOOTX64.EFI'
  efi_entries=$(efibootmgr --verbose)
  if ! grep -Fi "GPT,$partuuid," <<< "$efi_entries" | grep -Fi "$efi_path" >/dev/null; then
    efibootmgr --create --disk "/dev/$disk" --part "$partnum" --label 'Limine (Lanzaboote)' --loader "$efi_path"
  fi
fi
