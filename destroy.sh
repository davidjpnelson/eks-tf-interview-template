#!/bin/bash
set -eo pipefail

cd $(dirname $0)

echo "🚀 Starting infrastructure destruction..."

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

set -u

# First, destroy the EKS cluster
echo "🗑️ Destroying EKS cluster..."
cd terraform/aws
terraform init $TERRAFORM_INIT_ARGS
terraform destroy -var "interviewee_name=${INTERVIEW_NAME}" -auto-approve

echo "✨ EKS cluster destroyed successfully!"

# Finally, destroy the bootstrap infrastructure
echo "🗑️ Destroying bootstrap infrastructure..."
cd ../bootstrap
# Allow overriding only the bootstrap backend key via CLI
BOOTSTRAP_INIT_ARGS="$TERRAFORM_INIT_ARGS"
if [ -n "$BOOTSTRAP_STATE_KEY" ]; then
  BOOTSTRAP_INIT_ARGS="$BOOTSTRAP_INIT_ARGS --backend-config=key=$BOOTSTRAP_STATE_KEY"
fi
terraform init $BOOTSTRAP_INIT_ARGS
terraform destroy -auto-approve -var "interview_name=${INTERVIEW_NAME}"

echo "✨ Bootstrap infrastructure destroyed successfully!"
echo "🎉 All infrastructure has been cleaned up!"
