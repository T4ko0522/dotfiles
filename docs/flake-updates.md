# Flake input updates

`.github/workflows/update-flake-lock.yml`は毎朝08:15 JST（cronはUTCの`15 23 * * *`）にmasterで`nix flake update`を実行し、差分があれば`flake.lock`だけをmasterへ直接コミットします。GitHub APIで署名付きコミットを作成し、更新処理中にmasterが進んだ場合は失敗して上書きを防ぎます。起動予定時刻はGitHub側の混雑で遅れることがあります。

## GitHub App

更新コミットによる`push` workflowを起動するため、リポジトリ専用GitHub Appの短命installation tokenを使用します。

1. GitHubのDeveloper settingsでGitHub Appを作成する。
2. Repository accessを`T4ko0522/dotfiles`のみに制限する。
3. Repository permissionsでContentsをRead and writeにする。
4. Appを`T4ko0522/dotfiles`へinstallする。
5. Client IDをRepository variable `FLAKE_UPDATER_CLIENT_ID`へ登録する。
6. Private keyをRepository secret `FLAKE_UPDATER_PRIVATE_KEY`へ登録する。

AppのWebhookは不要です。workflowは更新処理が完了し、差分がある場合だけ、有効期限の短いinstallation tokenを発行します。masterへの直接コミットを許可するbranch protection / rulesetの設定が必要です。

## Manual run

Actionsの`Update flake lock`から`workflow_dispatch`を実行します。手動実行でも更新対象はmasterです。更新がなければコミットは作成されません。

masterへのすべてのpushは`lint.yml`と`publish-cache.yml`の対象です。lock更新も構文・整形・設定の検証とbuild・署名・cache publishを起動します。publishは同時実行を防ぎますが、待機中のrunが置き換わることがあるため、各pushの個別完了は保証しません。
