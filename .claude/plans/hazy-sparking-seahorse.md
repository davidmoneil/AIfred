# Proxy Card Search Enhancement Plan

## Overview

Enhance the MTG dashboard's proxy card search with:
1. **Caching** for Google Sheets data
2. **High-precision matching** (substring identity, not fuzzy)
3. **Image thumbnails** from Google Photos links
4. **USea integration** via discovered WooCommerce Store API (no scraping needed!)

## Key Discovery

**USea (agamecardshop.com) has a public, unauthenticated WooCommerce Store API:**
```
GET https://www.agamecardshop.com/wp-json/wc/store/v1/products?search=black+lotus
```
- Returns JSON with: name, price, stock status, images, permalink
- Supports: search, pagination, category filtering, sorting
- No API keys or authentication required
- **This eliminates need for Playwright/scraping entirely**

---

## Phase 1: Caching Infrastructure

### 1.1 Add Cache Module
**File**: `/Users/aircannon/Claude/Projects/mtg-card-sales/app/proxy_cache.py` (new)

```python
import time
from dataclasses import dataclass
from typing import Optional, Dict, Any

@dataclass
class CacheEntry:
    data: Any
    timestamp: float
    ttl: int = 300  # 5 minutes default

class ProxyCache:
    def __init__(self):
        self._cache: Dict[str, CacheEntry] = {}

    def get(self, key: str) -> Optional[Any]:
        entry = self._cache.get(key)
        if entry and (time.time() - entry.timestamp) < entry.ttl:
            return entry.data
        return None

    def set(self, key: str, data: Any, ttl: int = 300):
        self._cache[key] = CacheEntry(data=data, timestamp=time.time(), ttl=ttl)

    def invalidate(self, key: str):
        self._cache.pop(key, None)
```

### 1.2 Update fetch_proxy_sheets()
- Use cache before HTTP fetch
- Store results with 5-minute TTL
- Add manual "Refresh" button to invalidate cache

---

## Phase 2: High-Precision Matching

### 2.1 Matching Algorithm
User requirement: "close to 100% identity between substrings"

**Strategy**: Normalize both search term and target, then check if normalized search appears as complete word/phrase in target.

```python
def normalize_card_name(name: str) -> str:
    """Normalize for matching: lowercase, remove special chars, collapse spaces."""
    import unicodedata
    # Remove diacritics
    name = unicodedata.normalize('NFKD', name).encode('ascii', 'ignore').decode()
    # Lowercase and clean
    name = name.lower()
    # Remove special chars except spaces
    name = ''.join(c if c.isalnum() or c == ' ' else ' ' for c in name)
    # Collapse multiple spaces
    return ' '.join(name.split())

def is_high_precision_match(search: str, target: str) -> bool:
    """
    Returns True if search term appears as complete substring in target.
    Example: "Cavern of Souls" matches "Cavern of Souls #410a Neonink foil"
    """
    search_norm = normalize_card_name(search)
    target_norm = normalize_card_name(target)
    return search_norm in target_norm
```

### 2.2 Update search_in_sheets()
- Replace `card_lower in value_str.lower()` with `is_high_precision_match()`
- Add confidence score based on match position and length ratio

---

## Phase 3: Image Thumbnails

### 3.1 Sheet Structure (Confirmed by User)

**Black Lotus Sheet:**
- **SINGLES sheet** contains individual cards with Google Photos links
- Cell format: `https://photos.app.goo.gl/ePcDByecKCKYwpzx5`
- This is the primary source for card photos

**Ron's Sheet:**
- Multiple tabs: "Normal Set", "Holo Set", "Foil Set"
- Photos are links within cells in these specific sheets
- Different gid values needed for each tab

### 3.2 Update Sheet URLs to Fetch Multiple Tabs
```python
PROXY_SHEET_URLS = {
    # Black Lotus - SINGLES sheet (need to find correct gid)
    'black_lotus_singles': "https://docs.google.com/spreadsheets/d/1E2iSRhhNUjaZ3MblXx_rflpOIkMwK40OgX5X6yXE4zw/export?format=csv&gid=SINGLES_GID",

    # Ron's sheets - multiple tabs
    'rons_normal': "https://docs.google.com/spreadsheets/d/1FrEtQzYRvVaU6cLliyQho9yCJZPyPRTW/export?format=csv&gid=NORMAL_GID",
    'rons_holo': "https://docs.google.com/spreadsheets/d/1FrEtQzYRvVaU6cLliyQho9yCJZPyPRTW/export?format=csv&gid=HOLO_GID",
    'rons_foil': "https://docs.google.com/spreadsheets/d/1FrEtQzYRvVaU6cLliyQho9yCJZPyPRTW/export?format=csv&gid=FOIL_GID",
}
```
*Note: Will need to inspect sheets to get correct gid values for each tab*

### 3.3 Extract Google Photos Links
```python
import re

def extract_photo_url(cell_value: str) -> Optional[str]:
    """Extract Google Photos URL from cell content."""
    if pd.isna(cell_value):
        return None

    cell_str = str(cell_value)

    # Match Google Photos short links
    # Format: https://photos.app.goo.gl/XXXX
    match = re.search(r'https://photos\.app\.goo\.gl/\w+', cell_str)
    if match:
        return match.group(0)

    # Also match direct lh3.googleusercontent.com links
    match = re.search(r'https://lh3\.googleusercontent\.com/[^\s"\']+', cell_str)
    if match:
        return match.group(0)

    return None
```

### 3.4 Resolve Short Links to Thumbnails
Google Photos short links (photos.app.goo.gl) redirect to album/photo pages. For thumbnails:
- Option A: Follow redirect to get actual image URL (slower but reliable)
- Option B: Display as clickable link that opens in new tab (simpler)
- Option C: Use placeholder + link for now, enhance later

**Recommended**: Start with Option B (links), add thumbnail resolution as enhancement

### 3.2 Display Thumbnails in Results
```python
# In callback, generate result cards with images
html.Div([
    html.Img(src=image_url, style={'height': '80px', 'marginRight': '10px'}),
    html.Div([
        html.Strong(card_name),
        html.Br(),
        html.Small(f"Source: {source} | Row {row}")
    ])
], style={'display': 'flex', 'alignItems': 'center', 'marginBottom': '10px'})
```

---

## Phase 4: USea Store API Integration

### 4.1 Add USea Search Function
**File**: Update `dashboard.py`

```python
USEA_API_URL = "https://www.agamecardshop.com/wp-json/wc/store/v1/products"

def search_usea(card_name: str, per_page: int = 10) -> list:
    """Search USea via WooCommerce Store API."""
    try:
        response = requests.get(
            USEA_API_URL,
            params={'search': card_name, 'per_page': per_page},
            timeout=10,
            headers={'User-Agent': 'MTGCardChecker/1.0'}
        )
        response.raise_for_status()

        products = response.json()
        return [{
            'source': 'usea',
            'name': p['name'],
            'price': p['price'],
            'in_stock': p['is_in_stock'],
            'url': p['permalink'],
            'image': p['images'][0]['src'] if p.get('images') else None,
        } for p in products]
    except Exception as e:
        return [{'source': 'usea', 'error': str(e)}]
```

### 4.2 Add USea to Source Checklist
Update UI:
```python
dbc.Checklist(
    id='proxy-source-checklist',
    options=[
        {'label': ' Black Lotus Sheet', 'value': 'black_lotus'},
        {'label': " Ron's Sheet", 'value': 'rons'},
        {'label': ' USea (A Game Card Shop)', 'value': 'usea'},  # NEW
    ],
    value=['black_lotus', 'rons', 'usea'],
    ...
)
```

### 4.3 Rate Limiting
Add simple rate limiter (1 request/second for USea):
```python
import time
_last_usea_request = 0

def search_usea_throttled(card_name: str) -> list:
    global _last_usea_request
    elapsed = time.time() - _last_usea_request
    if elapsed < 1.0:
        time.sleep(1.0 - elapsed)
    _last_usea_request = time.time()
    return search_usea(card_name)
```

---

## Phase 5: Unified Results Display

### 5.1 Result Card Component
Create visually clean cards showing:
- Thumbnail image (left)
- Card name (bold)
- Source badge (colored)
- Price (if available)
- Stock status (USea)
- Link to source

```python
def create_result_card(result):
    """Create a visual card for a search result."""
    source_colors = {
        'black_lotus': '#E63946',
        'rons': '#F4A261',
        'usea': '#2A9D8F',
    }

    return dbc.Card([
        dbc.CardBody([
            dbc.Row([
                # Image column
                dbc.Col([
                    html.Img(
                        src=result.get('image', '/assets/placeholder.png'),
                        style={'height': '60px', 'objectFit': 'contain'}
                    ) if result.get('image') else html.Div()
                ], width=2),
                # Info column
                dbc.Col([
                    html.Strong(result['name'][:50]),
                    html.Br(),
                    dbc.Badge(
                        result['source'].replace('_', ' ').title(),
                        color='primary',
                        style={'backgroundColor': source_colors.get(result['source'])}
                    ),
                    html.Span(f" ${result['price']}" if result.get('price') else "", className="ms-2"),
                ], width=8),
                # Action column
                dbc.Col([
                    html.A("View →", href=result.get('url', '#'), target='_blank', className="btn btn-sm btn-outline-light")
                    if result.get('url') else html.Span()
                ], width=2, className="text-end"),
            ], align="center")
        ], className="py-2")
    ], className="mb-2", style={'backgroundColor': '#16213e'})
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `app/dashboard.py` | Add caching, USea integration, improved matching, result cards |
| `app/proxy_cache.py` | New file for cache infrastructure |

---

## Verification Plan

1. **Cache Test**:
   - Search for a card → note response time
   - Search again immediately → should be faster (cache hit)
   - Wait 5+ minutes → search again → should re-fetch

2. **Matching Test**:
   - Search "Cavern of Souls" → should match "Cavern of Souls #410a Neonink foil"
   - Search "Cavern" alone → should NOT match (not high precision)

3. **USea Integration Test**:
   - Search "Black Lotus" → should return USea results with prices/images
   - Check rate limiting works (no 429 errors)

4. **Visual Test**:
   - Results should show image thumbnails where available
   - Cards should be visually organized with source badges
   - Links should open in new tab

---

## Implementation Order

1. ✅ Phase 1: Caching (foundational)
2. ✅ Phase 2: Matching improvements (quick win)
3. ✅ Phase 4: USea API integration (high value, now easy!)
4. ✅ Phase 5: Visual results display
5. ✅ Phase 3: Image thumbnails (depends on sheet structure)

**Estimated time**: 1-2 hours for core functionality
