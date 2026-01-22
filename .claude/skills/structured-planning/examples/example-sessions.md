# Structured Planning - Example Sessions

These examples show how the planning workflow operates in practice.

---

## Example 1: New Design Mode

**User prompt**: "I want to build a habit tracking application"

### Session Flow

```
User: /plan "I want to build a habit tracking application"

Claude: Based on your request, I'm suggesting **New Design** mode.

This mode is best for: Building something new from scratch with full
specification coverage.

Is this the right approach?
> Yes, proceed with New Design ✓

───────────────────────────────────────────────────────────────────

Great! Let's plan your habit tracking application.

## Vision & Goals

**What specific problem are you trying to solve?**

User: People forget to do their daily habits and lose motivation when
they break their streaks. Most apps are too complicated.

Claude: I hear you on simplicity being important. Let me follow up:

**Who is the primary user of this?**

User: Anyone wanting to build better habits - probably skewing younger,
tech-comfortable, busy professionals.

**What does success look like for this project?**

User: Users actually stick with it for more than a week. High retention.
Simple enough that my mom could use it.

───────────────────────────────────────────────────────────────────
✓ Vision & Goals - captured
→ Scope & Features - current
○ Technical Considerations - next
○ Constraints - pending
○ Risks - pending
───────────────────────────────────────────────────────────────────

## Scope & Features

**What are the absolute must-have features for launch?**

User: Habit creation, daily check-in, streak counter. Maybe notifications
but I'm not sure about that.

Claude: You mentioned uncertainty about notifications. Let me dig deeper:

**What's your concern about notifications?**
- Technical complexity?
- User experience impact?
- Platform differences?

User: Mostly worried about being annoying. I want it optional and smart.

Claude: That's helpful context. I'll note notifications as "optional,
user-controlled" in MVP.

**What's explicitly out of scope for this version?**

User: Social features, habit suggestions, gamification beyond streaks.
Keep it focused.

───────────────────────────────────────────────────────────────────
✓ Vision & Goals - captured
✓ Scope & Features - captured
→ Technical Considerations - current
○ Constraints - pending
○ Risks - pending
───────────────────────────────────────────────────────────────────

## Technical Considerations

**Any technology preferences or constraints?**

User: I'm comfortable with React. Want it to work on mobile too.

Claude: For mobile support, I'm thinking React Native or a PWA approach.

**What existing systems does this need to work with?**

User: None really, standalone app. Maybe calendar sync later.

───────────────────────────────────────────────────────────────────
(Continues through Constraints and Risks...)
───────────────────────────────────────────────────────────────────

## Draft Specification Summary

**Project**: Habit Tracker
**Mode**: New Design

### Vision
A simple habit tracking app focused on daily check-ins and streak
maintenance for busy professionals who value simplicity over features.

### Scope
**MVP Features**:
- Habit creation (name, frequency, reminder time)
- Daily check-in interface
- Streak counter with visual feedback
- Optional, smart notifications

**Out of Scope**:
- Social features
- Habit suggestions/recommendations
- Gamification beyond streaks
- Analytics dashboard

### Technical Approach
- React (web) with potential React Native (mobile) later
- PWA for initial mobile support
- Local-first with optional cloud sync

Does this capture your intent? Any adjustments needed?

User: Looks good! Maybe add "simple analytics for the user" to phase 2.

Claude: Updated. Creating specification...

───────────────────────────────────────────────────────────────────

## Planning Complete

**Specification**: `.claude/planning/specs/2026-01-19-habit-tracker.md`
**Orchestration**: `.claude/orchestration/2026-01-19-habit-tracker.yaml`

### What's Next

Run these commands to execute your plan:
- `/orchestration:status` - See the task breakdown
- `/orchestration:resume` - Start working on tasks

### Planning Session Stats
- Questions asked: 12
- Depth escalations: 2 (notifications, mobile approach)
- Categories covered: 5/5
```

---

## Example 2: System Review Mode

**User prompt**: "Review my current voice system architecture"

### Session Flow

```
User: /plan:review "voice character system"

Claude: Starting System Review for the voice character system.

## Current State Assessment

**What system are we reviewing?**

User: The voice-character-system - it's a CLI tool that manages voice
characters for D&D narration using Chatterbox TTS.

**What's working well currently?**

User: Character creation is solid. The SQLite database works fine.
Voice generation quality is good.

**How long has this been in place?**

User: About 2 weeks. Still pretty new.

───────────────────────────────────────────────────────────────────
✓ Current State - captured
→ Pain Points - current
○ Desired State - next
○ Gap Analysis - pending
○ Prioritization - pending
───────────────────────────────────────────────────────────────────

## Pain Points

**What are the biggest pain points?**

User: The REST API is clunky. No web UI for non-technical users.
Voice library management is manual.

Claude: Multiple pain points across different areas. Let me explore:

**What's the technical debt situation?**

User: Not much yet - it's new. But the API routes are repetitive, could
use better error handling.

**What workarounds exist currently?**

User: Have to SSH into the server to run CLI commands. Copy voice files
manually between systems.

───────────────────────────────────────────────────────────────────
(Continues through Desired State, Gap Analysis, Prioritization...)
───────────────────────────────────────────────────────────────────

## Review Summary

### Findings

**Critical Issues**: None
**High Priority**:
- No web interface for voice management
- Manual voice library sync

**Medium Priority**:
- API error handling inconsistent
- No bulk operations for characters

**Low Priority**:
- Code duplication in routes

### Improvement Plan

**Phase 1: Quick Wins**
- Add web dashboard (character CRUD, voice generation)
- Improve API error responses

**Phase 2: Core Improvements**
- Voice library sync automation
- Bulk character operations

**Phase 3: Strategic**
- PostgreSQL sync for n8n integration

Ready to create the improvement orchestration?

User: Yes, let's do it.

───────────────────────────────────────────────────────────────────

## Review Complete

**Review Document**: `.claude/planning/reviews/2026-01-19-voice-system-review.md`
**Orchestration**: `.claude/orchestration/2026-01-19-voice-system-improvements.yaml`
```

---

## Example 3: Feature Planning Mode

**User prompt**: "Add dark mode to the dashboard"

### Session Flow

```
User: /plan:feature "dark mode toggle for the dashboard"

Claude: Starting Feature Planning for dark mode.

## Feature Scope

**What capability are you adding?**

User: A toggle that switches the dashboard between light and dark themes.
Should persist the preference.

**What problem does this solve for users?**

User: Eye strain during night use. Personal preference. Accessibility.

**What's explicitly NOT part of this feature?**

User: No automatic switching based on time. No system preference detection
for now. Just manual toggle.

───────────────────────────────────────────────────────────────────
✓ Feature Scope - captured
→ Integration - current
○ Acceptance - next
───────────────────────────────────────────────────────────────────

## Integration

**What existing code does this touch?**

User: The main layout component, probably need CSS variables, and
localStorage for persistence.

**Any breaking changes expected?**

User: Shouldn't be - adding alongside existing styles.

───────────────────────────────────────────────────────────────────
✓ Feature Scope - captured
✓ Integration - captured
→ Acceptance - current
───────────────────────────────────────────────────────────────────

## Acceptance Criteria

**How will you know this feature is complete?**

User: Toggle visible in header. Clicking switches theme instantly.
Preference persists across sessions.

───────────────────────────────────────────────────────────────────

## Feature Summary

**Feature**: Dark Mode Toggle
**Project**: Dashboard

### Scope
- Manual toggle in header
- Light/dark theme switching
- localStorage persistence
- NOT: auto-switching, system detection

### Integration
- Layout component modification
- CSS variable system for theming
- localStorage for persistence

### Acceptance Criteria
- [ ] Toggle visible in header
- [ ] Theme switches instantly on click
- [ ] Preference persists across browser sessions
- [ ] Both themes maintain contrast accessibility

Ready to generate orchestration?

User: Yes

───────────────────────────────────────────────────────────────────

## Feature Planning Complete

**Specification**: `.claude/planning/specs/2026-01-19-dark-mode-toggle.md`
**Orchestration**: `.claude/orchestration/2026-01-19-dark-mode-toggle.yaml`

### Tasks Generated
1. Create CSS variable system for colors
2. Create ThemeProvider context
3. Create toggle component
4. Add localStorage persistence
5. Update layout to use theme
6. Test both themes
```

---

## Dynamic Depth Example

This shows how depth escalates based on complexity signals:

```
Claude: **Any technology preferences or constraints?**

User: We need to integrate with our existing enterprise SSO system,
and there might be some compliance requirements I'm not sure about.

Claude: [Detects: integration requirement + uncertainty + enterprise context]

I'd like to explore the integration and compliance aspects more:

**What SSO system are you integrating with?**
- SAML-based (Okta, Azure AD)?
- OAuth/OIDC?
- Custom enterprise solution?

User: Azure AD, SAML-based.

Claude: **What compliance requirements might apply?**
- Are you handling personal data (GDPR)?
- Healthcare data (HIPAA)?
- Financial data (SOX, PCI)?
- Or is this internal tooling?

User: It's internal but we do touch some customer data, so probably GDPR.

Claude: Got it. I'll include GDPR considerations in the technical approach
and add a security review task to the orchestration.
```

The depth escalated from base technical questions to extended security/compliance questions because the user's answer contained:
- Integration with external system (Azure AD)
- Uncertainty ("might be some compliance requirements I'm not sure about")
- Enterprise context signals

---

## Skip Depth Example

```
Claude: **What's explicitly out of scope for this version?**

User: Social features, recommendations, gamification. That's enough
detail on scope - let's move on.

Claude: [User requested to move on]

Got it, moving to Technical Considerations...
```

When the user explicitly indicates they want to move forward, the system respects that and skips remaining questions in the category.
