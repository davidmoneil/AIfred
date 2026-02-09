# Control Prompt v3

## Changes from v2
- Added explicit layout constraint: "no text should overlap with sidebars or images"
- Specified column layout model: "left column for text, right column for sidebars/images"
- Added "use a y-cursor to stack elements vertically without overlap"
- Added "constrain quote boxes to their column width"
- Emphasized "use helper functions that enforce safe widths"
- Added "test every two-column slide for collision before saving"

## The Prompt

---

I'm teaching Elder's Quorum this Sunday and I want to create something memorable. My quorum is men ranging from their 30s to 70s with all different professional backgrounds — engineers, teachers, retirees, tradesmen.

I want to use the physics of periodic motion as a metaphor for covenant living and spiritual renewal. The physics concepts — simple harmonic motion, oscillation, restoring forces, damped and driven systems — map beautifully onto repentance, covenants, and grace. I'm drawing from three General Conference talks:

- Elder Patrick Kearon: "Jesus Christ and Your New Beginning"
- Elder Michael Cziesla: "Simplicity in Christ"
- Elder Kelly R. Johnson: "Be Reconciled to God"

Lindsey Vonn's skiing makes a great visual anchor — her biomechanics literally demonstrate periodic motion, and crashes show what happens when rhythm fails.

Key requirements:
- This is a DISCUSSION, not a lecture. Every content slide needs an open-ended, personal discussion question
- 12-15 slides in PowerPoint format (.pptx)
- Polished visual design: dark blue/gold for physics, purple/lavender for spiritual, colored header bars, accent lines, visual motifs
- Clean, high-resolution diagrams for physics concepts — spring-mass system, annotated sine wave, skier oscillation path, slalom gates
- A damped-vs-driven oscillation comparison diagram for the grace/covenant slide
- Include speaker notes with talking points for each slide
- Font sizes readable from the back of a room (18pt+ for body, 28pt+ for titles)

Layout rules — these are critical:
- Use a strict two-column layout model: left column for text (max 7.5"), right column for sidebars/images (starting at 8.5"). Leave a 0.5" gutter between them.
- No text box should ever extend past its column boundary — even if the text wraps, the box must stay within the zone
- Use a y-cursor to stack elements vertically, always calculating the next element's position from the previous element's bottom edge plus a gap — never hardcode overlapping positions
- Constrain quote boxes to their column width (not full slide width when a sidebar exists)
- Discussion boxes go in the discussion zone (below y=5.9") at full width
- Before saving, mentally verify every two-column slide: does the left content's right edge stay at least 0.5" away from the right content's left edge?

Build this with physics slides in the first half and spiritual application in the second, with a clear transition slide bridging them.

---

## Expected Improvements over v2
- Zone-based layout prevents text/sidebar collisions on slides 12, 14
- y-cursor approach prevents vertical overlap between quotes and discussion boxes
- Column-width constraints prevent quote text running off right edge
- Explicit collision verification step catches remaining issues before save
