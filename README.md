# AWS: いったんIAMについて整理しとこ！

Zennの記事「手を動かしながら学ぶAWS IAMの基礎」のサンプルコード。

URL: To be updated

## Terraform の実行

Terraform と AWS CLI を用意し、`terraform` プロファイルで対象の AWS アカウントにログインする。Terraform の AWS Provider はこのプロファイルと東京リージョン（`ap-northeast-1`）を使用する。

```sh
aws login --profile terraform
aws sts get-caller-identity --profile terraform
```

各ディレクトリは独立した構成とローカル state を持つ。試したいディレクトリを指定して `init`、`apply` を実行する。以下は01の例。`apply` 時に聞かれる `aws_account_id` には、上の `get-caller-identity` で表示された `Account` を入力する。

```sh
EXAMPLE_DIR=01_iam_user
terraform -chdir="$EXAMPLE_DIR" init
terraform -chdir="$EXAMPLE_DIR" apply
```

確認後、同じディレクトリで `destroy` を実行する。ここでも同じ `aws_account_id` を入力する。

```sh
terraform -chdir="$EXAMPLE_DIR" destroy
```

`EXAMPLE_DIR` を以下のいずれかに替えれば、各章を同じ手順で試せる。

| ディレクトリ | 内容 |
| --- | --- |
| `01_iam_user` | IAMユーザーと Users 一覧の閲覧用インラインポリシー |
| `02_iam_group` | `tuser` だけを `developer` に所属させ、`ListGroups` の権限を比較 |
| `03_managed_policy` | `tuser` は AWS 管理ポリシー、`tuser2` は直接付与したカスタマー管理ポリシーを使用 |
| `04_iam_role` | 03 のユーザー・グループを継承し、`tuser` が引き受ける IAM ロールを追加 |
| `05_weather_log_system` | 天気を取得する Lambda と保存先の S3 |
| `06_s3_read_access/user-inline-policy` | ユーザーのインラインポリシーで S3 を閲覧 |
| `06_s3_read_access/bucket-policy` | バケットポリシーで S3 を閲覧 |
| `06_s3_read_access/assume-role` | ロールを引き受けて S3 を閲覧 |

01〜04と06の各方式は、いずれも `tuser` という名前の IAM ユーザーを作る。02〜06は比較用の `tuser2` も作成し、どのグループにも所属させない。02では `tuser2` に Users 一覧用のインラインポリシーを付け、03〜06ではIAM閲覧用のカスタマー管理ポリシーを直接付ける。同時に `apply` せず、前のディレクトリを `destroy` してから次を試す。05・06では `destroy` 時に S3 内の天気スナップショットも削除される。

01〜04のコンソールログイン URL と初期パスワードは、`apply` 後に次のコマンドでクリップボードにコピーできる。

```sh
terraform -chdir="$EXAMPLE_DIR" output -raw iam_user_console_sign_in_url | pbcopy
terraform -chdir="$EXAMPLE_DIR" output -raw iam_user_console_password | pbcopy
```

02〜06の `tuser2` は `tuser2_console_sign_in_url` と `tuser2_console_password`、05・06の運用ユーザーは `weather_operator_console_sign_in_url` と `weather_operator_console_password`、06の `tuser` は `tuser_console_sign_in_url` と `tuser_console_password` を出力する。05の運用ユーザーは初回ログイン時にパスワード変更が必要で、変更後は初期パスワードの出力値を使用できない。パスワードやローカル state を共有・コミットしないこと。

02で権限を比べる場合、両ユーザーともインラインポリシーで IAM の Users 一覧を表示できる。`developer` グループに所属する `tuser` だけが User groups 一覧も表示できる。グループ詳細の閲覧権限は付与していない。

```sh
terraform -chdir=02_iam_group output -raw tuser2_console_sign_in_url | pbcopy
terraform -chdir=02_iam_group output -raw tuser2_console_password | pbcopy
```

03では `developer` グループに AWS 管理ポリシー `IAMFullAccess` を付け、`tuser2` には自作したIAM閲覧用のカスタマー管理ポリシーを直接付ける。AWSコンソールの IAM > Policies で両ポリシーの種類を確認できる。`tuser2` はIAMを閲覧できるが、IAMユーザーやグループの作成・変更はできない。作成権限の差を実際のリソース作成なしで判定したい場合は、IAM Policy Simulator で `iam:CreateUser` を比較する。

```sh
terraform -chdir=03_managed_policy output -raw managed_policy_arn
terraform -chdir=03_managed_policy output -raw customer_managed_policy_arn
```

04では `tuser` でコンソールにサインインした後、AWS CLI で同じユーザーとしてログインし、ロール用プロファイルから引き受けを確認できる。`aws login` には AWS CLI 2.32.0 以降が必要。

```sh
aws login --profile tuser --region ap-northeast-1
aws sts get-caller-identity --profile tuser
aws configure set role_arn "$(terraform -chdir=04_iam_role output -raw iam_role_arn)" --profile tuser-role
aws configure set source_profile tuser --profile tuser-role
aws configure set region ap-northeast-1 --profile tuser-role
aws sts get-caller-identity --profile tuser-role
```

最後の `Arn` が `assumed-role/demo-user-role/` を含めば成功。04のロールには権限ポリシーを付けていないため、この例では引き受けと呼び出し元の確認だけを行う。

## 章ごとの差分

`git diff --no-index` なら、Git に追加していないファイルも比較できる。まずは各章の `main.tf` を比較する。

```sh
git diff --no-index -- 01_iam_user/main.tf 02_iam_group/main.tf
git diff --no-index -- 02_iam_group/main.tf 03_managed_policy/main.tf
git diff --no-index -- 03_managed_policy/main.tf 04_iam_role/main.tf
git diff --no-index -- 04_iam_role/main.tf 05_weather_log_system/main.tf
git diff --no-index -- 05_weather_log_system/main.tf 06_s3_read_access/user-inline-policy/main.tf
git diff --no-index -- 05_weather_log_system/main.tf 06_s3_read_access/bucket-policy/main.tf
git diff --no-index -- 05_weather_log_system/main.tf 06_s3_read_access/assume-role/main.tf
```

`01` から `02` はユーザーの定義を残し、末尾にグループと `tuser2` を追加している。`02` から `03` はグループのインラインポリシーを AWS 管理ポリシーに置換し、`tuser2` のインラインポリシーをカスタマー管理ポリシーに置換する。`03` から `04` は既存のユーザー・グループ定義を残し、ファイル末尾にロールと引き受けの設定を追加している。`05` ではロールの信頼先が `tuser` から Lambda に変わり、天気ログ用の構成に切り替わる。`provider.tf`、`variables.tf`、`outputs.tf` を見る場合は、上のコマンドの両方のファイル名を置き換える。たとえばロール方式の出力差分は次のとおり。

```sh
git diff --no-index -- 05_weather_log_system/outputs.tf 06_s3_read_access/assume-role/outputs.tf
```

差分がある場合、`git diff --no-index` の終了コードは `1` になる。
