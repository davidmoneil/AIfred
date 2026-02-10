---
name: deck-ops
model: sonnet
description: Create slide deck presentations
version: 1.2.0
category: document
tags: [presentation, slides, deck, pptx, pdf, design, visual, teaching]
token_cost: ~18000
dependencies: [Bash, Write, Read, Edit, WebSearch, WebFetch, Task]
overlaps_with: [pptx, pdf, doc-ops]
complements: [research-ops, web-fetch]
---

## Selection Guidance

**Use this skill when**:
- Creating a complete slide deck from topic, sources, or content
- User cares about visual quality, narrative arc, and audience engagement
- The presentation serves teaching, persuasion, or discussion facilitation
- Multiple source materials need synthesis into a coherent visual story

**Do NOT use when**:
- Simple file format conversion (use doc-ops)
- Editing an existing .pptx file (use pptx skill directly)
- Creating a quick data-driven chart deck (use xlsx + pptx)
- User just wants bullet points in slides (use pptx skill directly)

**Delegates to**: pptx (PPTX format), pdf (PDF format), research-ops (deep research)

---

# Deck-Ops: End-to-End Presentation Creation

## Philosophy

A great presentation is designed **backward from the audience**, not forward from the content.

Three principles govern every decision:
1. **Audience-first**: The audience's needs, context, and engagement style dictate design language
2. **Narrative arc**: Every slide earns its place in a story — no slide exists for information alone
3. **Visual communication**: Diagrams, motifs, and layout do the heavy lifting — text supports, not carries

## The 7-Phase Pipeline

```
Phase 1: DISCOVER   — Research sources, extract key content
Phase 2: ENVISION   — Define audience, purpose, core metaphor, narrative arc
Phase 3: ARCHITECT  — Design slide structure, flow, and information hierarchy
Phase 4: DESIGN     — Establish visual system (colors, fonts, motifs, layouts)
Phase 5: GENERATE   — Create the slide deck in target format
Phase 6: REVIEW     — Visual audit, font check, narrative verification
Phase 7: REFINE     — Iterative improvement cycles (Wiggum Loop)
```

---

## Phase 1: DISCOVER (Content Research)

### Goal
Find, evaluate, and extract the raw material that will become slide content.

### Process
1. **Source identification**: What primary sources does the user reference or want?
2. **Source retrieval**: Use WebSearch/WebFetch to find full text of talks, articles, papers
3. **Source evaluation**: For each source, extract:
   - Core thesis (1 sentence)
   - Key quotes (verbatim, with attribution)
   - Supporting data/examples
   - Metaphors or analogies already present
4. **Cross-source synthesis**: What themes connect the sources? Where do they reinforce each other?
5. **Gap analysis**: What visual or narrative elements are needed beyond the source text?

### Source Quality Checklist
- [ ] Full text available (not just summaries)
- [ ] Key quotes identified with exact wording
- [ ] Attribution details correct (name, title, context)
- [ ] Cross-source connections mapped
- [ ] Visual anchor candidates identified (photos, diagrams, data)

---

## Phase 2: ENVISION (Purpose & Audience)

### Goal
Define the presentation's reason for existing and who it serves.

### The Five Questions
Answer ALL of these before touching slide design:

1. **WHO is the audience?**
   - Age range, background, expertise level
   - What do they already know about this topic?
   - What's their attention span and engagement style?

2. **WHY does this presentation exist?**
   - Inform? Persuade? Facilitate discussion? Inspire action?
   - What should the audience DO after seeing this?

3. **WHAT is the core metaphor or narrative thread?**
   - Every great presentation has ONE central analogy or story
   - Everything else supports, illustrates, or extends this thread
   - The metaphor should be grounded in source text, not imposed

4. **WHERE will this be presented?**
   - Projected screen? Laptop? Printed handout?
   - This determines font sizes, layout ratios, color contrast

5. **HOW should the audience engage?**
   - Passive listening → dense visual slides
   - Active discussion → sparse slides with prominent questions
   - Workshop/activity → instructional slides with clear steps

### Presentation Archetypes

| Archetype | Structure | Visual Style |
|---|---|---|
| **Teaching/Discussion** | Hook → Foundation → Core content → Application → Call to action | Open layouts, prominent questions, warm tones |
| **Persuasive/Pitch** | Problem → Vision → Evidence → Ask | Bold typography, data visualization, high contrast |
| **Technical/Tutorial** | Concept → Diagram → Example → Practice | Clean layouts, native diagrams, monospace for code |
| **Narrative/Inspirational** | Story → Tension → Insight → Resolution | Full-bleed images, cinematic typography, minimal text |

---

## Phase 3: ARCHITECT (Slide Structure)

### Goal
Define the narrative flow — what slides exist, in what order, and what each one does.

### The Slide Inventory Method
For each slide, define:
- **Number and title**
- **Type**: Title / Content / Transition / Discussion / Visual / Conclusion
- **Purpose**: What does this slide accomplish that no other slide does?
- **Content**: Key text, quotes, data, or diagrams
- **Engagement**: How does this slide involve the audience?

### Structural Rules
1. **The 3-minute rule**: No slide should need more than 3 minutes. If it does, split it.
2. **Front-load engagement**: Discussion questions or visual hooks within the first 3 slides
3. **Transition slides**: Required between major sections (signal the shift, don't just jump)
4. **Bookend design**: Opening and closing slides should echo each other
5. **Discussion placement**: Questions on every content slide, not just at the end
6. **Content density**: Maximum 3 bullets per slide. If you need more, split or use a diagram.

### Narrative Arc Template
```
1. HOOK          — Grab attention (image, question, bold claim)
2. PREVIEW       — Foreshadow where you're going (optional)
3-4. FOUNDATION  — Establish the concept/metaphor foundation
5-N. DEVELOPMENT — Build the argument through alternating content + engagement
N+1. TRANSITION  — Bridge between major sections
N+2-M. APPLICATION — Apply the concept to the audience's context
M+1. CONCLUSION  — Synthesize, call to action, echo the hook
```

---

## Phase 4: DESIGN (Visual System)

### Goal
Establish the visual language before generating a single slide.

### Design System Checklist

**Color Palette** (3-5 colors):
- Primary background (dark or light)
- Header/accent color
- Text color (high contrast with background)
- Highlight/callout color
- Secondary accent (optional)

Match palette to content mood:
- **Sacred/spiritual**: Deep blues, purples, golds, warm whites
- **Technical/analytical**: Navy, slate, silver, accent red or green
- **Energetic/motivational**: Bold primaries, high contrast
- **Warm/personal**: Earth tones, warm grays, amber accents

**Typography Hierarchy** (projection-optimized):
| Element | Minimum Size | Recommended |
|---|---|---|
| Slide title | 28pt | 30-36pt |
| Section header | 20pt | 22-24pt |
| Body text | 16pt | 18-20pt |
| Bullet points | 16pt | 18pt |
| Quotes | 14pt | 15-16pt |
| Discussion questions | 14pt | 16pt bold italic |
| Captions/annotations | 12pt | 13-14pt |
| Slide numbers | 10pt | 11pt |

**CRITICAL**: These are PROJECTION minimums. For reading on a laptop, reduce by ~30%.

**Visual Motif**:
- Choose ONE recurring visual element that reinforces the core metaphor
- Apply it to 60-80% of slides (not every slide — leave breathing room)
- Use it decoratively on some slides, informationally on others
- Examples: sine wave, connecting line, geometric shape, color gradient

**Layout Patterns**:
- **Full-bleed**: Image covers entire slide, text overlaid with semi-transparent backing
- **Two-column**: Content left, visual right (or reverse)
- **Header + content**: Colored header bar, white content area below
- **Quote slide**: Centered quote with attribution, minimal decoration
- **Discussion slide**: Content top, prominent discussion box bottom

### Discussion Box Design
Discussion boxes should be:
- **Visually distinct** from other content (different background color, border)
- **Positioned prominently** (lower third of slide, full width)
- **Questions that are personal and open-ended**:
  - BAD: "What is the definition of X?"
  - BAD: "Do you agree with Y?" (yes/no)
  - GOOD: "When have you experienced X in your own life?"
  - GOOD: "Which of these resonates most with you? Why?"

---

## Phase 5: GENERATE (Create the Deck)

### Format Selection

| Format | Tool | Best For | Trade-offs |
|---|---|---|---|
| **PPTX** | python-pptx | Editable, portable, universal | Less precise layout control |
| **PDF** | ReportLab | Pixel-perfect, native diagrams | Not editable by presenter |
| **Google Slides** | Google Slides API | Collaborative, cloud-native | Requires API credentials |

### PPTX Generation (python-pptx)

**Setup pattern**:
```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
import math

prs = Presentation()
prs.slide_width = Inches(13.333)   # 16:9 widescreen
prs.slide_height = Inches(7.5)
BLANK_LAYOUT = prs.slide_layouts[6]  # blank layout
```

**Key patterns**:
- Use blank layouts and position everything manually for full control
- Add shapes with `slide.shapes.add_shape()` for backgrounds, boxes, accents
- Add text with `slide.shapes.add_textbox()` for all text content
- Add images with `slide.shapes.add_picture()` for photos/diagrams
- Draw lines/shapes for decorative elements (accent lines, borders)
- Set paragraph formatting: `paragraph.font.size`, `paragraph.alignment`, `paragraph.space_before`

**CRITICAL: Multi-line text in python-pptx**:
```python
# WRONG — \n creates a literal newline character, breaks rendering
txBox = slide.shapes.add_textbox(left, top, width, height)
txBox.text_frame.paragraphs[0].text = "Line 1\nLine 2"  # BAD

# RIGHT — use add_paragraph() for each line
tf = txBox.text_frame
tf.word_wrap = True
p1 = tf.paragraphs[0]
p1.text = "Line 1"
p1.font.size = Pt(18)
p2 = tf.add_paragraph()
p2.text = "Line 2"
p2.font.size = Pt(18)
```

**CRITICAL: Zone-Based Layout Model** (16:9 = 13.333" x 7.5"):

Every slide must respect a **zone grid** — content must stay within its assigned zone to prevent collisions.

```
Zone Model (13.333" x 7.5"):
┌─────────────────────────────────────────┐
│ HEADER ZONE  y: 0 → 1.2"               │  Header bar, title, accent lines
├───────────────────────┬─────────────────┤
│ LEFT CONTENT          │ RIGHT CONTENT   │  Main content area
│ x: 0.5" → 8.0"       │ x: 8.5" → 12.8"│  7.5" + 4.3" with 0.5" gutter
│ y: 1.3" → 5.8"       │ y: 1.3" → 5.8"  │
├───────────────────────┴─────────────────┤
│ DISCUSSION ZONE  y: 5.9" → 7.0"        │  Discussion box, full-width
├─────────────────────────────────────────┤
│ FOOTER ZONE  y: 7.1" → 7.5"            │  Footer bar, slide number
└─────────────────────────────────────────┘
```

**Width budget rules**:
- **Full-width text**: max 11.8" (x: 0.5" to 12.3")
- **Left column** (when right has sidebar/image): max **7.0"** (x: 0.5" to 7.5")
- **Right sidebar**: max **4.0"** (x: 8.5" to 12.5")
- **Gutter between columns**: minimum 0.5" (left_end + 0.5" <= right_start)
- **Outer margins**: 0.5" minimum all sides
- **FORMULA**: `available_width = column_right_edge - column_left_edge - inner_margin`
- **NEVER** let a text box extend past its column boundary — even if text wraps, the box itself must stay within the zone

**Vertical stack protocol** — track cumulative y-position to prevent overlap:
```python
# Track the bottom edge of each element
y_cursor = Inches(1.3)  # Start below header

# Place element 1
add_textbox(slide, x, y_cursor, w, Inches(0.5), "Title text")
y_cursor += Inches(0.5) + Inches(0.1)  # height + gap

# Place element 2 — uses y_cursor, guaranteed no overlap
add_bullet_text(slide, x, y_cursor, w, Inches(1.5), bullets)
y_cursor += Inches(1.5) + Inches(0.1)

# Verify: if y_cursor > DISCUSSION_ZONE_TOP (5.9"), content overflows
assert y_cursor <= Inches(5.9), f"Content overflow at y={y_cursor}"
```

**Quote box width constraint** — quotes MUST respect their column:
```python
# If in left column (with right sidebar), constrain to 7.5"
quote_width = Inches(7.5) if has_right_sidebar else Inches(11.5)
add_quote_box(slide, text, attrib, MARGIN, y, quote_width)
```

**Speaker notes** (add to every slide for presenter guidance):
```python
notes_slide = slide.notes_slide
tf = notes_slide.notes_text_frame
tf.text = "Presenter notes: key talking points for this slide..."
```

**Native diagram drawing** (python-pptx shapes):
```python
# Add a colored rectangle (background bar, accent box)
shape = slide.shapes.add_shape(
    MSO_SHAPE.RECTANGLE, left, top, width, height)
shape.fill.solid()
shape.fill.fore_color.rgb = RGBColor(0x1B, 0x2A, 0x4A)
shape.line.fill.background()  # no border
```

**For complex native diagrams** (curves, parametric shapes):
- Generate diagram as PNG using matplotlib or PIL at **300+ DPI with antialiasing**
- Use `Image.new("RGBA", (w, h))` at 2x resolution, then embed
- Prefer PIL `ImageDraw` with `width=3` for visible strokes
- For highest quality: generate via ReportLab canvas → PDF → PNG → embed in PPTX
- Use web-safe Unicode characters only (avoid →, use \u2192 with Calibri/Arial)

### Recommended Helper Functions (python-pptx)

Define these at the top of every PPTX generation script to enforce layout safety:

```python
# Layout zone constants
SLIDE_W = Inches(13.333)
SLIDE_H = Inches(7.5)
MARGIN = Inches(0.5)
HEADER_BOTTOM = Inches(1.2)
FOOTER_TOP = SLIDE_H - Inches(0.4)
DISCUSSION_TOP = Inches(5.9)
LEFT_COL_MAX = Inches(7.5)    # right edge when sidebar exists
RIGHT_COL_START = Inches(8.5)  # left edge of right sidebar
GUTTER = Inches(0.5)

def safe_width(x_start, has_right_sidebar=False):
    """Calculate maximum width from x_start without collision."""
    if has_right_sidebar:
        return RIGHT_COL_START - GUTTER - x_start
    return SLIDE_W - MARGIN - x_start

def add_textbox(slide, left, top, width, height, text, **kwargs):
    """Add text box with automatic width clamping."""
    max_w = SLIDE_W - MARGIN - left
    width = min(width, max_w)  # Never exceed slide boundary
    txBox = slide.shapes.add_textbox(left, top, width, height)
    # ... font/color/alignment setup
    return txBox

def y_after(top, height, gap=Inches(0.1)):
    """Calculate next y position after an element (vertical stack)."""
    return top + height + gap
```

### python-pptx Pitfalls

| Pitfall | Cause | Fix |
|---|---|---|
| Text shows as boxes | `\n` in text string | Use `add_paragraph()` for each line |
| Unicode arrows as boxes | Font doesn't support glyph | Use Calibri (supports most Unicode) or substitute with text ("->") |
| Background not visible | Fill type not set | Call `bg.fill.solid()` then `bg.fill.fore_color.rgb = color` |
| Text clipped at edge | Width exceeds available space | Calculate available width from slide width minus margins |
| Image stretched | Aspect ratio not preserved | Calculate target dimensions preserving original aspect ratio |
| Slide layout conflicts | Non-blank layout has placeholders | Always use `prs.slide_layouts[6]` (blank) for full control |

### PDF Generation (ReportLab)

Delegate to `skills/pdf/SKILL.md` for ReportLab-specific patterns.

Key advantage: Canvas API gives direct path drawing for native diagrams:
```python
# Sine wave via canvas path
p = c.beginPath()
for i in range(steps):
    x = start_x + (i/steps) * length
    y = center_y + amplitude * math.sin(2 * math.pi * periods * i / steps)
    if i == 0: p.moveTo(x, y)
    else: p.lineTo(x, y)
c.drawPath(p, stroke=1, fill=0)
```

### Slide-to-Image Conversion (for review)

**Strategy priority** (use first available):

1. **LibreOffice** (best quality):
```bash
soffice --headless --convert-to pdf presentation.pptx --outdir /output/dir/
python3 -c "
import fitz
doc = fitz.open('presentation.pdf')
for i, page in enumerate(doc):
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
    pix.save(f'slide_{i+1:02d}.png')
"
```

2. **Existing pptx skill thumbnail** (if available):
```bash
python skills/pptx/scripts/thumbnail.py presentation.pptx slides --cols 4
```

3. **PIL-based fallback renderer** (no external deps, approximate):
```python
# Read PPTX shapes and render to PIL Image
# Handles: background fills, shape rectangles, embedded images, text
# Limitations: no rounded corners, no gradients, basic text alignment
# See deck_draft1/render_pptx.py for reference implementation
```
The PIL renderer gives ~70% visual fidelity — enough to verify layout, content placement, and text sizing, but NOT color accuracy or decorative elements.

4. **PDF → images** (for PDF-format decks):
```python
import fitz
doc = fitz.open('presentation.pdf')
for i, page in enumerate(doc):
    pix = page.get_pixmap(matrix=fitz.Matrix(150/72, 150/72))
    pix.save(f'slide_{i+1:02d}.png')
```

**When no renderer is available**: Generate a parallel "preview PDF" using ReportLab with the same content/layout as the PPTX. This provides pixel-perfect preview while the PPTX serves as the deliverable.

---

## Phase 6: REVIEW (Visual Audit)

### Goal
Systematically evaluate every slide against quality criteria.

### The 5-Category Audit

For each slide, assess:

1. **STRUCTURAL**: Does this slide earn its place? Is it in the right position?
2. **CONTENT**: Is the text accurate, concise, and at the right density?
3. **AESTHETIC**: Do colors, fonts, and layout create visual harmony?
4. **FLOW**: Does this slide connect smoothly to its neighbors?
5. **ENGAGEMENT**: Does this slide involve the audience?

### Layout Collision Checklist (run BEFORE quality standards)

For every slide with multi-column content (sidebar, image + text, split layout):
- [ ] **Left column right edge + 0.5" gutter < right column left edge** (no horizontal overlap)
- [ ] **Text box width does not exceed column boundary** (even with word wrap)
- [ ] **Quote box width constrained to its column** (not full-width when sidebar exists)
- [ ] **Discussion box y-position > all content above it** (no vertical overlap)
- [ ] **Attribution text y-position > quote box bottom** (quote and attribution don't collide)
- [ ] **Image placement does not extend into text zone** (verify image right edge < text left edge, or image bottom edge < text top edge)
- [ ] **Bullet text terminates before sidebar zone begins** (if right sidebar at x=8.5", bullets must end before x=8.0")

**Common collision patterns to check**:
```
BAD:  Bullet width = Inches(7), sidebar at x = Inches(9)
      → Bullet extends 0.5"+7" = 7.5", sidebar at 9" — OK only if bullet LEFT starts at 0.5"
      → But if bullet LEFT is at 0.7" and extends 7", it reaches 7.7" — still OK
      → BUT if bullet text wraps and PIL measures wider, it visually clips

GOOD: Bullet width = min(Inches(7), sidebar_x - bullet_x - Inches(0.5))
      → This guarantees the gutter is respected regardless of starting position
```

### Minimum Quality Standards

- [ ] All body text >= 16pt (projected) or >= 12pt (laptop)
- [ ] All discussion questions are personal and open-ended
- [ ] No slide has more than 3 bullet points
- [ ] Every section transition has a bridging element
- [ ] Visual motif appears on 60-80% of slides
- [ ] Em-dashes (U+2014) used for all attributions (never --)
- [ ] Color contrast ratio >= 4.5:1 for all text
- [ ] Slide numbers present on all slides
- [ ] Narrative arc: hook → development → conclusion is clear
- [ ] No dead space (empty areas > 2 inches with no purpose)

---

## Phase 7: REFINE (Iterative Improvement)

### The Presentation Wiggum Loop

Adapted from the AC-02 Wiggum Loop for presentation-specific iteration:

```
For each cycle (recommend 3-5 cycles):
  1. RENDER   — Generate slides and convert to images
  2. REVIEW   — Visual audit against the 5 categories
  3. IDENTIFY — List specific issues with priority (S/C/A/F/E codes)
  4. FIX      — Apply changes targeting one category per cycle
  5. VERIFY   — Re-render and confirm fixes
  6. DOCUMENT — Log changes in cycle notes
```

### Category Rotation (recommended cycle order)
1. **Structure & Engagement** — slide order, discussion questions, audience hooks
2. **Visual System** — motifs, diagrams, image quality, layout consistency
3. **Typography & Density** — font sizes, text reduction, white space
4. **Narrative & Flow** — transitions, connecting statements, arc verification
5. **Final Audit** — composite review, resolution scorecard

### Dual-Set Approach
If the deck has distinct slide groups (e.g., technical vs. applied):
- Iterate each set separately — they may need different treatments
- Technical slides often need: simpler visuals, native diagrams, less text
- Applied/discussion slides often need: prominent questions, reduced density

---

## Quick Reference: Design Patterns

### Color Palettes by Mood

**Sacred/Devotional**: `#1B2A4A` (navy) / `#3A2A5A` (purple) / `#C8A84E` (gold) / `#F8F4FF` (lavender)
**Technical/Clean**: `#1A1A2E` (dark) / `#2C4A7C` (blue) / `#F4F6FA` (light) / `#E74C3C` (accent red)
**Warm/Inspirational**: `#5D1D2E` (burgundy) / `#C15937` (rust) / `#997929` (gold) / `#FAF7F2` (cream)
**Nature/Growth**: `#1E5128` (forest) / `#4E9F3D` (green) / `#F4F1DE` (cream) / `#E07A5F` (terracotta)

### Font Stacks (web-safe for PPTX)
- **Headers**: Arial Black, Impact, or Calibri Bold
- **Body**: Calibri, Arial, or Helvetica
- **Quotes**: Georgia Italic, Calibri Light Italic
- **Data/Code**: Courier New, Consolas

### Discussion Question Templates
```
Personal reflection:  "When have you experienced [concept] in your life?"
Resonance check:      "Which of these [items] resonates most with you? Why?"
Application:          "What is one [concept] you could [action] this week?"
Open exploration:     "What happens when [condition]?"
Comparative:          "How is [A] like [B] in your experience?"
```

---

## Dependencies

**Required** (presentation generation):
- python-pptx >= 1.0.0 (`pip install python-pptx`)
- Pillow (`pip install Pillow`)

**Optional** (enhanced features):
- ReportLab (`pip install reportlab`) — PDF generation, native diagrams
- PyMuPDF (`pip install pymupdf`) — PDF-to-image conversion
- matplotlib (`pip install matplotlib`) — Complex chart/diagram generation
- LibreOffice (`brew install --cask libreoffice`) — PPTX-to-PDF conversion

**For visual review**:
- PyMuPDF (fitz) for rendering slides as images
- Read tool for visual inspection of rendered PNGs
