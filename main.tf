provider "aws" {
  region     = "ap-south-1"
}

module "iam" {
  source                = "./modules/iam"
  role_name             = "ec2-ssm-role_awez"
  instance_profile_name = "ec2-ssm-instance-profile_awez"
}

module "ec2" {
  source                 = "./modules/ec2"
  ami                    = "ami-05c179eced2eb9b5b"
  instance_type          = "t2.micro"
  key_name               = "DevOpskeypair"
  iam_instance_profile   = module.iam.ec2_instance_profile
  vpc_id                 = "vpc-096b181209a1ed59a"
  security_group_name    = "ec2-ssh-sg_awez"
  ssh_cidr_blocks        = ["0.0.0.0/0"]
  tags                   = { Name = "cloudwatch-module-test", monitor = "cloudwatch" }
}

module "ssm" {
  source           = "./modules/ssm"
  document_name    = "InstallCloudWatchAgent-AL2023-awez"
  document_content = jsonencode({
    schemaVersion = "2.2",
    description   = "Install, configure, and start CloudWatch Agent on AL2023",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "installAndStartCloudWatchAgent",
        inputs = {
          runCommand = [
            "dnf update -y",
            "dnf install -y amazon-cloudwatch-agent",
            "mkdir -p /usr/share/collectd/",
            "touch /usr/share/collectd/types.db",
            "cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json",
            "{",
            "  \"agent\": { \"metrics_collection_interval\": 60, \"root\": \"cwagent\" },",
            "  \"logs\": {",
            "    \"logs_collected\": {",
            "      \"files\": {",
            "        \"collect_list\": [",
            "          { \"file_path\": \"/var/log/messages\", \"log_group_name\": \"cloudwatch-logs\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 },",
            "          { \"file_path\": \"/var/log/syslog\", \"log_group_name\": \"cloudwatch-logs\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 },",
            "          { \"file_path\": \"/var/log/*.log\", \"log_group_name\": \"cloudwatch-logs\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 },",
            "          { \"file_path\": \"/var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log\", \"log_group_name\": \"cloudwatch-agent-logs\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 }",
            "        ]",
            "      }",
            "    }",
            "  },",
            "  \"metrics\": {",
            "    \"namespace\": \"CustomNamespace\",",
            "    \"append_dimensions\": {",
            "      \"InstanceId\": \"$${aws:InstanceId}\",",
            "      \"InstanceType\": \"$${aws:InstanceType}\"",
            "    },",
            "    \"metrics_collected\": {",
            "      \"cpu\": {",
            "        \"measurement\": [\"cpu_usage_idle\", \"cpu_usage_user\"],",
            "        \"metrics_collection_interval\": 60",
            "      },",
            "      \"disk\": {",
            "        \"measurement\": [\"used_percent\"],",
            "        \"resources\": [\"*\"],",
            "        \"metrics_collection_interval\": 60",
            "      },",
            "      \"mem\": {",
            "        \"measurement\": [\"mem_used_percent\"],",
            "        \"metrics_collection_interval\": 60",
            "      }",
            "    }",
            "  }",
            "}",
            "EOF",
            "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s",
            "systemctl enable amazon-cloudwatch-agent",
            "systemctl restart amazon-cloudwatch-agent",
            "systemctl status amazon-cloudwatch-agent | tee /var/log/cloudwatch-agent-status.log"
          ]
        }
      }
    ]
  })
  monitoring_tag_values = ["cloudwatch"]
}
