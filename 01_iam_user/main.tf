# 01: IAMユーザーを作成
resource "aws_iam_user" "tuser" {
  name = "tuser"
}

# 01: コンソールログイン用の初期パスワードを生成する
resource "aws_iam_user_login_profile" "tuser" {
  user                    = aws_iam_user.tuser.name
  password_reset_required = false
}

# 01: コンソールの IAM > Users 一覧を表示する権限を付与
resource "aws_iam_user_policy" "list_users" {
  name = "list-users"
  user = aws_iam_user.tuser.name

  # AWS Console > IAM > Users を表示するための権限
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:ListUsers"
      Resource = "*"
    }]
  })
}
