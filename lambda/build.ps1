# Build script for AWS Lambda
# This script builds the Go binary for Linux and creates a deployment zip
# Usage: .\build.ps1 [-PushToECR]

param(
    [switch]$PushToECR = $false
)

$AWS_ACCOUNT_ID = "211125751164"
$AWS_REGION = "us-west-2"
$ECR_REPO = "lambda-order-processor"
$IMAGE_TAG = "latest"

Write-Host "=== Building Lambda function ===" -ForegroundColor Cyan

# Build for Linux AMD64 (Lambda runtime)
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"

Write-Host "Building Lambda function for Linux..."
go build -tags lambda.norpc -o bootstrap main.go

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

# Create deployment zip
Write-Host "Creating deployment package..."
if (Test-Path "lambda.zip") {
    Remove-Item "lambda.zip"
}
Compress-Archive -Path bootstrap -DestinationPath lambda.zip

Write-Host "Lambda deployment package created: lambda.zip" -ForegroundColor Green
Write-Host "Size: $((Get-Item lambda.zip).Length / 1KB) KB"

# Reset environment
Remove-Item Env:GOOS
Remove-Item Env:GOARCH
Remove-Item Env:CGO_ENABLED

# Optional: Push to ECR for container-based Lambda
if ($PushToECR) {
    Write-Host "`n=== Pushing to ECR ===" -ForegroundColor Cyan
    
    # Check if Dockerfile exists
    if (-not (Test-Path "Dockerfile")) {
        Write-Host "Creating Dockerfile for Lambda container image..."
        @"
FROM public.ecr.aws/lambda/provided:al2

COPY bootstrap /var/runtime/bootstrap

CMD ["bootstrap"]
"@ | Out-File -FilePath Dockerfile -Encoding utf8
    }
    
    # Build Docker image
    Write-Host "Building Docker image..."
    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker build failed!" -ForegroundColor Red
        exit 1
    }
    
    # Login to ECR
    Write-Host "Logging into ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ECR login failed!" -ForegroundColor Red
        exit 1
    }
    
    # Tag for ECR
    $ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
    Write-Host "Tagging image for ECR: $ECR_URI"
    docker tag ${ECR_REPO}:${IMAGE_TAG} $ECR_URI
    
    # Push to ECR
    Write-Host "Pushing to ECR..."
    docker push $ECR_URI
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully pushed to ECR: $ECR_URI" -ForegroundColor Green
    } else {
        Write-Host "ECR push failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n=== Build Complete ===" -ForegroundColor Green
Write-Host "Lambda zip: lambda.zip (ready for Terraform deployment)"
if ($PushToECR) {
    Write-Host "ECR image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
}
Write-Host "`nTo push to ECR, run: .\build.ps1 -PushToECR"
