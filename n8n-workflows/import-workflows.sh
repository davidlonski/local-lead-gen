#!/bin/bash
# Import n8n workflows for local-lead-gen project
# Usage: ./import-workflows.sh [N8N_API_KEY]

set -e

N8N_URL="http://127.0.0.1:5678"
WORKFLOWS_DIR="$(dirname "$0")"

# Check if API key is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <N8N_API_KEY>"
    echo ""
    echo "To get your API key:"
    echo "1. Open n8n at http://127.0.0.1:5678"
    echo "2. Go to Settings → API Keys → Create API Key"
    echo "3. Run: $0 <your-api-key>"
    exit 1
fi

API_KEY="$1"

echo "Importing workflows to n8n at $N8N_URL..."

# Import lead-outreach workflow
echo "→ Importing lead-outreach.json..."
curl -X POST "$N8N_URL/rest/workflows/import" \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -d @"$WORKFLOWS_DIR/lead-outreach.json"

echo ""

# Import fredrick-response-handler workflow
echo "→ Importing fredrick-response-handler.json..."
curl -X POST "$N8N_URL/rest/workflows/import" \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -d @"$WORKFLOWS_DIR/fredrick-response-handler.json"

echo ""
echo "✓ Workflows imported successfully!"
echo ""
echo "Next steps:"
echo "1. Open n8n at http://127.0.0.1:5678"
echo "2. Configure credentials (Notion API + Gmail OAuth)"
echo "3. Update LEADS_DB_ID_PLACEHOLDER in both workflows"
echo "4. Activate the workflows"
