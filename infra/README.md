Terraform infra for Phase 3: Async Solution

This folder contains a minimal Terraform scaffold that creates the required AWS resources for the async solution described in the lab.

Notes / important constraints:
- Do NOT create IAM roles in Terraform for ECS task execution or task role; use lab-provided ARNs (pass them via variables). Default variables are set to the provided lab role ARN.
- The task definitions use images from the ECR repositories created here (you must push appropriate images after terraform apply).

How to use (local):

1. Change directory and initialize:

```powershell
cd infra
terraform init
```

2. Inspect plan and apply (this will create VPC, subnets, ALB, ECR, ECS cluster, SNS, SQS and subscribe SNS->SQS):

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

3. After apply, push your Docker images to the created ECR repos and update task definitions or use image tags matching `:latest`.

4. The outputs include ALB DNS, SNS topic ARN, SQS URL and ECS cluster name.
