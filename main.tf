provider "aws" {
  region     = "ap-south-1"
}

module "iam" {
  source                = "./modules/iam"
  role_name             = "ec2-ssm-role"
  instance_profile_name = "ec2-ssm-instance-profile"
}

module "ec2" {
  source                 = "./modules/ec2"
  ami                    = "ami-05c179eced2eb9b5b"
  instance_type          = "t2.micro"
  key_name               = "DevOpskeypair"
  iam_instance_profile   = module.iam.ec2_instance_profile
  vpc_id                 = "vpc-096b181209a1ed59a"
  security_group_name    = "ec2-ssh-sg"
  ssh_cidr_blocks        = ["0.0.0.0/0"]
  tags                   = { Name = "AL2023-TerraformInstance", monitor = "cloudwatch" }
}

module "ssm" {
  source           = "./modules/ssm"
  document_name    = "InstallCloudWatchAgent-AL2023"
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
            "  \"agent\": { \"metrics_collection_interval\": 60, \"run_as_user\": \"cwagent\" },",
            "  \"logs\": {",
            "    \"logs_collected\": {",
            "      \"files\": {",
            "        \"collect_list\": [",
            "          { \"file_path\": \"/var/log/messages\", \"log_group_class\": \"STANDARD\", \"log_group_name\": \"EC2-System-Logs\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 }",
            "        ]",
            "      }",
            "    }",
            "  },",
            "  \"metrics\": {",
            "    \"metrics_collected\": {",
            "      \"collectd\": { \"metrics_aggregation_interval\": 10 },",
            "      \"statsd\": { \"metrics_aggregation_interval\": 10, \"metrics_collection_interval\": 10, \"service_address\": \":8125\" }",
            "    }",
            "  },",
            "  \"traces\": {",
            "    \"buffer_size_mb\": 3,",
            "    \"concurrency\": 8,",
            "    \"insecure\": false,",
            "    \"traces_collected\": {",
            "      \"xray\": {",
            "        \"bind_address\": \"127.0.0.1:2000\",",
            "        \"tcp_proxy\": { \"bind_address\": \"127.0.0.1:2000\" }",
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