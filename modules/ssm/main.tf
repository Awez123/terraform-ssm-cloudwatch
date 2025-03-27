resource "aws_ssm_document" "install_cloudwatch_agent" {
  name          = var.document_name
  document_type = "Command"

  content = var.document_content
}

resource "aws_ssm_association" "install_cloudwatch_agent_association" {
  name = aws_ssm_document.install_cloudwatch_agent.name
  targets {
    key    = "tag:monitor"
    values = var.monitoring_tag_values
  }
}
