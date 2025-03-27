# Terraform Project: Modularized EC2 with IAM and SSM Integration

This Terraform project provisions an EC2 instance with proper IAM roles and SSM integration for monitoring using CloudWatch. The configuration is modularized into three modules: `ec2`, `iam`, and `ssm`.

## Modules Overview

### 1. `iam` Module
- **Purpose**: Creates an IAM role and instance profile for the EC2 instance to allow it to interact with AWS Systems Manager (SSM) and CloudWatch.
- **Resources**:
  - `aws_iam_role`: Defines the role for EC2.
  - `aws_iam_role_policy_attachment`: Attaches policies for SSM and CloudWatch.
  - `aws_iam_instance_profile`: Creates an instance profile for the EC2 instance.
- **Outputs**:
  - `ec2_instance_profile`: The name of the instance profile, used by the `ec2` module.

### 2. `ec2` Module
- **Purpose**: Provisions an EC2 instance with a security group and required tags.
- **Resources**:
  - `aws_security_group`: Allows SSH access to the EC2 instance.
  - `aws_instance`: Creates the EC2 instance.
- **Tags**:
  - Includes a `monitor` tag with the value `cloudwatch` to enable SSM association based on tags.
- **Inputs**:
  - AMI ID, instance type, key pair name, IAM instance profile, VPC ID, and tags.

### 3. `ssm` Module
- **Purpose**: Creates an SSM document and associates it with EC2 instances based on tags.
- **Resources**:
  - `aws_ssm_document`: Defines the SSM document to install and configure the CloudWatch agent.
  - `aws_ssm_association`: Associates the SSM document with EC2 instances using the `monitor` tag.
- **Inputs**:
  - Document name, document content, and tag values for targeting instances.

## Flow and Working

1. **IAM Role Creation**:
   - The `iam` module creates an IAM role with policies for SSM and CloudWatch.
   - The instance profile is outputted for use in the `ec2` module.

2. **EC2 Instance Provisioning**:
   - The `ec2` module provisions an EC2 instance with the specified AMI, instance type, and key pair.
   - A security group is created to allow SSH access.
   - The EC2 instance is tagged with `monitor = cloudwatch` to enable SSM association.

3. **SSM Integration**:
   - The `ssm` module creates an SSM document to install and configure the CloudWatch agent.
   - The SSM document is associated with EC2 instances using the `monitor` tag.

4. **Monitoring Setup**:
   - The CloudWatch agent is installed and configured on the EC2 instance using the SSM document.
   - Logs and metrics are sent to CloudWatch for monitoring.

## File Structure

```
c:\Users\awezk\Desktop\del
├── main.tf                # Root module to orchestrate the submodules
├── modules
│   ├── ec2
│   │   ├── main.tf        # EC2 instance and security group
│   │   ├── variables.tf   # Input variables for the EC2 module
│   ├── iam
│   │   ├── main.tf        # IAM role, policies, and instance profile
│   │   ├── variables.tf   # Input variables for the IAM module
│   │   ├── outputs.tf     # Outputs for the IAM module
│   ├── ssm
│       ├── main.tf        # SSM document and association
│       ├── variables.tf   # Input variables for the SSM module
```

## How to Use

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the Infrastructure**:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

4. **Verify**:
   - Check the EC2 instance in the AWS Management Console.
   - Verify that the CloudWatch agent is installed and running.
   - Confirm that logs and metrics are being sent to CloudWatch.

## Notes

- Replace sensitive values (e.g., `access_key`, `secret_key`, `vpc_id`, `key_name`) with your own.
- Ensure the AMI ID is valid for your region.
- Restrict the SSH security group to your IP for better security.

## Cleanup

To destroy the infrastructure, run:
```bash
terraform destroy
```

This will remove all resources created by this Terraform configuration.