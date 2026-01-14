###############################################################################
# Ajyal LMS - Deployment & Operations Guide
# Windows ASG + CodeDeploy + Patching Explained
###############################################################################

## Architecture Overview

```
                     ┌─────────────────────────────────────────────────────────┐
                     │                    INTERNET                              │
                     └────────────────────────┬────────────────────────────────┘
                                              │
                     ┌────────────────────────▼────────────────────────────────┐
                     │              Application Load Balancer                   │
                     │         (Distributes traffic to healthy instances)       │
                     └────────────────────────┬────────────────────────────────┘
                                              │
          ┌───────────────────────────────────┼───────────────────────────────────┐
          │                                   │                                   │
    ┌─────▼─────┐                       ┌─────▼─────┐                       ┌─────▼─────┐
    │ Windows   │                       │ Windows   │                       │ Windows   │
    │ Instance 1│                       │ Instance 2│                       │ Instance N│
    │           │                       │           │                       │           │
    │ CodeDeploy│                       │ CodeDeploy│                       │ CodeDeploy│
    │  Agent    │                       │  Agent    │                       │  Agent    │
    │ SSM Agent │                       │ SSM Agent │                       │ SSM Agent │
    └───────────┘                       └───────────┘                       └───────────┘
          │                                   │                                   │
          └───────────────────────────────────┼───────────────────────────────────┘
                                              │
                     ┌────────────────────────▼────────────────────────────────┐
                     │                Auto Scaling Group (ASG)                  │
                     │    - Maintains desired instance count                    │
                     │    - Replaces unhealthy instances automatically          │
                     │    - Scales based on CPU/Memory metrics                  │
                     └─────────────────────────────────────────────────────────┘
```

## 1. Windows Auto Scaling Group (ASG) - How It Works

### Launch Template Configuration

Windows instances are created from a Launch Template that includes:

```hcl
# User data installs CodeDeploy agent on Windows boot
user_data = base64encode(<<-EOF
  <powershell>
  # Install CodeDeploy Agent for Windows
  New-Item -Path "C:\Temp" -ItemType Directory -Force
  Set-Location "C:\Temp"

  # Download and install agent
  $url = "https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/codedeploy-agent.msi"
  Invoke-WebRequest -Uri $url -OutFile "codedeploy-agent.msi"
  Start-Process msiexec.exe -ArgumentList "/i codedeploy-agent.msi /quiet" -Wait

  # Start the service
  Start-Service -Name codedeployagent
  </powershell>
EOF
)
```

### ASG Behavior

1. **Initial Launch**: ASG creates instances from Launch Template
2. **Health Checks**: ALB performs health checks on `/health` endpoint
3. **Self-Healing**: Unhealthy instances are terminated and replaced
4. **Scaling**: Based on CloudWatch alarms (CPU > 80%)

```
ASG Lifecycle:
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   Instance       │    │    Health        │    │   Register to    │
│   Launches       │───▶│    Check OK      │───▶│   Target Group   │
│   (From LT)      │    │                  │    │                  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
                                │
                                │ Fails
                                ▼
                        ┌──────────────────┐    ┌──────────────────┐
                        │   Instance       │    │   New Instance   │
                        │   Terminated     │───▶│   Launched       │
                        │                  │    │                  │
                        └──────────────────┘    └──────────────────┘
```

---

## 2. Zero-Downtime Deployment with CodeDeploy

### Deployment Flow (WITH_TRAFFIC_CONTROL)

When you deploy with ALB integration:

```
Step 1: CodeDeploy starts deployment
        ┌─────────────────────────────────────────────────────────────┐
        │                                                             │
        │    ALB ──────▶ [Instance 1] ✓ Healthy, Serving Traffic     │
        │       ──────▶ [Instance 2] ✓ Healthy, Serving Traffic     │
        │                                                             │
        └─────────────────────────────────────────────────────────────┘

Step 2: Deregister Instance 1 from ALB (drain connections)
        ┌─────────────────────────────────────────────────────────────┐
        │                                                             │
        │    ALB ──╳───▶ [Instance 1] ⏳ Draining (300s default)     │
        │       ──────▶ [Instance 2] ✓ Serving ALL Traffic          │
        │                                                             │
        └─────────────────────────────────────────────────────────────┘

Step 3: Deploy to Instance 1 (while offline)
        ┌─────────────────────────────────────────────────────────────┐
        │                                                             │
        │    ALB ──╳───▶ [Instance 1] 🔄 Installing new version     │
        │       ──────▶ [Instance 2] ✓ Serving ALL Traffic          │
        │                                                             │
        └─────────────────────────────────────────────────────────────┘

Step 4: Re-register Instance 1, Deregister Instance 2
        ┌─────────────────────────────────────────────────────────────┐
        │                                                             │
        │    ALB ──────▶ [Instance 1] ✓ New version, Serving        │
        │       ──╳───▶ [Instance 2] ⏳ Draining                     │
        │                                                             │
        └─────────────────────────────────────────────────────────────┘

Step 5: Deploy to Instance 2, Complete
        ┌─────────────────────────────────────────────────────────────┐
        │                                                             │
        │    ALB ──────▶ [Instance 1] ✓ New version                  │
        │       ──────▶ [Instance 2] ✓ New version                  │
        │                                                             │
        │    ✅ DEPLOYMENT COMPLETE - ZERO DOWNTIME                   │
        └─────────────────────────────────────────────────────────────┘
```

### Deployment Configuration Options

| Config Name | Behavior | Downtime | Speed |
|-------------|----------|----------|-------|
| `AllAtOnce` | Deploy to ALL instances simultaneously | Brief (~30s) | FASTEST |
| `HalfAtATime` | Deploy to 50% at a time | ZERO | Fast |
| `OneAtATime` | Deploy one instance at a time | ZERO | Slow |

### CodeDeploy appspec.yml for Windows

```yaml
version: 0.0
os: windows
files:
  - source: /
    destination: C:\inetpub\wwwroot\AjyalApp
hooks:
  BeforeInstall:
    - location: scripts\stop-iis.ps1
      timeout: 120
  AfterInstall:
    - location: scripts\start-iis.ps1
      timeout: 120
  ValidateService:
    - location: scripts\validate-health.ps1
      timeout: 300
```

---

## 3. OS Patching with SSM Patch Manager

### How Patching Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PATCHING WORKFLOW                                      │
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ Maintenance │    │   Scan      │    │   Install   │    │   Reboot    │  │
│  │   Window    │───▶│   Patches   │───▶│   Patches   │───▶│   Instance  │  │
│  │  (Sunday)   │    │             │    │             │    │             │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                              │
│  Scheduled:                                                                  │
│  - Windows: Sunday 4 AM UTC                                                  │
│  - Linux: Sunday 5 AM UTC                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Patch Groups (Tag-Based)

Instances are patched based on their `PatchGroup` tag:

| Tag Value | OS | Patch Baseline |
|-----------|-----|----------------|
| `windows-app` | Windows Server 2025 | AWS-DefaultPatchBaseline |
| `windows-api` | Windows Server 2025 | AWS-DefaultPatchBaseline |
| `linux-rabbitmq` | Amazon Linux 2 | AWS-AmazonLinux2DefaultPatchBaseline |
| `linux-botpress` | Amazon Linux 2 | AWS-AmazonLinux2DefaultPatchBaseline |

### Zero-Downtime Patching Strategy

For production environments with ALB integration:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    PATCHING WITH ZERO DOWNTIME                             │
│                                                                            │
│  1. SSM Patch Manager coordinates with ASG                                 │
│                                                                            │
│  2. Before patching an instance:                                           │
│     - Deregister from ALB target group                                     │
│     - Wait for connection draining (300s)                                  │
│                                                                            │
│  3. Patch the instance:                                                    │
│     - Install Windows Updates / yum updates                                │
│     - Reboot if required                                                   │
│                                                                            │
│  4. After patching:                                                        │
│     - Wait for instance to pass health check                               │
│     - Re-register to ALB target group                                      │
│                                                                            │
│  5. Move to next instance (one at a time)                                  │
│                                                                            │
│  Result: Users never experience downtime                                   │
└───────────────────────────────────────────────────────────────────────────┘
```

### Patching On/Off Toggle

```hcl
# In variables.tf
variable "enable_patching" {
  description = "Master toggle for patching"
  default     = true  # Set to false to disable ALL patching
}

variable "enable_windows_patching" {
  default = true  # Set to false to disable Windows patching only
}

variable "enable_linux_patching" {
  default = true  # Set to false to disable Linux patching only
}
```

---

## 4. Complete Deployment Order

```bash
# Deploy infrastructure in order
./deploy.sh apply

# Or deploy modules individually:
./deploy.sh apply 01-vpc        # VPC, Subnets, NAT Gateway
./deploy.sh apply 02-security   # Security Groups, WAF, KMS
./deploy.sh apply 03-storage    # EFS, S3 buckets
./deploy.sh apply 04-database   # RDS SQL Server, PostgreSQL, Redis
./deploy.sh apply 05-cicd       # CodeDeploy applications & roles
./deploy.sh apply 06-compute    # EC2 instances, ASG, ALB
./deploy.sh apply 07-patching   # SSM Patch Manager
./deploy.sh apply 08-monitoring # CloudWatch, CloudTrail
```

### Enable Zero-Downtime After Compute Deployment

After deploying compute, update cicd with ASG/ALB integration:

```bash
cd environments/preprod/05-cicd

terraform apply \
  -var="app_target_group_name=preprod-ajyal-windows-app-tg" \
  -var="api_target_group_name=preprod-ajyal-windows-api-tg" \
  -var="app_asg_name=preprod-ajyal-windows-app-asg" \
  -var="api_asg_name=preprod-ajyal-windows-api-asg"
```

---

## 5. Triggering a Deployment

### From AWS CLI

```bash
# Deploy to Windows App servers
aws deploy create-deployment \
  --application-name preprod-windows-app \
  --deployment-group-name preprod-ajyal-windows-app-dg \
  --s3-location bucket=ajyal-artifacts-preprod,key=windows-app/app-v1.0.zip,bundleType=zip

# Deploy to Linux Botpress servers
aws deploy create-deployment \
  --application-name preprod-linux-app \
  --deployment-group-name preprod-ajyal-linux-botpress-dg \
  --s3-location bucket=ajyal-artifacts-preprod,key=linux-botpress/botpress-v1.0.tar,bundleType=tar
```

### From S3 (Auto-Deploy)

Upload artifact to S3, CodePipeline automatically triggers deployment:

```bash
# Upload to S3 triggers deployment
aws s3 cp ./app-v1.0.zip s3://ajyal-artifacts-preprod/windows-app/
```

---

## 6. Monitoring & Rollback

### Automatic Rollback

CodeDeploy automatically rolls back if:
- Deployment fails on any instance
- CloudWatch alarm triggers during deployment

```hcl
auto_rollback_configuration {
  enabled = true
  events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
}
```

### Manual Rollback

```bash
# Stop current deployment and rollback
aws deploy stop-deployment \
  --deployment-id d-XXXXXXXXX \
  --auto-rollback-enabled
```

### View Deployment Status

```bash
# List recent deployments
aws deploy list-deployments \
  --application-name preprod-windows-app \
  --deployment-group-name preprod-ajyal-windows-app-dg

# Get deployment details
aws deploy get-deployment --deployment-id d-XXXXXXXXX
```

---

## 7. Summary Table

| Feature | Windows | Linux | Zero-Downtime |
|---------|---------|-------|---------------|
| ASG Support | ✅ | ✅ | ✅ |
| CodeDeploy | ✅ (MSI Agent) | ✅ | ✅ |
| ALB Integration | ✅ | ✅ | ✅ |
| Auto Patching | ✅ (Sunday 4AM) | ✅ (Sunday 5AM) | ✅ |
| Auto Rollback | ✅ | ✅ | ✅ |
| CloudWatch Monitoring | ✅ | ✅ | N/A |
| On/Off Toggle | ✅ | ✅ | N/A |

