{
  autoPatchelfHook,
  buildNpmPackage,
  fetchurl,
  jq,
  lib,
  nodejs_22,
  stdenv,
}:
buildNpmPackage rec {
  pname = "cf-cli";
  version = "1.0.0-beta.20";

  src = fetchurl {
    url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
    hash = "sha256-ITv9lUJXSut0qeOU2cfXkxq1dFxJQorMj18bqLUlMzE=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-eUs26cJR+WlEIN+c2aRdh8lwTuol8qhyFFj1iqG8PQY=";
  dontNpmBuild = true;
  # workerd resolves its optional binary at runtime; its installer executes it
  # before autoPatchelfHook can fix the Linux interpreter.
  npmRebuildFlags = ["--ignore-scripts"];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [stdenv.cc.cc.lib];

  postPatch = ''
    # The npm release is already built; lock only its runtime dependencies.
    ${lib.getExe jq} 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${./package-lock.json} package-lock.json
  '';

  meta = {
    description = "Cloudflare command-line interface";
    homepage = "https://github.com/cloudflare/cf";
    license = with lib.licenses; [mit asl20];
    mainProgram = "cf";
    platforms = ["x86_64-linux" "aarch64-darwin"];
  };
}
