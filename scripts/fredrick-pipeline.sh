#!/bin/bash
# fredrick-pipeline.sh - Complete lead generation pipeline
# Orchestrates: scrape → build sites → update Notion → trigger n8n

set -e

# Configuration
PROJECT_DIR="$HOME/Desktop/local-lead-gen"
SCRAPER_SCRIPT="$PROJECT_DIR/scraper/scraper.py"
BUILD_SCRIPT="$PROJECT_DIR/scripts/build-site.sh"
NOTION_API_KEY="NOTION_API_KEY_PLACEHOLDER"
N8N_WEBHOOK="http://127.0.0.1:5678/webhook/lead-outreach"
LEADS_FILE="$PROJECT_DIR/leads.json"

echo "=========================================="
echo "Fredrick Lead Gen Pipeline"
echo "Started: $(date)"
echo "=========================================="

# Step 1: Run Playwright scraper
echo ""
echo "[Step 1/4] Running scraper..."
python3 "$SCRAPER_SCRIPT" restaurant "Rochester, NY"
python3 "$SCRAPER_SCRIPT" salon "Rochester, NY"
python3 "$SCRAPER_SCRIPT" contractor "Rochester, NY"

echo "Scraping complete. Checking for new leads..."

# Step 2: Process new leads
echo ""
echo "[Step 2/4] Processing new leads..."

if [ ! -f "$LEADS_FILE" ]; then
    echo "No leads.json found. Nothing to process."
    exit 0
fi

# Read leads and process new ones
node -e "
const fs = require('fs');
const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8'));
const newLeads = leads.filter(lead => lead.status === 'new');

if (newLeads.length === 0) {
    console.log('No new leads to process.');
    process.exit(0);
}

console.log(\`Found \${newLeads.length} new leads to process:\`);
newLeads.forEach(lead => {
    console.log(\`  - \${lead.name} (\${lead.niche})\`);
});
"

# Process each new lead
NEW_LEADS=$(node -e "const fs = require('fs'); const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8')); console.log(JSON.stringify(leads.filter(l => l.status === 'new')));")

if [ "$NEW_LEADS" = "[]" ]; then
    echo "No new leads to process."
    exit 0
fi

# Parse and process each lead
echo "$NEW_LEADS" | jq -c '.[]' | while read -r lead; do
    NAME=$(echo "$lead" | jq -r '.name')
    ADDRESS=$(echo "$lead" | jq -r '.address')
    PHONE=$(echo "$lead" | jq -r '.phone')
    NICHE=$(echo "$lead" | jq -r '.niche')
    
    echo ""
    echo "Processing: $NAME ($NICHE)"
    
    # Step 3: Build site
    echo "  → Building site..."
    SITE_URL=$(bash "$BUILD_SCRIPT" "$NICHE" "$NAME" "$ADDRESS" "$PHONE" 2>&1 | tail -1)
    
    if [ -z "$SITE_URL" ] || [ "$SITE_URL" = "DEPLOYMENT_PENDING" ]; then
        echo "  ⚠️  Site build/deployment issue. Check logs."
        SITE_URL="ERROR"
    else
        echo "  ✅ Site deployed: $SITE_URL"
    fi
    
    # Update lead status in leads.json
    node -e "
    const fs = require('fs');
    const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8'));
    const leadIndex = leads.findIndex(l => l.name === '$NAME' && l.status === 'new');
    if (leadIndex !== -1) {
        leads[leadIndex].status = 'site_built';
        leads[leadIndex].site_url = '$SITE_URL';
        leads[leadIndex].updated_at = new Date().toISOString();
    }
    fs.writeFileSync('$LEADS_FILE', JSON.stringify(leads, null, 2));
    "
    
    # Step 4: Update Notion (if configured)
    echo "  → Updating Notion..."
    # This requires knowing the Notion page ID for this lead
    # You can store the Notion page ID when initially adding the lead to Notion
    
    # Step 5: Trigger n8n workflow
    echo "  → Triggering n8n outreach workflow..."
    curl -X POST "$N8N_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{
            \"lead_name\": \"$NAME\",
            \"lead_niche\": \"$NICHE\",
            \"site_url\": \"$SITE_URL\",
            \"phone\": \"$PHONE\",
            \"address\": \"$ADDRESS\"
        }" 2>/dev/null && echo "  ✅ n8n triggered" || echo "  ⚠️  n8n webhook failed"
    
    echo "  ✅ Lead processed: $NAME"
    
    # Rate limiting - avoid hitting API limits
    sleep 5
done

echo ""
echo "=========================================="
echo "✅ Pipeline complete!"
echo "Finished: $(date)"
echo "=========================================="

# Summary
TOTAL=$(node -e "const fs = require('fs'); const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8')); console.log(leads.length);")
PROCESSED=$(node -e "const fs = require('fs'); const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8')); console.log(leads.filter(l => l.status === 'site_built').length);")
REMAINING=$(node -e "const fs = require('fs'); const leads = JSON.parse(fs.readFileSync('$LEADS_FILE', 'utf8')); console.log(leads.filter(l => l.status === 'new').length);")

echo ""
echo "Summary:"
echo "  Total leads: $TOTAL"
echo "  Processed: $PROCESSED"
echo "  Remaining: $REMAINING"
