# Local Lead Gen Automation Guide

## Overview

This project automates the creation of lead generation websites for local businesses. The pipeline:
1. Scrapes local business leads (restaurants, salons, contractors)
2. Builds customized websites from templates
3. Deploys sites to Vercel
4. Updates lead status in Notion
5. Triggers outreach workflows via n8n

## Prerequisites

### Required Tools
- **Node.js & npm** - For template dependencies
- **Git** - Version control
- **GitHub CLI (gh)** - Repository creation
- **Vercel CLI** - Deployment (`npm i -g vercel`)
- **Python 3** - Scraper runtime
- **Playwright** - Scraper browser automation (`pip install playwright && playwright install`)
- **jq** - JSON processing (`brew install jq`)
- **curl** - API requests

### Required Accounts & API Keys
- **GitHub** - Log in via `gh auth login`
- **Vercel** - Log in via `vercel login`
- **Notion** - API key: `NOTION_API_KEY_PLACEHOLDER`
- **n8n** - Running locally at `http://127.0.0.1:5678`

## Quick Start

### Run Full Pipeline
```bash
cd ~/Desktop/local-lead-gen
./scripts/fredrick-pipeline.sh
```

This will:
- Scrape new leads for all niches
- Build and deploy sites for new leads
- Update Notion with site URLs
- Trigger n8n outreach workflow

### Build Single Site
```bash
cd ~/Desktop/local-lead-gen
./scripts/build-site.sh restaurant "Joe's Pizza" "123 Main St, Rochester, NY" "(585) 555-1234"
```

## Scripts Reference

### `build-site.sh`
Builds and deploys a single lead generation site.

**Arguments:**
1. `niche` - Business type: `restaurant`, `salon`, or `contractor`
2. `business_name` - Full business name
3. `address` - Business address
4. `phone` - Contact phone number

**What it does:**
- Clones the appropriate template from `templates/<niche>/`
- Replaces placeholders (`{{BUSINESS_NAME}}`, `{{ADDRESS}}`, etc.) in all files
- Creates a new GitHub repository: `local-lead-gen-<niche>-<slugified-name>`
- Pushes code to GitHub
- Deploys to Vercel
- Outputs the Vercel deployment URL

**Example:**
```bash
./scripts/build-site.sh contractor "Mike's Plumbing" "456 Oak Ave, Rochester, NY" "(585) 555-5678"
```

### `fredrick-pipeline.sh`
Orchestrates the complete lead generation workflow.

**Steps:**
1. Runs Playwright scraper for all niches (restaurant, salon, contractor)
2. Reads `leads.json` and finds leads with status "new"
3. For each new lead:
   - Calls `build-site.sh` to create and deploy site
   - Updates lead status to "site_built" with site URL
   - Updates Notion (if configured)
   - Triggers n8n webhook for outreach
4. Outputs summary statistics

## Checking Status

### In Notion
1. Open your Notion Leads Database
2. Filter by status:
   - `new` - Leads scraped but no site built
   - `site_built` - Site deployed, ready for outreach
   - `contacted` - Outreach initiated
   - `converted` - Lead converted to customer

### Local Leads File
View all leads and their status:
```bash
cat ~/Desktop/local-lead-gen/leads.json | jq '.[] | {name, niche, status, site_url}'
```

### Check Specific Lead
```bash
cat ~/Desktop/local-lead-gen/leads.json | jq '.[] | select(.name == "Joe'\''s Pizza")'
```

## Troubleshooting

### Scraper Issues

**Problem:** No leads found
- **Solution:** Check internet connection, verify Playwright is installed (`playwright install`), try different location/search terms

**Problem:** Playwright timeout
- **Solution:** Increase timeout in `scraper.py`, check if headless mode works, try with `headless=False` for debugging

### Build/Deploy Issues

**Problem:** GitHub repo creation fails
- **Solution:** 
  - Verify `gh auth status`
  - Check if repo name already exists
  - Ensure GitHub username is correct in `build-site.sh`

**Problem:** Vercel deployment fails
- **Solution:**
  - Verify `vercel login` is active
  - Check Vercel token: `vercel whoami`
  - Review build logs: `vercel logs <deployment-url>`
  - Ensure template builds locally first: `cd templates/restaurant && npm install && npm run build`

**Problem:** Placeholder replacement not working
- **Solution:** Ensure template files contain the placeholders (`{{BUSINESS_NAME}}`, etc.). You may need to add them to the template files manually.

### Notion Integration Issues

**Problem:** Notion API errors
- **Solution:**
  - Verify API key is correct
  - Check that integration has access to the database
  - Verify database ID is correct
  - Check API key permissions

### n8n Webhook Issues

**Problem:** n8n webhook not triggering
- **Solution:**
  - Verify n8n is running: `open http://127.0.0.1:5678`
  - Check webhook path in n8n workflow matches `http://127.0.0.1:5678/webhook/lead-outreach`
  - Test webhook manually: `curl -X POST http://127.0.0.1:5678/webhook/lead-outreach -H "Content-Type: application/json" -d '{"test": true}'`

## Manual Steps Required

### Adding Placeholders to Templates
The templates don't have placeholders by default. You need to add them to key files:

**In `templates/<niche>/src/app/page.tsx`:**
```tsx
<h1>{{BUSINESS_NAME}}</h1>
<p>Address: {{ADDRESS}}</p>
<p>Phone: {{PHONE}}</p>
<p>Hours: {{HOURS}}</p>
<p>{{DESCRIPTION}}</p>
```

**In `templates/<niche>/src/app/layout.tsx`:**
```tsx
<title>{{BUSINESS_NAME}} - Professional Services</title>
<meta name="description" content="{{DESCRIPTION}}" />
```

### Setting Up Notion Database
Create a Notion database with these properties:
- **Name** (Title)
- **Address** (Text)
- **Phone** (Text)
- **Niche** (Select: restaurant, salon, contractor)
- **Status** (Select: new, site_built, contacted, converted)
- **Site URL** (URL)
- **Created At** (Date)
- **Updated At** (Date)

### Configuring n8n Workflow
1. Open n8n at `http://127.0.0.1:5678`
2. Create a new workflow
3. Add a **Webhook** node (POST `/lead-outreach`)
4. Add subsequent nodes for your outreach (email, SMS, etc.)
5. Activate the workflow

## File Structure

```
local-lead-gen/
├── templates/           # Next.js templates by niche
│   ├── restaurant/
│   ├── salon/
│   └── contractor/
├── scripts/            # Automation scripts
│   ├── build-site.sh
│   └── fredrick-pipeline.sh
├── scraper/            # Playwright scraper
│   └── scraper.py
├── sites/              # Generated sites (created during build)
├── docs/               # Documentation
│   └── automation-guide.md
├── n8n-workflows/      # Exported n8n workflows
├── leads.json          # Lead data (created by scraper)
└── .gitignore
```

## Next Steps

1. **Add placeholders** to template files
2. **Test scraper:** `python3 scraper/scraper.py restaurant`
3. **Test single build:** `./scripts/build-site.sh restaurant "Test Biz" "123 St" "555-1234"`
4. **Configure Notion** database and update script with DB ID
5. **Set up n8n** workflow for outreach
6. **Run full pipeline:** `./scripts/fredrick-pipeline.sh`
7. **Schedule pipeline** with cron or OpenClaw heartbeat

## Notes

- The scraper uses Google search results (simplified). For production, use Google Maps API or Yelp API for better data.
- Rate limiting is built in (5-second delay between leads). Adjust as needed.
- Sites are deployed to Vercel's free tier by default.
- All lead data is stored locally in `leads.json`. Back up regularly.
- Notion integration requires manual setup of database and page IDs.
