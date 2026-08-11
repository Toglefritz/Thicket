#!/bin/zsh
#
# Deploys the Thicket agent to Google Cloud Run.
#
# Usage:
#   export GEMINI_API_KEY="your-key"
#   ./deploy.sh

set -e

PROJECT_ID="thicket-505111"
REGION="us-central1"
SERVICE_NAME="thicket-agent"

echo "Deploying $SERVICE_NAME to $REGION in project $PROJECT_ID..."

gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --set-env-vars "GEMINI_API_KEY=$GEMINI_API_KEY,GCP_PROJECT_ID=$PROJECT_ID" \
  --allow-unauthenticated

echo "Done."
