# n8n Workflow Setup for Local Lead Gen

## Overview

Two n8n workflows automate the lead outreach process:

1. **Lead Outreach** (`lead-outreach.json`) - Weekly cron that finds "site_built" leads and sends them to OpenClaw for email generation
2. **Fredrick Response Handler** (`fredrick-response-handler.json`) - Webhook that generates personalized emails via OpenClaw, sends via Gmail, and updates Notion

---

## Prerequisites

- n8n running at http://127.0.0.1:5678
- Notion API key with access to Leads database
- Gmail OAuth credentials (davelonski12@gmail.com)
- OpenClaw Gateway running at http://127.0.0.1:18789
- OpenClaw Dashboard/Webhook running at http://127.0.0.1:7891

---

## Importing Workflows

### Method 1: Via n8n UI (Recommended)

1. Open n8n at http://127.0.0.1:5678
2. Click **"Create Workflow"** or go to **"Workflows"** → **"Import from File"**
3. Select `lead-outreach.json` for the first workflow
4. Repeat for `fredrick-response-handler.json`
5. Save both workflows (click **"Save"** button)

### Method 2: Via n8n API (Programmatic)

```bash
# Import lead-outreach workflow
curl -X POST http://127.0.0.1:5678/rest/workflows/import \
  -H "Content-Type: application/json" \
  -d @lead-outreach.json

# Import fredrick-response-handler workflow
curl -X POST http://127.0.0.1:5678/rest/workflows/import \
  -H "Content-Type: application/json" \
  -d @fredrick-response-handler.json
```

---

## Required Credentials

### 1. Notion API

**Credential ID:** `notion-credentials`

**Setup:**
1. Go to **"Credentials"** → **"New"** → **"Notion API"**
2. Enter your Notion API key: `NOTION_API_KEY_PLACEHOLDERabX7`
3. Save as `Notion API`

**Notion Leads Database:**
- Create a new database in Notion called "Leads" with these properties:
  - `Name` (title)
  - `Status` (select): options include `site_built`, `outreached`, `responded`, `closed`
  - `Address` (rich_text)
  - `Phone` (phone)
  - `Email` (email)
  - `Site URL` (url)
- Copy the database ID from the URL (format: `https://www.notion.so/xxxxx?v=yyyy` → database ID is `xxxxx`)
- Replace `LEADS_DB_ID_PLACEHOLDER` in both workflow JSON files with your actual database ID

### 2. Gmail OAuth2

**Credential ID:** `gmail-credentials`

**Setup:**
1. Go to **"Credentials"** → **"New"** → **"Gmail OAuth2"**
2. Follow the OAuth flow to connect `davelonski12@gmail.com`
3. Save as `Gmail OAuth`

---

## Webhook URLs

After importing the **Fredrick Response Handler** workflow:

1. Open the workflow in n8n
2. Click on the **"Webhook - Receive Lead Data"** node
3. Copy the **"Production URL"** (format: `http://127.0.0.1:5678/webhook/fredrick-response-handler`)
4. This URL is already configured in the **Lead Outreach** workflow's HTTP Request node

**Important:** The webhook path is set to `fredrick-response-handler`. Make sure this matches exactly.

---

## Workflow Details

### Workflow 1: Lead Outreach (lead-outreach.json)

**Trigger:** Every Monday at 9:00 AM (cron expression: `0 9 * * 1`)

**Flow:**
1. Cron trigger fires
2. Notion node queries Leads DB for pages where `Status = "site_built"`
3. Split node loops through leads one by one
4. HTTP Request POSTs lead data to OpenClaw webhook (`http://127.0.0.1:7891/api/n8n/trigger`)
5. Wait node delays 2 minutes (rate limiting between emails)
6. Loop continues until all leads processed

**Payload sent to OpenClaw:**
```json
{
  "lead_name": "{{$json.name}}",
  "lead_address": "{{$json.address}}",
  "lead_phone": "{{$json.phone}}",
  "site_url": "{{$json.site_url}}",
  "lead_id": "{{$json.id}}"
}
```

---

### Workflow 2: Fredrick Response Handler (fredrick-response-handler.json)

**Trigger:** POST to webhook URL (`/webhook/fredrick-response-handler`)

**Flow:**
1. Webhook receives lead data
2. HTTP Request calls OpenClaw agent endpoint (`http://127.0.0.1:18789/api/agent`) to generate personalized email
3. Gmail node sends the generated email to the lead
4. Notion node updates lead status to `"outreached"`
5. Webhook responds with success message

**Expected OpenClaw Response:**
The OpenClaw agent should return a JSON response with the generated email content in a `response` field.

---

## Activating Workflows

1. Open each workflow in n8n
2. Toggle the **"Active"** switch in the top-right corner
3. For the cron workflow, verify the next execution time in the **"Executions"** tab

---

## Testing

### Test Lead Outreach Workflow:
1. In Notion, create a test lead with `Status = "site_built"`
2. Manually trigger the workflow (click **"Execute Workflow"**)
3. Check n8n executions log for errors
4. Verify webhook call to OpenClaw

### Test Response Handler:
```bash
curl -X POST http://127.0.0.1:5678/webhook/fredrick-response-handler \
  -H "Content-Type: application/json" \
  -d '{
    "lead_name": "Test Business",
    "lead_address": "123 Main St",
    "lead_phone": "555-1234",
    "lead_email": "test@example.com",
    "site_url": "https://testbusiness.com",
    "lead_id": "abc123"
  }'
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Notion node fails | Verify database ID and API key; check Leads DB has correct properties |
| Gmail send fails | Re-authenticate Gmail OAuth; verify sender is davelonski12@gmail.com |
| Webhook not receiving | Check webhook URL; ensure n8n is accessible at 127.0.0.1:5678 |
| OpenClaw call fails | Verify Gateway running at :18789 and Dashboard at :7891 |
| Lead data missing | Check Notion property names match workflow expressions (case-sensitive) |

---

## File Locations

- Workflows: `~/Desktop/local-lead-gen/n8n-workflows/`
- Documentation: `~/Desktop/local-lead-gen/docs/n8n-setup.md`
- Notion reference: `~/.openclaw/workspace-main/NOTION.md`

---

## Next Steps

1. Create the Leads database in Notion with the specified properties
2. Update both workflow JSON files with the actual database ID
3. Import workflows into n8n
4. Configure credentials (Notion API + Gmail OAuth)
5. Activate workflows
6. Test with a sample lead
