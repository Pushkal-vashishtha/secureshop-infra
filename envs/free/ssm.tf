# Session Manager preferences for the whole account/region:
# - every session's input and output streamed to CloudWatch (who did what)
# - sessions run as "ubuntu" (your normal environment), not ssm-user
# - idle sessions end after 20 minutes
resource "aws_ssm_document" "session_prefs" {
  #checkov:skip=CKV_AWS_112:Session traffic is already TLS-encrypted by SSM; an extra KMS key adds cost in this lab
  #checkov:skip=CKV_AWS_113:Logs go to CloudWatch, encrypted at rest with AWS-owned keys; no S3 bucket used
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"
  content = jsonencode({
    schemaVersion = "1.0"
    description   = "SecureShop Session Manager preferences"
    sessionType   = "Standard_Stream"
    inputs = {
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.lab["ssm-sessions"].name
      cloudWatchEncryptionEnabled = false
      cloudWatchStreamingEnabled  = true
      s3BucketName                = ""
      idleSessionTimeout          = "20"
      runAsEnabled                = true
      runAsDefaultUser            = "ubuntu"
      shellProfile                = { linux = "cd ~ && exec bash -l", windows = "" }
    }
  })
}
