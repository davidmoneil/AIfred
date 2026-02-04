#!/usr/bin/env node
/**
 * JICM Continuation Verifier Hook
 *
 * Event: UserPromptSubmit
 *
 * Purpose: Ensures continuation context is properly injected after a JICM-triggered
 * /clear. This hook fires on user prompt submission and checks if we're in a JICM
 * continuation state that needs reinforcement.
 *
 * Signal Files Checked:
 *   - .continuation-injected.signal: session-start.sh set this
 *   - .clear-sent.signal: watcher set this when /clear was sent
 *   - .jicm-complete.signal: full cycle completed
 *
 * If a clear was sent but no jicm-complete signal exists, this hook adds
 * reinforcement context to ensure Jarvis continues working.
 *
 * Version: 4.0.0 (JICM v4 Cascade Resume)
 */

const fs = require('fs');
const path = require('path');

// Read stdin
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
    try {
        const data = JSON.parse(input);
        const result = verifyJicmContinuation(data);
        console.log(JSON.stringify(result, null, 2));
    } catch (error) {
        // On error, return success with no additional context
        console.log(JSON.stringify({
            proceed: true,
            hookSpecificOutput: {
                hookEventName: "UserPromptSubmit",
                error: error.message
            }
        }));
    }
});

function verifyJicmContinuation(data) {
    const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const contextDir = path.join(projectDir, '.claude', 'context');

    // Check signal files
    const clearSentFile = path.join(contextDir, '.clear-sent.signal');
    const continuationInjectedFile = path.join(contextDir, '.continuation-injected.signal');
    const jicmCompleteFile = path.join(contextDir, '.jicm-complete.signal');

    // If no clear was sent, nothing to do
    if (!fs.existsSync(clearSentFile)) {
        return {
            proceed: true,
            hookSpecificOutput: {
                hookEventName: "UserPromptSubmit",
                jicmState: "normal"
            }
        };
    }

    // If JICM cycle is complete, clean up and return
    if (fs.existsSync(jicmCompleteFile)) {
        // Clean up signal files
        try {
            fs.unlinkSync(clearSentFile);
            fs.unlinkSync(continuationInjectedFile);
            fs.unlinkSync(jicmCompleteFile);
        } catch (e) {
            // Ignore cleanup errors
        }

        return {
            proceed: true,
            hookSpecificOutput: {
                hookEventName: "UserPromptSubmit",
                jicmState: "cycle_complete",
                cleanedUp: true
            }
        };
    }

    // Clear was sent but cycle not complete - check if continuation was injected
    if (!fs.existsSync(continuationInjectedFile)) {
        // Continuation wasn't injected - this is a problem
        // Add reinforcement context
        return {
            proceed: true,
            hookSpecificOutput: {
                hookEventName: "UserPromptSubmit",
                jicmState: "reinforcing",
                additionalContext: `JICM CONTINUATION REINFORCEMENT

Your context was recently optimized. If you haven't already:
1. Read .claude/context/.compressed-context-ready.md (if exists)
2. Read .claude/context/.in-progress-ready.md (if exists)
3. Read .claude/context/session-state.md for current work status
4. Continue the task that was in progress

Do not greet or ask for instructions - continue working.`
            }
        };
    }

    // Check if continuation was recently injected (within last 60 seconds)
    try {
        const continuationTime = fs.readFileSync(continuationInjectedFile, 'utf8').trim();
        const injectedDate = new Date(continuationTime);
        const now = new Date();
        const elapsedSeconds = (now - injectedDate) / 1000;

        if (elapsedSeconds < 60) {
            // Recently injected, add gentle reinforcement
            return {
                proceed: true,
                hookSpecificOutput: {
                    hookEventName: "UserPromptSubmit",
                    jicmState: "continuation_active",
                    elapsedSeconds: Math.round(elapsedSeconds),
                    additionalContext: "JICM: Continue with the task from your preserved context."
                }
            };
        }
    } catch (e) {
        // Can't read timestamp, proceed normally
    }

    // Continuation was injected more than 60s ago - assume it worked
    // Mark cycle complete
    try {
        fs.writeFileSync(jicmCompleteFile, new Date().toISOString());
    } catch (e) {
        // Ignore
    }

    return {
        proceed: true,
        hookSpecificOutput: {
            hookEventName: "UserPromptSubmit",
            jicmState: "marked_complete"
        }
    };
}
