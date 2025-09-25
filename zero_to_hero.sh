#!/bin/bash
set -eo pipefail

cd $(dirname $0)

echo "🚀 Starting zero to hero deployment..."

# Optional: choose interview/ECR repo name and bootstrap backend key
INTERVIEW_NAME="interview-repo"

# Get the first argument after -- if it exists
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "--" ]] && [[ $((i+1)) -le $# ]]; then
    INTERVIEW_NAME="${!((i+1))}"
    break
  fi
done

BOOTSTRAP_STATE_KEY="${INTERVIEW_NAME}-bootstrap-ecr.tfstate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-state-key)
      BOOTSTRAP_STATE_KEY="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [-- <interview-name>]";
      echo "       [--bootstrap-state-key <s3/key/path.tfstate>]";
      echo "Example: $0 -- acme-takehome --bootstrap-state-key interviews/acme/bootstrap-ecr.tfstate"; exit 0 ;;
    --) shift; shift ;;  # Skip the -- and the interview name
    *) 
      if [[ "$1" != "--bootstrap-state-key" ]]; then
        echo "Unknown argument: $1" >&2; exit 1
      fi ;;
  esac
  shift
done

TERRAFORM_INIT_ARGS=''
if [ ! -z "$TF_STATE_BUCKET" ]; then
    TERRAFORM_INIT_ARGS="--backend-config=bucket=$TF_STATE_BUCKET"
fi
if [ ! -z "$TF_STATE_KEY" ]; then
    TERRAFORM_INIT_ARGS="$TERRAFORM_INIT_ARGS --backend-config=key=$TF_STATE_KEY"
fi
if [ ! -z "$TF_STATE_REGION" ]; then
    TERRAFORM_INIT_ARGS="$TERRAFORM_INIT_ARGS --backend-config=region=$TF_STATE_REGION"
fi

TFVARS=""
if [ ! -z "$SSH_CIDR_BLOCK" ]; then
    # Create a temporary file for the list
    TEMP_FILE=$(mktemp)
    echo "ssh_cidr_blocks = [\"$SSH_CIDR_BLOCK\"]" > "$TEMP_FILE"
    TFVARS="$TFVARS -var-file=$TEMP_FILE"
    # Clean up temp file after terraform runs
    trap 'rm -f "$TEMP_FILE"' EXIT
fi

set -u

# Initialize and apply Terraform
echo "📦 Creating infrastructure with Terraform..."
cd terraform/bootstrap
# Allow overriding only the bootstrap backend key via CLI
BOOTSTRAP_INIT_ARGS="$TERRAFORM_INIT_ARGS"
if [ -n "$BOOTSTRAP_STATE_KEY" ]; then
  BOOTSTRAP_INIT_ARGS="$BOOTSTRAP_INIT_ARGS --backend-config=key=$BOOTSTRAP_STATE_KEY"
fi
terraform init $BOOTSTRAP_INIT_ARGS
terraform apply -auto-approve -var "interview_name=${INTERVIEW_NAME}"

# Surface which ECR repository is being used
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
echo "📦 Using ECR repository: ${ECR_REPO_URL} (name: ${INTERVIEW_NAME})"

echo "✨ Bootstrap Infrastructure created successfully!"

# Initialize the EKS cluster
echo "📦 Initializing EKS cluster..."
cd ../aws
# Init with the bucket we just created, but the standard key from that module
terraform init $TERRAFORM_INIT_ARGS
terraform apply -var "interviewee_name=${INTERVIEW_NAME}" -auto-approve

echo "✨ EKS cluster initialized successfully!"

# Build/push app image and deploy (only if ./app exists two levels up)
if [ -d "../../app" ]; then
  echo "🐳 Building and pushing Docker image..."
  cd ../../app
  make build push
  IMAGE_ID=$(make output-image-id)

  echo "🔍 Image ID: $IMAGE_ID"

  cd ../terraform
  terraform init $TERRAFORM_INIT_ARGS
  terraform apply -var "docker_image=$IMAGE_ID" -var "ecr_repository_url=$ECR_REPO_URL" $TFVARS -auto-approve

  timeout=300  # 5 minutes in seconds
  start_time=$(date +%s)
  end_time=$((start_time + timeout))

  current_time=$(date +%s)
  while ! curl -s $(terraform output -raw instance_ip) > /dev/null; do
      current_time=$(date +%s)
      if [ $current_time -ge $end_time ]; then
          echo "Timeout reached after 5 minutes. Application may not be ready."
          break
      fi
      echo "Waiting for application to start... $(date)"
      sleep 10
  done

  EXIT_CODE=0
  if [ $current_time -ge $end_time ]; then
      echo "Timeout reached after 5 minutes. Application may not be ready."
      EXIT_CODE=1
  else
      echo "🎉 Deployment complete!"
  fi

  echo "🔑 To SSH into the instance, run:"
  echo "    $(terraform output -raw ssh_key_commands)"

  echo
  echo "🔍 You can access the application at: http://$(terraform output -raw instance_ip)"

  exit $EXIT_CODE
else
  echo "ℹ️ No ./app found. Skipping image build and app deployment."
  echo "   ECR repository is ready: ${ECR_REPO_URL}"
  exit 0
fi