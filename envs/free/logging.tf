# Off-box evidence: Falco alerts, the Kubernetes audit log, application logs.
# The lab box may only APPEND (create a stream, put events). It has no permission
# to delete or change log groups, streams or retention: an attacker with root on
# the box cannot erase what has already been shipped.
resource "aws_cloudwatch_log_group" "lab" {
  for_each          = toset(["falco", "audit", "apps"])
  name              = "/secureshop/dev/${each.key}"
  retention_in_days = 30
  #checkov:skip=CKV_AWS_158:Encrypted at rest with AWS-owned keys by default; a customer-managed KMS key adds cost in this free-tier lab
  #checkov:skip=CKV_AWS_338:30 days of evidence is enough for a short-lived lab; production would keep at least a year
}

data "aws_iam_policy_document" "lab_logs" {
  statement {
    sid       = "AppendOnlyToSecureShopLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = flatten([for g in aws_cloudwatch_log_group.lab : [g.arn, "${g.arn}:log-stream:*"]])
  }
}

resource "aws_iam_role_policy" "lab_logs" {
  name   = "ship-logs-append-only"
  role   = aws_iam_role.lab.id
  policy = data.aws_iam_policy_document.lab_logs.json
}
