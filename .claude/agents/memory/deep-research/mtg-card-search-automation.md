# Research Report: MTG Card Search Automation for Resellers

**Date**: 2026-01-30
**Scope**: Automated card availability checking across 4 MTG reseller sources

## Executive Summary

This research investigates programmatic access methods for checking MTG card availability across four distinct sources: two WooCommerce-based e-commerce sites (Black Lotus Cards and A Game Card Shop) and two public Google Sheets. All four sources are accessible programmatically with varying levels of complexity:

- **Google Sheets**: Both sheets are publicly accessible via CSV export URLs (VERIFIED via testing)
- **Black Lotus Cards**: WooCommerce site with REST API access (requires API credentials)
- **A Game Card Shop (USea)**: WooCommerce site, though access was blocked during testing (403 error)

**Recommended Approach**: Start with Google Sheets (easiest), then implement WooCommerce API access for the e-commerce sites. Consider web scraping as a fallback only if API access is unavailable.

## Key Findings

### Finding 1: Google Sheets Are Publicly Accessible via CSV Export

Both Google Sheets successfully export to CSV format using direct URLs:

**Sheet 1 (Black Lotus Updated Cards List)**:
- URL: https://docs.google.com/spreadsheets/d/1E2iSRhhNUjaZ3MblXx_rflpOIkMwK40OgX5X6yXE4zw/export?format=csv&gid=0
- Status: **VERIFIED** - Downloaded 216KB (2,811 lines)
- Structure: 6 columns with categories for REGULAR CARDS, HOLO CARDS, and FOIL CARDS
- Contains: Product names, stock status, pricing information

**Sheet 2 (Ron's Cards List)**:
- URL: https://docs.google.com/spreadsheets/d/1FrEtQzYRvVaU6cLliyQho9yCJZPyPRTW/export?format=csv&gid=685162865
- Status: **VERIFIED** - Downloaded 1.3KB (16 lines)
- Contains: Links to YouTube, Imgur, Pinterest resources and set information

**CSV Export URL Pattern**:
https://docs.google.com/spreadsheets/d/{SHEET_ID}/export?format=csv&gid={GID}

Where:
- SHEET_ID = the long string between /d/ and /edit in the sheet URL
- gid = the sheet tab ID (from #gid= in URL)

### Finding 2: Black Lotus Cards Uses WooCommerce with REST API

Black Lotus Cards is a WordPress/WooCommerce site (confirmed via source analysis):

**Platform Details**:
- WooCommerce version: 10.3.7
- WordPress version: 6.9
- Theme: Shoptimizer 2.7.7

**Available API Endpoints**:
- REST API base: https://blacklotuscards.com/wp-json/
- WooCommerce AJAX: /?wc-ajax=%%endpoint%%
- WordPress AJAX: /wp-admin/admin-ajax.php

**Search Capabilities**:
- Filter by price ranges
- Filter by product categories
- Filter by product types (Regular, Foil, Holo, Galaxy Foil, etc.)
- Sort options (name, price, popularity, rating)
- Pagination support

**WooCommerce REST API Features**:
- Product search by name using search parameter
- Filter by SKU, category, attributes
- Pagination with per_page parameter
- Requires API credentials (Consumer Key + Consumer Secret)
- Generated at: WooCommerce > Settings > Advanced > REST API

**Authentication**: Basic Auth with consumer key (username) and consumer secret (password)

### Finding 3: A Game Card Shop (USea) Is Also WooCommerce-Based

**Platform Details**:
- Confirmed WooCommerce site (version 10.3.7)
- WordPress version: 6.9
- Theme: Shoptimizer 2.7.7
- **NOTE**: Direct access returned 403 Forbidden during testing

**Site Structure**:
- Main shop: https://www.agamecardshop.com/?post_type=product
- Bundle category: https://www.agamecardshop.com/product-category/bundle/
- Products feed: https://www.agamecardshop.com/shop/feed/

**Unique Characteristics**:
- Sells proxy MTG cards (reproductions, not authentic cards)
- Maintains a complete cards list in a spreadsheet (may be publicly accessible)
- Has YouTube channel with card videos

**Access Considerations**:
- Site blocked direct curl access (403 error)
- May require User-Agent headers or cookies
- REST API access would require credentials from site owner
- Web scraping would require handling anti-bot measures

### Finding 4: Web Scraping as Fallback Option

If API access is unavailable, web scraping is viable but requires careful implementation:

**Tool Selection**:

| Scenario | Tool | Reason |
|----------|------|--------|
| Static HTML pages | BeautifulSoup | Fast, lightweight, easy to use |
| JavaScript-heavy sites | Selenium | Can execute JS, interact with dynamic content |
| Large-scale projects | Scrapy | Built-in rate limiting, concurrent requests |
| Hybrid approach | Selenium + BeautifulSoup | Selenium renders, BeautifulSoup parses |

**BeautifulSoup - Use When**:
- Page content is in initial HTML (not JS-rendered)
- No user interaction needed
- Speed is important
- Resource constraints exist

**Selenium - Use When**:
- Content loads via JavaScript
- Need to click buttons, scroll, fill forms
- Dealing with SPAs (Single Page Applications)
- Infinite scroll or dynamic loading

### Finding 5: Rate Limiting and Ethical Scraping Requirements

**Critical Best Practices**:

1. **Always Check robots.txt**
   - Check before scraping: https://example.com/robots.txt
   - Respect Disallow directives
   - Honor Crawl-delay if specified
   - Not legally binding but ethically essential

2. **Implement Rate Limiting**
   - Use time.sleep() between requests (minimum 1-2 seconds)
   - Implement exponential backoff for 429 errors
   - Make requests indistinguishable from human behavior
   - Use libraries like aiometer for async rate limiting

3. **Identify Your Bot**
   - Use transparent User-Agent string
   - Include contact information
   - Example: "MyMTGBot/1.0 (contact@example.com)"

4. **HTTP 429 Response Handling**
   - Watch for "Too Many Requests" errors
   - Implement exponential backoff
   - Track token bucket limits if exposed

5. **Legal and Ethical Considerations**
   - Respect terms of service
   - Don't overload servers
   - Avoid scraping personal data
   - Consider asking for permission

## Comparison: Access Methods

| Source | Platform | Access Method | Auth Required | Tested | Difficulty |
|--------|----------|---------------|---------------|--------|-----------|
| Black Lotus Sheet | Google Sheets | CSV Export URL | No | ✅ Yes (216KB) | Easy |
| Ron's Sheet | Google Sheets | CSV Export URL | No | ✅ Yes (1.3KB) | Easy |
| Black Lotus Cards | WooCommerce | REST API | Yes (API Key) | ❌ No | Medium |
| A Game Card Shop | WooCommerce | REST API / Scraping | Yes / Maybe | ❌ No (403) | Hard |

## Recommendations

### Primary Recommendation: Hybrid Approach

**Implementation Priority**:

1. **Phase 1: Google Sheets (Immediate)**
   - Implement CSV download via requests library
   - Parse with pandas or built-in csv module
   - No authentication required
   - Fast, reliable, simple

2. **Phase 2: Black Lotus Cards API (Short-term)**
   - Request API credentials from site owner
   - Implement WooCommerce REST API client
   - Use official woocommerce Python package
   - Proper error handling and rate limiting

3. **Phase 3: A Game Card Shop (Long-term)**
   - **Option A**: Request API credentials (preferred)
   - **Option B**: Respectful web scraping if necessary
     - Check robots.txt first
     - Use appropriate User-Agent
     - Implement 2-3 second delays
     - Consider BeautifulSoup + requests for static content

**Rationale**:
- Google Sheets provide immediate value with zero barriers
- WooCommerce API is official, supported, and reliable
- Web scraping should be last resort due to fragility and ethical concerns
- Phased approach allows incremental value delivery

**Caveats**:
- WooCommerce API requires site owner cooperation
- A Game Card Shop has anti-bot measures (403 response)
- Sheets may change structure without notice
- Consider caching to minimize requests

### Alternative: Pure Scraping Approach

**When to Use**: If API access is impossible to obtain

**Implementation**:
1. Use requests with custom User-Agent headers
2. Parse with BeautifulSoup for static content
3. Upgrade to Selenium only if JavaScript rendering required
4. Implement robust error handling for blocks/rate limits
5. Cache results to minimize requests
6. Monitor for structure changes

**Trade-offs**:
- More fragile (breaks when HTML changes)
- Risk of IP blocking
- Ethical concerns if overused
- May violate terms of service

## Python Libraries Recommendation

### Core Libraries

| Library | Purpose | Install | Priority |
|---------|---------|---------|----------|
| requests | HTTP requests | pip install requests | Essential |
| pandas | CSV/data processing | pip install pandas | Essential |
| beautifulsoup4 | HTML parsing | pip install beautifulsoup4 | High |
| lxml | Fast XML/HTML parser | pip install lxml | High |
| woocommerce | WooCommerce API | pip install woocommerce | Medium |
| selenium | JS rendering (if needed) | pip install selenium | Low |
| retry | Automatic retries | pip install retry | Medium |

### Optional Enhancement Libraries

| Library | Purpose | When to Use |
|---------|---------|-------------|
| gspread | Google Sheets API | If need write access to sheets |
| gspread-dataframe | Pandas integration | If using Sheets API + pandas |
| aiometer | Async rate limiting | For high-volume async scraping |
| httpx | Modern async HTTP | Alternative to requests for async |

## Action Items

- [x] Test Google Sheets CSV export URLs (COMPLETED)
- [ ] Request API credentials from Black Lotus Cards owner
- [ ] Request API credentials from A Game Card Shop owner
- [ ] Check robots.txt for both WooCommerce sites
- [ ] Implement Google Sheets CSV parser (Phase 1)
- [ ] Build card matching algorithm (fuzzy string matching)
- [ ] Implement WooCommerce API client (Phase 2)
- [ ] Add caching layer to minimize requests
- [ ] Create user interface for card lookup

## Implementation Sketch

```python
import requests
import pandas as pd
from woocommerce import API

# Google Sheets Access (TESTED - WORKS)
def fetch_black_lotus_sheet():
    url = "https://docs.google.com/spreadsheets/d/1E2iSRhhNUjaZ3MblXx_rflpOIkMwK40OgX5X6yXE4zw/export?format=csv&gid=0"
    df = pd.read_csv(url)
    return df

def fetch_rons_sheet():
    url = "https://docs.google.com/spreadsheets/d/1FrEtQzYRvVaU6cLliyQho9yCJZPyPRTW/export?format=csv&gid=685162865"
    df = pd.read_csv(url)
    return df

# WooCommerce API Access (REQUIRES CREDENTIALS)
def search_black_lotus_api(card_name, consumer_key, consumer_secret):
    wcapi = API(
        url="https://blacklotuscards.com",
        consumer_key=consumer_key,
        consumer_secret=consumer_secret,
        version="wc/v3"
    )
    response = wcapi.get("products", params={"search": card_name})
    return response.json()

# Fallback: Web Scraping (USE ONLY IF NECESSARY)
from bs4 import BeautifulSoup
import time

def scrape_product_search(url, card_name):
    headers = {
        'User-Agent': 'MTGCardChecker/1.0 (contact@example.com)'
    }
    time.sleep(2)  # Rate limiting
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, 'lxml')
    # Parse product listings...
    return results
```

## Uncertainties

1. **API Credential Access**: Unknown if site owners will provide API keys
2. **A Game Card Shop Access**: 403 error suggests anti-bot measures; may require:
   - Session cookies
   - CAPTCHA solving
   - Rotating proxies
   - Or simply permission from owner
3. **Sheet Structure Stability**: Google Sheets may change column structure without notice
4. **Update Frequency**: Unknown how often inventory updates
5. **Card Name Matching**: Need fuzzy matching for variations (e.g., "Lightning Bolt" vs "Lightning Bolt [M10]")

## Related Topics

- Fuzzy string matching algorithms (Levenshtein distance, fuzz ratio)
- MTG card name normalization (set codes, special characters)
- Database design for card inventory caching
- Real-time vs batch update strategies
- User interface design for card availability checking
- Integration with deck management tools
- Price comparison across vendors
- Scryfall API for card data validation

## Sources Summary

### Google Sheets Access
1. [How to Download Google Spreadsheet as a CSV](https://yasha.solutions/posts/2025-10-24-how-to-download-google-spreadsheet-as-a-csv-from-a-public-url/)
2. [How to Create a CSV or Excel Direct Download Link](https://www.highviewapps.com/blog/how-to-create-a-csv-or-excel-direct-download-link-in-google-sheets/)

### WooCommerce API
3. [WooCommerce REST API Developer Guide](https://brainspate.com/blog/woocommerce-rest-api-developer-guide/)
4. [WooCommerce REST API Documentation](https://woocommerce.github.io/woocommerce-rest-api-docs/)
5. [WooCommerce REST API Integration Guide](https://www.cloudways.com/blog/woocommerce-rest-api/)
6. [WooCommerce Python Package](https://pypi.org/project/WooCommerce/)
7. [How to work with WooCommerce REST API with Python](https://linuxconfig.org/how-to-work-with-the-woocommerce-rest-api-with-python)

### Web Scraping Tools
8. [Selenium vs BeautifulSoup Comparison](https://www.zenrows.com/blog/selenium-vs-beautifulsoup)
9. [BeautifulSoup vs Selenium Guide](https://www.browserstack.com/guide/beautifulsoup-vs-selenium)
10. [MTG Card Info Scraper Example](https://github.com/dreamsincode/MTG-card-info)
11. [Selenium Web Scraping Guide 2026](https://www.scrapingbee.com/blog/selenium-python/)

### Rate Limiting & Ethics
12. [Rate Limiting in Web Scraping](https://scrapfly.io/blog/posts/what-is-rate-limiting-everything-you-need-to-know)
13. [Web Scraping Best Practices 2026](https://medium.com/@datajournal/dos-and-donts-of-web-scraping-in-2025-e4f9b2a49431)
14. [Robots.txt for Web Scraping](https://dataprixa.com/robots-txt-for-web-scraping/)
15. [Responsible Scraper Etiquette](https://bytetunnels.com/posts/responsible-scraper-etiquette-best-practices/)
16. [How to Rate Limit Async Requests](https://scrapfly.io/blog/posts/how-to-rate-limit-asynchronous-python-requests)

### Python Libraries
17. [gspread-pandas Documentation](https://github.com/aiguofer/gspread-pandas)
18. [gspread-dataframe Documentation](https://pythonhosted.org/gspread-dataframe/)

---

**Research Completed**: 2026-01-30
**Next Update Recommended**: When implementing Phase 1 (Google Sheets parser)
