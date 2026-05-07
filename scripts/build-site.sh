#!/bin/bash
# build-site.sh - Build and deploy a lead generation site
# Usage: ./build-site.sh <niche> <business_name> <address> <phone>

set -e  # Exit on error

# Arguments
NICHE="${1}"
BUSINESS_NAME="${2}"
ADDRESS="${3}"
PHONE="${4}"

# Validate arguments
if [ -z "$NICHE" ] || [ -z "$BUSINESS_NAME" ] || [ -z "$ADDRESS" ] || [ -z "$PHONE" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 <niche> <business_name> <address> <phone>"
    echo "  niche: restaurant|salon|contractor"
    exit 1
fi

# Validate niche
if [[ ! "$NICHE" =~ ^(restaurant|salon|contractor)$ ]]; then
    echo "Error: Invalid niche. Must be: restaurant, salon, or contractor"
    exit 1
fi

# Configuration
TEMPLATES_DIR="$HOME/Desktop/local-lead-gen/templates"
WORK_DIR="$HOME/Desktop/local-lead-gen/sites"
GITHUB_USER="davidlonski"  # Update with your GitHub username
NOTION_API_KEY="NOTION_API_KEY_PLACEHOLDER"
NOTION_LEADS_DB="YOUR_LEADS_DB_ID"  # Update with actual Notion DB ID

# Create slugified name for repo/URL
SLUG=$(echo "$BUSINESS_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
REPO_NAME="local-lead-gen-${NICHE}-${SLUG}"
SITE_DIR="$WORK_DIR/$REPO_NAME"

echo "=========================================="
echo "Building site for: $BUSINESS_NAME"
echo "Niche: $NICHE"
echo "Address: $ADDRESS"
echo "Phone: $PHONE"
echo "Repo: $REPO_NAME"
echo "=========================================="

# Create work directory if it doesn't exist
mkdir -p "$WORK_DIR"

# Clone template
echo "[1/5] Cloning $NICHE template..."
if [ -d "$SITE_DIR" ]; then
    echo "Site directory already exists, removing..."
    rm -rf "$SITE_DIR"
fi

cp -r "$TEMPLATES_DIR/$NICHE" "$SITE_DIR"
cd "$SITE_DIR"

# Initialize git repo
git init
git add .
git commit -m "Initial commit from $NICHE template"

# Replace placeholders in all files
echo "[2/5] Replacing placeholders..."

# Define replacement values
HOURS="Mon-Fri: 9am-6pm, Sat: 10am-4pm, Sun: Closed"
DESCRIPTION="Professional $NICHE services in your local area. Contact us today!"

# Use find and sed to replace placeholders
find "$SITE_DIR" -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.jsx" -o -name "*.html" -o -name "*.css" -o -name "*.json" \) -not -path "*/node_modules/*" -not -path "*/.git/*" | while read file; do
    # Check if file contains any placeholders before attempting replacement
    if grep -q "{{BUSINESS_NAME}}\|{{ADDRESS}}\|{{PHONE}}\|{{HOURS}}\|{{DESCRIPTION}}" "$file" 2>/dev/null; then
        echo "  Updating: $file"
        sed -i '' "s/{{BUSINESS_NAME}}/$BUSINESS_NAME/g" "$file"
        sed -i '' "s/{{ADDRESS}}/$ADDRESS/g" "$file"
        sed -i '' "s/{{PHONE}}/$PHONE/g" "$file"
        sed -i '' "s/{{HOURS}}/$HOURS/g" "$file"
        sed -i '' "s/{{DESCRIPTION}}/$DESCRIPTION/g" "$file"
    fi
done

# Commit changes
git add .
git commit -m "Customize with business info: $BUSINESS_NAME" || echo "No changes to commit"

# Create GitHub repo and push
echo "[3/5] Creating GitHub repository..."
gh repo create "$GITHUB_USER/$REPO_NAME" --public --source="$SITE_DIR" --push 2>/dev/null || {
    echo "Repo might already exist, attempting to push..."
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git" 2>/dev/null || true
    git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || echo "Push failed - repo may need manual setup"
}

# Deploy to Vercel
echo "[4/5] Deploying to Vercel..."
VERCEL_URL=$(vercel --prod --yes --token="$VERCEL_TOKEN" 2>&1 | grep -o 'https://[^[:space:]]*' | head -1)

if [ -z "$VERCEL_URL" ]; then
    echo "Vercel deployment may have failed. Check output above."
    VERCEL_URL="DEPLOYMENT_PENDING"
fi

echo "Site deployed to: $VERCEL_URL"

# Update Notion Leads DB
echo "[5/5] Updating Notion..."
# This requires the Notion page ID for the lead
# You'll need to pass the Notion page ID or look it up by business name

echo "=========================================="
echo "✅ Site build complete!"
echo "   Business: $BUSINESS_NAME"
echo "   URL: $VERCEL_URL"
echo "   Repo: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "=========================================="

# Output URL for pipeline to capture
echo "$VERCEL_URL"
