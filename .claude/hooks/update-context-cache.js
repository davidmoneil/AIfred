#!/usr/bin/env node
/**
 * Post-turn hook to update context category cache
 * Runs after each assistant response to keep statusline data fresh
 *
 * This hook reads the session transcript and calculates categorical breakdown
 * based on message types, avoiding the need for manual /context runs.
 */

const fs = require('fs');
const path = require('path');

const CACHE_FILE = path.join(process.env.HOME, '.claude/logs/context-categories.json');
const LOG_FILE = path.join(process.env.HOME, '.claude/logs/context-hook.log');

function log(msg) {
    const timestamp = new Date().toISOString();
    fs.appendFileSync(LOG_FILE, `[${timestamp}] ${msg}\n`);
}

function readInput() {
    return new Promise((resolve) => {
        let data = '';
        process.stdin.setEncoding('utf8');
        process.stdin.on('readable', () => {
            let chunk;
            while (chunk = process.stdin.read()) {
                data += chunk;
            }
        });
        process.stdin.on('end', () => {
            try {
                resolve(JSON.parse(data));
            } catch (e) {
                resolve({});
            }
        });
    });
}

async function main() {
    try {
        const input = await readInput();

        // Get transcript path - try multiple sources
        let transcriptPath = input.session_transcript_path ||
                            input.transcript_path ||
                            process.env.CLAUDE_TRANSCRIPT_PATH;

        // Fallback: read from statusline JSON which has the path
        if (!transcriptPath || !fs.existsSync(transcriptPath)) {
            const statuslineFile = path.join(process.env.HOME, '.claude/logs/statusline-input.json');
            if (fs.existsSync(statuslineFile)) {
                try {
                    const slData = JSON.parse(fs.readFileSync(statuslineFile, 'utf8'));
                    transcriptPath = slData.transcript_path;
                } catch (e) {
                    log('Could not read transcript path from statusline JSON');
                }
            }
        }

        if (!transcriptPath || !fs.existsSync(transcriptPath)) {
            log('No transcript path available');
            console.log(JSON.stringify({ proceed: true }));
            return;
        }

        // Read statusline JSON for actual token counts
        const statuslineFile = path.join(process.env.HOME, '.claude/logs/statusline-input.json');
        let statuslineData = {};
        if (fs.existsSync(statuslineFile)) {
            try {
                statuslineData = JSON.parse(fs.readFileSync(statuslineFile, 'utf8'));
            } catch (e) {
                log('Could not read statusline JSON');
            }
        }

        // Get actual token usage from statusline
        const contextWindow = statuslineData.context_window || {};
        const currentUsage = contextWindow.current_usage || {};
        const ctxSize = contextWindow.context_window_size || 200000;

        const totalUsed = (currentUsage.input_tokens || 0) +
                         (currentUsage.cache_creation_input_tokens || 0) +
                         (currentUsage.cache_read_input_tokens || 0);

        // Read transcript to count messages and estimate breakdown
        const transcript = fs.readFileSync(transcriptPath, 'utf8');
        const lines = transcript.trim().split('\n');

        let userMessages = 0;
        let assistantMessages = 0;
        let toolUses = 0;
        let totalMessageChars = 0;

        for (const line of lines) {
            try {
                const entry = JSON.parse(line);
                if (entry.type === 'user') {
                    userMessages++;
                    if (entry.message?.content) {
                        totalMessageChars += JSON.stringify(entry.message.content).length;
                    }
                } else if (entry.type === 'assistant') {
                    assistantMessages++;
                    if (entry.message?.content) {
                        totalMessageChars += JSON.stringify(entry.message.content).length;
                    }
                } else if (entry.type === 'tool_use' || entry.type === 'tool_result') {
                    toolUses++;
                }
            } catch (e) {
                // Skip unparseable lines
            }
        }

        // Estimate token counts based on character counts (rough: 4 chars per token)
        const estimatedMessageTokens = Math.round(totalMessageChars / 4);

        // Known fixed overhead values (these are relatively stable)
        const sysPrompt = 2600;
        const sysTools = 17100;
        const agents = 300;
        const memory = 1100;
        const skills = 1700;
        const compact = 3000;

        // Calculate messages as: total - fixed overhead
        // Use actual total if available, otherwise use estimate
        const fixedOverhead = sysPrompt + sysTools + agents + memory + skills + compact;
        let messages;

        if (totalUsed > 0) {
            messages = Math.max(0, totalUsed - fixedOverhead);
        } else {
            messages = estimatedMessageTokens;
        }

        const freeSpace = Math.max(0, ctxSize - (fixedOverhead + messages));

        // Write cache
        const cacheData = {
            timestamp: new Date().toISOString(),
            context_window_size: ctxSize,
            total_used: totalUsed || (fixedOverhead + messages),
            source: 'hook-calculated',
            transcript_stats: {
                user_messages: userMessages,
                assistant_messages: assistantMessages,
                tool_uses: toolUses
            },
            categories: {
                system_prompt: sysPrompt,
                system_tools: sysTools,
                custom_agents: agents,
                memory_files: memory,
                skills: skills,
                messages: messages,
                compact_buffer: compact,
                free_space: freeSpace
            }
        };

        fs.mkdirSync(path.dirname(CACHE_FILE), { recursive: true });
        fs.writeFileSync(CACHE_FILE, JSON.stringify(cacheData, null, 2));

        log(`Cache updated: total=${totalUsed}, messages=${messages}, userMsgs=${userMessages}`);

    } catch (error) {
        log(`Error: ${error.message}`);
    }

    // Always allow the operation to proceed
    console.log(JSON.stringify({ proceed: true }));
}

main();
