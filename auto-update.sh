#!/bin/bash

# Usage: ./switch-traffic.sh <new_color>
# Example: ./switch-traffic.sh green

# ========== Input Validation ==========
if [ "$#" -ne 1 ]; then
  echo "❌ Usage: $0 <new_color>"
  echo "   Example: $0 green"
  exit 1
fi

NEW_COLOR="$1"

if [[ "$NEW_COLOR" != "blue" && "$NEW_COLOR" != "green" ]]; then
  echo "❌ Invalid color: $NEW_COLOR"
  echo "   Allowed values: blue or green"
  exit 1
fi

# ========== Setup ==========
REPO_PATH="$HOME/gitops-nginx-bluegreen"
SERVICE_FILE="$REPO_PATH/base/nginx-service.yaml"
ARGO_APP_FILE="$REPO_PATH/base/argo-app.yaml"

cd "$REPO_PATH" || { echo "❌ GitOps repo not found at $REPO_PATH"; exit 1; }

# ========== Get Current Color ==========
ACTIVE_COLOR=$(grep 'color:' "$SERVICE_FILE" | awk '{print $2}')

if [[ "$ACTIVE_COLOR" == "$NEW_COLOR" ]]; then
  echo "✅ Traffic is already routed to $NEW_COLOR. No changes needed."
  exit 0
fi

echo "🔄 Switching traffic from $ACTIVE_COLOR ➡ $NEW_COLOR"

# ========== Patch Service Selector ==========
sed -i "s/color: $ACTIVE_COLOR/color: $NEW_COLOR/" "$SERVICE_FILE"

# ========== Patch ArgoCD App Overlay Path ==========
sed -i "s/overlays\/$ACTIVE_COLOR/overlays\/$NEW_COLOR/" "$ARGO_APP_FILE"

# ========== Git Commit & Push ==========
git add "$SERVICE_FILE" "$ARGO_APP_FILE"

COMMIT_MSG="🔀 Switch traffic to $NEW_COLOR (from $ACTIVE_COLOR)"
git commit -m "$COMMIT_MSG"
git push origin main

echo "✅ Successfully switched traffic to $NEW_COLOR and pushed to Git."

