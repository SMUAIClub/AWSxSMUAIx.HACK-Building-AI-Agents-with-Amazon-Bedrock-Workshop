#!/usr/bin/env bash
# Zips the pre-built frontend bundle and pushes it to an Amplify app/branch via
# the create-deployment -> upload -> start-deployment flow (the CLI equivalent
# of the console's drag-and-drop "Deploy without Git" upload).
set -euo pipefail

APP_ID="$1"
BRANCH_NAME="$2"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP_PATH="$DIR/.build/frontend.zip"

rm -rf "$DIR/.build"
mkdir -p "$DIR/.build"
(cd "$DIR" && zip -qr "$ZIP_PATH" index.html assets)

RESPONSE=$(aws amplify create-deployment --app-id "$APP_ID" --branch-name "$BRANCH_NAME")
UPLOAD_URL=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['zipUploadUrl'])" "$RESPONSE")
JOB_ID=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['jobId'])" "$RESPONSE")

curl -sf -X PUT -H "Content-Type: application/zip" --data-binary "@$ZIP_PATH" "$UPLOAD_URL" >/dev/null

aws amplify start-deployment --app-id "$APP_ID" --branch-name "$BRANCH_NAME" --job-id "$JOB_ID" >/dev/null

echo "Started Amplify deployment job $JOB_ID for $APP_ID/$BRANCH_NAME"
