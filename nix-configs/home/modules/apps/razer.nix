{pkgs, ...}: let
  # Razer マウスへ起動時に適用する設定値。変えたい場合はここを編集する。
  # OpenRazer はランタイム設定なので、graphical-session ごとに 1 度適用する。
  razer-config =
    pkgs.writers.writePython3Bin "razer-config" {
      libraries = [pkgs.python3Packages.openrazer];
      flakeIgnore = ["E501"];
    } ''
      import sys
      import time

      import openrazer.client as rc

      TARGET_DPI = 1600
      TARGET_POLL_RATE = 1000
      RETRIES = 30
      INTERVAL = 1.0


      def good_mice():
          # 誤認識 (UNKNOWN_xxxx, openrazer#2487) を除き、DPI 制御できるマウスのみ返す
          try:
              dm = rc.DeviceManager()
          except Exception:
              return []
          mice = []
          for dev in dm.devices:
              if dev.type != "mouse":
                  continue
              if "UNKNOWN" in (dev.name or "").upper():
                  continue
              if not dev.has("dpi"):
                  continue
              mice.append(dev)
          return mice


      def apply_settings(dev):
          if dev.has("dpi"):
              if dev.has("available_dpi"):
                  dev.dpi = (TARGET_DPI, 0)
              else:
                  dev.dpi = (TARGET_DPI, TARGET_DPI)
          if dev.has("poll_rate"):
              dev.poll_rate = TARGET_POLL_RATE


      def main():
          mice = []
          for _ in range(RETRIES):
              mice = good_mice()
              if mice:
                  break
              time.sleep(INTERVAL)
          if not mice:
              print("razer-config: no correctly-identified mouse found", file=sys.stderr)
              return 0
          for dev in mice:
              try:
                  apply_settings(dev)
                  poll = dev.poll_rate if dev.has("poll_rate") else "n/a"
                  print("razer-config: {0}: dpi={1} poll_rate={2}".format(dev.name, dev.dpi, poll))
              except Exception as exc:
                  print("razer-config: {0}: failed: {1}".format(dev.name, exc), file=sys.stderr)
          return 0


      if __name__ == "__main__":
          sys.exit(main())
    '';
in {
  systemd.user.services.razer-config = {
    Unit = {
      Description = "Apply Razer mouse DPI and polling rate via OpenRazer";
      After = ["openrazer-daemon.service"];
      Wants = ["openrazer-daemon.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${razer-config}/bin/razer-config";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
