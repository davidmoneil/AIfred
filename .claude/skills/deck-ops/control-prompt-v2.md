# Control Prompt v2

## Changes from v1
- Added explicit request for "clean, readable diagrams" (addresses G3 diagram quality)
- Specified "polished visual design with colored backgrounds, accent lines" (addresses rendering expectations)
- Added "with speaker notes" (addresses G6)
- Mentioned "make sure text doesn't overlap or get clipped" (addresses G5 width budgeting)
- Added "use proper paragraph breaks, not forced newlines" (addresses G1)

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
- Make sure text doesn't overlap or get clipped — budget the 16:9 width carefully
- Include speaker notes with talking points for each slide
- Font sizes readable from the back of a room (18pt+ for body, 28pt+ for titles)

Build this with physics slides in the first half and spiritual application in the second, with a clear transition slide bridging them.

---

## Expected Improvements over v1
- Multi-line text handled via add_paragraph() not \n
- Speaker notes on every slide
- Diagrams at 300 DPI with antialiasing
- Explicit width budgeting preventing text clipping
- Colored backgrounds and accent lines properly applied
