# Upgrade History Entry

## {{ID}} - {{TITLE}}

**Applied**: {{TIMESTAMP}}
**Source**: {{SOURCE}}
**Status**: {{STATUS}}

---

## Summary

{{SUMMARY}}

---

## Changes Made

### Files Modified

{{FILES_MODIFIED}}

### Key Changes

{{KEY_CHANGES}}

---

## Verification

- Checkpoint tag: `pre-{{ID}}`
- Validation: {{VALIDATION_STATUS}}
- Errors: {{ERRORS}}

---

## Lessons Learned

{{LESSONS}}

---

## Rollback Info

If issues arise:
```bash
/upgrade rollback {{ID}}
```

Or manually:
```bash
git checkout pre-{{ID}} -- <files>
```

---

*Logged by Upgrade Skill v1.0*
