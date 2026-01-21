#!/bin/bash
# Test script for debugging keystroke sending
# Run this from a DIFFERENT terminal than your Claude session

echo "=== Keystroke Test ==="
echo ""
echo "This will try to send '/test' + Enter to your Claude terminal."
echo "Watch your Claude terminal to see if it receives the input."
echo ""
echo "Make sure:"
echo "1. You have a Claude session running in another Terminal window"
echo "2. Claude is at a prompt (not mid-response)"
echo ""
read -p "Press Enter to test... "

echo ""
echo "Activating Terminal and sending keystrokes..."

osascript <<'APPLESCRIPT'
tell application "Terminal"
    activate
    delay 0.5

    -- Log all window titles for debugging
    set windowTitles to {}
    repeat with w in windows
        set end of windowTitles to name of w
    end repeat

    -- Find first window that doesn't seem to be a test/watcher
    set targetWindow to missing value
    repeat with w in windows
        set winName to name of w
        if winName does not contain "test-keystroke" and winName does not contain "Watcher" then
            set targetWindow to w
            exit repeat
        end if
    end repeat

    if targetWindow is not missing value then
        set frontmost of targetWindow to true
        delay 0.3
    end if

    tell application "System Events"
        tell process "Terminal"
            keystroke "/test-keystroke-success"
            delay 0.2
            key code 36
        end tell
    end tell

    return "Sent to window. All windows: " & (windowTitles as text)
end tell
APPLESCRIPT

RESULT=$?
echo ""
if [[ $RESULT -eq 0 ]]; then
    echo "AppleScript executed successfully."
    echo ""
    echo "Check your Claude terminal:"
    echo "- If you see '/test-keystroke-success' and it tried to execute: WORKING"
    echo "- If text appears but doesn't execute: Return key not being processed"
    echo "- If nothing appears: Wrong window targeted"
else
    echo "AppleScript failed with code $RESULT"
fi
echo ""
echo "If this doesn't work, try installing cliclick:"
echo "  brew install cliclick"
