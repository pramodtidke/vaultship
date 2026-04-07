# VaultShip — DevSecOps CI/CD Pipeline

A 5-stage pipeline: lint → secrets scan → Docker build → CVE scan → deploy to ECS Fargate.

## Stack
- **GitHub Actions** — CI/CD orchestration
- **Docker** — multi-stage image build
- **GitLeaks** — secrets scanning (SAST)
- **Trivy** — container vulnerability scanning
- **AWS ECR** — container registry
- **AWS ECS Fargate** — serverless container hosting
- **Terraform** — infrastructure as code

---

## Setup: Step by Step

### 1. Fork / clone this repo to your GitHub account

```bash
git clone https://github.com/YOUR_USERNAME/vaultship.git
cd vaultship
```

---

### 2. Create Terraform state bucket (one-time, manual)

Before running `terraform apply`, create the S3 backend resources:

```bash
# Create S3 bucket (replace YOUR_BUCKET_NAME with something unique)
aws s3api create-bucket \
  --bucket vaultship-tfstate \
  --region us-east-1

# Enable versioning (protects state history)
aws s3api put-bucket-versioning \
  --bucket vaultship-tfstate \
  --versioning-configuration Status=Enabled

# Enable encryption at rest
aws s3api put-bucket-encryption \
  --bucket vaultship-tfstate \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name vaultship-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

### 3. Apply Terraform

```bash
cd terraform

# Update YOUR_GITHUB_USERNAME in main.tf (search for "repo:YOUR_GITHUB_USERNAME")

terraform init
terraform plan
terraform apply
```

After apply, note the outputs:
```
github_actions_role_arn = "arn:aws:iam::123456789:role/vaultship-github-actions"
ecr_repository_url      = "123456789.dkr.ecr.us-east-1.amazonaws.com/vaultship"
```

---

### 4. Add GitHub Secret

Go to: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret name     | Value                               |
|-----------------|-------------------------------------|
| `AWS_ROLE_ARN`  | The `github_actions_role_arn` output |

---

### 5. Push to main

```bash
git add .
git commit -m "feat: initial VaultShip pipeline"
git push origin main
```

Watch the Actions tab — all 5 stages should go green.

---

## Pipeline stages

```
push to main
    │
    ▼
┌─────────┐   ┌──────────────┐   ┌────────────┐   ┌───────────┐   ┌────────┐
│  Lint   │──▶│ Secrets Scan │──▶│ Build+Push │──▶│ Trivy CVE │──▶│ Deploy │
│ ESLint  │   │  GitLeaks    │   │    ECR     │   │   Scan    │   │  ECS   │
└─────────┘   └──────────────┘   └────────────┘   └───────────┘   └────────┘
```

- **Lint** — ESLint on all JS files. Fails on errors.
- **Secrets Scan** — GitLeaks scans full git history. Fails on leaked credentials.
- **Build + Push** — Multi-stage Docker build, pushed to ECR tagged with git SHA.
- **Trivy Scan** — Scans ECR image. Fails hard on CRITICAL CVEs. Uploads SARIF to GitHub Security tab.
- **Deploy** — Updates ECS task definition with new image, rolls out new Fargate tasks.

---

## Testing the pipeline defences

### Test GitLeaks (secrets scan)
```bash
# Add a fake secret to a file
echo 'const key = "AKIAIOSFODNN7EXAMPLE"' >> app/index.js
git add . && git commit -m "test: add fake key"
git push
# Pipeline should FAIL at Stage 2
# Revert: git revert HEAD && git push
```

### Test Trivy (CVE scan)
Change the Dockerfile base image to an older version:
```dockerfile
FROM node:16 AS builder   # older = more CVEs
```
Push and watch Stage 4 fail with CRITICAL CVEs listed in the logs.

---

## Local development

```bash
# Build image
docker build -t vaultship .

# Run locally
docker run -p 3000:3000 vaultship

# Test
curl http://localhost:3000/health
```

---

## Estimated AWS costs (us-east-1)

| Resource          | Cost                         |
|-------------------|------------------------------|
| ECS Fargate (1 task, 0.25 vCPU, 512MB) | ~$9/month |
| ECR storage (first 500MB free) | ~$0/month to start |
| CloudWatch Logs (7 day retention) | < $1/month |
| S3 + DynamoDB (state backend) | < $1/month |

**Destroy when done studying:**
```bash
cd terraform && terraform destroy
```
