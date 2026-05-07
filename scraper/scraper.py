#!/usr/bin/env python3
"""
Local Lead Gen Scraper
Uses Playwright to scrape local business leads
"""

import json
import asyncio
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeout

async def scrape_leads(niche, location="Rochester, NY", max_results=10):
    """
    Scrape leads for a given niche and location
    
    Args:
        niche: Type of business (restaurant, salon, contractor)
        location: City/location to search
        max_results: Maximum number of results to return
    
    Returns:
        List of lead dictionaries with name, address, phone
    """
    leads = []
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Construct search query based on niche
        search_query = f"{niche} in {location}"
        search_url = f"https://www.google.com/search?q={search_query.replace(' ', '+')}"
        
        try:
            await page.goto(search_url, timeout=30000)
            await page.wait_for_timeout(3000)  # Wait for results to load
            
            # Extract business information from Google search results
            # This is a simplified version - in production, use Google Maps API or similar
            business_elements = await page.query_selector_all("div.VkpGBb")
            
            for idx, element in enumerate(business_elements[:max_results]):
                try:
                    name_elem = await element.query_selector("div.qBF1Pd")
                    name = await name_elem.inner_text() if name_elem else f"Business {idx + 1}"
                    
                    address_elem = await element.query_selector("div.W4Efsd span")
                    address = await address_elem.inner_text() if address_elem else "Address not found"
                    
                    phone_elem = await element.query_selector("span.LrzXr")
                    phone = await phone_elem.inner_text() if phone_elem else "Phone not found"
                    
                    leads.append({
                        "name": name.strip(),
                        "address": address.strip(),
                        "phone": phone.strip(),
                        "niche": niche,
                        "status": "new"
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

def get_new_leads():
    """Get only new leads that haven't been processed"""
    existing = load_existing_leads()
    processed_names = {lead["name"] for lead in existing if lead.get("status") != "new"}
    
    # In a real scenario, you'd scrape fresh leads and compare
    # For now, return existing new leads
    return [lead for lead in existing if lead.get("status") == "new"]

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
