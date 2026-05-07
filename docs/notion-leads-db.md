# Notion Leads Database Schema

## Database: Leads (for Local Lead Gen Project)

**Purpose:** Track local business leads through the outreach pipeline — from initial discovery to site building to conversion.

**Database ID:** `LEADS_DB_ID_PLACEHOLDER` (replace with actual ID after creating in Notion)

---

## Properties

| Property | Type | Options/Notes |
|----------|------|---------------|
| `Name` | title | Business name (e.g., "Joe's Pizza") |
| `Status` | select | `discovered`, `contacted`, `site_building`, `site_built`, `outreached`, `responded`, `converted`, `lost` |
| `Address` | rich_text | Full business address |
| `Phone` | phone | Business phone number |
| `Email` | email | Business email (for outreach) |
| `Site URL` | url | URL of the built site (when ready) |
| `Lead Source` | select | `Google Maps`, `Yelp`, `Referral`, `Cold Call`, `Other` |
| `Priority` | select | `High`, `Medium`, `Low` |
| `Notes` | rich_text | Any additional context about the lead |
| `Date Added` | date | Auto-set when lead is created |
| `Last Contact` | date | Updated when outreach happens |
| `Site Built Date` | date | When the website was completed |

---

## Status Flow

```
discovered → contacted → site_building → site_built → outreached → responded → converted
     ↓              ↓               ↓               ↓              ↓             ↓
  lost           lost            lost            lost          lost         lost
```

**Key Statuses for Automation:**
- `site_built` — Triggers the weekly outreach workflow (lead-outreach.json)
- `outreached` — Set automatically by fredrick-response-handler.json after email is sent

---

## Example Entry

| Field | Value |
|-------|-------|
| Name | "Mario's Italian Bistro" |
| Status | `site_built` |
| Address | "123 Main St, Rochester, NY 14623" |
| Phone | "(585) 555-0123" |
| Email | "mario@mariosbistro.com" |
| Site URL | "https://mariositalianbistro.com" |
| Lead Source | `Google Maps` |
| Priority | `High` |
| Date Added | "2026-05-01" |
| Site Built Date | "2026-05-06" |

---

## Notion API Integration

**Query site_built leads:**
```python
import requests

API_KEY = "NOTION_API_KEY_PLACEHOLDERabX7"
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json"
}
LEADS_DB_ID = "YOUR_DB_ID_HERE"

response = requests.post(
    f"https://api.notion.com/v1/databases/{LEADS_DB_ID}/query",
    headers=HEADERS,
    json={
        "filter": {
            "property": "Status",
            "select": {
                "equals": "site_built"
            }
        }
    }
)

leads = response.json()["results"]
for lead in leads:
    props = lead["properties"]
    print(f"Name: {props['Name']['title'][0]['text']['content']}")
    print(f"ID: {lead['id']}")
```

---

## Creating This Database

1. In Notion, click **"+ New Page"** → **"Database"** → **"Table"**
2. Name it **"Leads - Local Lead Gen"**
3. Add the properties above (delete default columns first)
4. Copy the database ID from the URL:
   - URL format: `https://www.notion.so/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx?v=yyyyyyyy`
   - Database ID is the `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` part (32 hex chars)
5. Update `LEADS_DB_ID_PLACEHOLDER` in:
   - This file
   - `lead-outreach.json`
   - `fredrick-response-handler.json`

---

## Integration with n8n Workflows

- **lead-outreach.json** queries this DB for `Status = "site_built"`
- **fredrick-response-handler.json** updates lead status to `"outreached"` after sending email
- Both workflows need the actual database ID to function

---

## Notes

- Property names are **case-sensitive** in n8n expressions
- Notion API has rate limits: ~3 requests/second
- Always use the `2022-06-28` API version for consistency
- Rich text fields have a 2000 character limit per "text" object
