#!/usr/bin/env python3
"""
Local Lead Gen Scraper
Uses Playwright to scrape Google Maps for businesses without websites
"""

import json
import asyncio
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeout

async def scrape_leads(niche, location="Rochester, NY", max_results=10):
    """
    Scrape leads from Google Maps for a given niche and location
    """
    leads = []
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        )
        page = await context.new_page()
        
        # Google Maps search
        search_query = f"{niche} in {location}"
        maps_url = f"https://www.google.com/maps/search/{search_query.replace(' ', '+')}"
        
        try:
            print(f"Searching: {search_query}")
            await page.goto(maps_url, timeout=30000)
            await page.wait_for_timeout(5000)  # Wait for results
            
            # Scroll to load more results
            for _ in range(3):
                await page.keyboard.press("End")
                await page.wait_for_timeout(2000)
            
            # Extract business cards
            # Google Maps business results
            business_cards = await page.query_selector_all("div.Nv2PK")
            
            print(f"Found {len(business_cards)} business cards")
            
            for idx, card in enumerate(business_cards[:max_results]):
                try:
                    # Name
                    name_elem = await card.query_selector("div.qBF1Pd")
                    name = await name_elem.inner_text() if name_elem else f"Business {idx+1}"
                    
                    # Get all text content
                    card_text = await card.inner_text()
                    
                    # Try to find address (usually in the card)
                    address = "Address not found"
                    phone = "Phone not found"
                    
                    # Simple extraction - look for phone pattern
                    import re
                    phone_match = re.search(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}', card_text)
                    if phone_match:
                        phone = phone_match.group()
                    
                    # Check if they have a website (we want ones WITHOUT)
                    website_elem = await card.query_selector("a[href*='http']")
                    has_website = website_elem is not None
                    
                    if has_website:
                        # Check if it's a real website or just Google Maps link
                        href = await website_elem.get_attribute("href")
                        if href and 'google.com' not in href and 'maps' not in href:
                            print(f"Skipping {name} - has website: {href[:50]}")
                            continue
                    
                    leads.append({
                        "name": name.strip(),
                        "address": address.strip(),
                        "phone": phone.strip(),
                        "niche": niche,
                        "status": "new",
                        "site_url": ""
                    })
                    
                except Exception as e:
                    print(f"Error extracting business {idx}: {e}")
                    continue
            
        except PlaywrightTimeout:
            print("Timeout while loading search results")
        except Exception as e:
            print(f"Error during scraping: {e}")
        finally:
            await browser.close()
    
    return leads

def load_existing_leads():
    """Load existing leads from leads.json"""
    try:
        with open("/Users/Fredrick/Desktop/local-lead-gen/leads.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return []

def save_leads(leads):
    """Save leads to leads.json"""
    with open("/Users/Fredrick/Desktop/local-lead-gen/leads.json", "w") as f:
        json.dump(leads, f, indent=2)

if __name__ == "__main__":
    import sys
    
    niche = sys.argv[1] if len(sys.argv) > 1 else "restaurant"
    location = sys.argv[2] if len(sys.argv) > 2 else "Rochester, NY"
    
    print(f"Scraping {niche} leads in {location}...")
    
    # Run the async scraper
    leads = asyncio.run(scrape_leads(niche, location))
    
    # Load existing and merge
    existing = load_existing_leads()
    
    # Only add truly new leads (by name)
    existing_names = {lead["name"] for lead in existing}
    new_leads = [lead for lead in leads if lead["name"] not in existing_names]
    
    all_leads = existing + new_leads
    save_leads(all_leads)
    
    print(f"Found {len(new_leads)} new leads. Total: {len(all_leads)}")
    print(f"New leads: {json.dumps(new_leads, indent=2)}")
