---
name: doc-ops
version: 1.0.0
description: >
  Document format operations — Word, Excel, PDF, PowerPoint.
  Use when: document, docx, xlsx, pdf, pptx, spreadsheet, presentation, word, excel, powerpoint, slides, report.
absorbs: docx, xlsx, pdf, pptx
---

## Format Router

```
Document task?
├── Word (.docx) → Read skills/docx/SKILL.md
│   Create, edit, redline, extract text from Word documents
│   Tools: pandoc, docx-js (create), OOXML (edit), tracked changes
│
├── Excel (.xlsx) → Read skills/xlsx/SKILL.md
│   Spreadsheets with formulas, financial models, data analysis
│   Tools: openpyxl, pandas, recalc.py (LibreOffice)
│
├── PDF (.pdf) → Read skills/pdf/SKILL.md
│   Create, merge, split, extract, fill forms
│   Tools: pypdf, pdfplumber, reportlab, qpdf
│   Forms: Read skills/pdf/forms.md
│
├── PowerPoint (.pptx) → Read skills/pptx/SKILL.md
│   Create (html2pptx), edit (OOXML), template-based
│   Tools: pptxgenjs, html2pptx.js, inventory.py, replace.py
│
├── Convert between formats:
│   ├── Any → PDF: soffice --headless --convert-to pdf INPUT
│   ├── PDF → images: pdftoppm -jpeg -r 150 INPUT.pdf PREFIX
│   └── DOCX → markdown: pandoc INPUT.docx -o OUTPUT.md
│
└── Simple text output → Use Write tool (no skill needed)
```

## Common Patterns

- **OOXML unpack/pack**: `python ooxml/scripts/unpack.py FILE DIR` / `pack.py DIR FILE`
- **Text extraction**: `pandoc` (docx), `markitdown` (pptx), `pdfplumber` (pdf), `pandas` (xlsx)
- **Visual preview**: `soffice --headless --convert-to pdf` then `pdftoppm -jpeg`
- **Code style**: Concise, minimal prints, no verbose variable names

## Dependencies (shared)

LibreOffice (`soffice`), pandoc, poppler-utils (`pdftoppm`, `pdftotext`), defusedxml.
Format-specific deps listed in each sub-skill.
