# Flake input updates

`.github/workflows/update-flake-lock.yml`は毎週月曜日12:15 JSTに`nix flake update`を実行し、全inputの更新を1つのPRへまとめます。PRは自動mergeせず、通常のPR CIで全NixOS構成を検証します。

## GitHub App

更新PRを通常の`pull_request` workflowで検証するため、リポジトリ専用GitHub Appの短命installation tokenを使用します。

1. GitHubのDeveloper settingsでGitHub Appを作成する。
2. Repository accessを`T4ko0522/dotfiles`のみに制限する。
3. Repository permissionsでContentsとPull requestsをRead and writeにする。
4. Appを`T4ko0522/dotfiles`へinstallする。
5. Client IDをRepository variable `FLAKE_UPDATER_CLIENT_ID`へ登録する。
6. Private keyをRepository secret `FLAKE_UPDATER_PRIVATE_KEY`へ登録する。

AppのWebhookは不要です。workflowは更新処理が完了した後に、有効期限の短いinstallation tokenを発行します。

## Manual run

Actionsの`Update flake lock`から`workflow_dispatch`を実行します。更新がなければPRは作成されません。既存の`automation/update-flake-lock` PRがある場合は同じPRが更新されます。
