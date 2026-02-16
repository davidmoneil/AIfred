#!/usr/bin/env node
/**
 * Session Stop Hook
 *
 * Runs when Claude Code session ends. Sends desktop notification
 * so you know when long-running tasks complete.
 *
 * Requirements:
 * - Linux: notify-send (libnotify-bin package)
 * - macOS: osascript (built-in)
 * - Windows: PowerShell (built-in)
 *
 * Created: 2026-01-03
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 * Source: my-claude-code-setup research project
 */

const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const os = require('os');

// Notification settings
const APP_NAME = 'Claude Code';
const NOTIFICATION_TIMEOUT = 5000; // ms

/**
 * Send Linux notification via notify-send
 */
async function notifyLinux(title, message) {
  try {
    await execFileAsync('notify-send', [
      '--app-name=' + APP_NAME,
      '--urgency=low',
      '--icon=dialog-information',
      '--expire-time=10000',
      title,
      message
    ], { timeout: NOTIFICATION_TIMEOUT });
    return true;
  } catch {
    return false;
  }
}

/**
 * Send macOS notification via osascript
 */
async function notifyMacOS(title, message) {
  try {
    const script = `display notification "${message}" with title "${title}" sound name "Glass"`;
    await execFileAsync('osascript', ['-e', script], { timeout: NOTIFICATION_TIMEOUT });
    return true;
  } catch {
    return false;
  }
}

/**
 * Send Windows notification via PowerShell
 */
async function notifyWindows(title, message) {
  try {
    const script = `
      [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
      $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
      $textNodes = $template.GetElementsByTagName("text")
      $textNodes.Item(0).AppendChild($template.CreateTextNode("${title}")) | Out-Null
      $textNodes.Item(1).AppendChild($template.CreateTextNode("${message}")) | Out-Null
      $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
      [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("${APP_NAME}").Show($toast)
    `;
    await execFileAsync('powershell', ['-Command', script], { timeout: NOTIFICATION_TIMEOUT });
    return true;
  } catch {
    return false;
  }
}

/**
 * Send notification based on platform
 */
async function sendNotification(title, message) {
  const platform = os.platform();

  switch (platform) {
    case 'linux':
      return notifyLinux(title, message);
    case 'darwin':
      return notifyMacOS(title, message);
    case 'win32':
      return notifyWindows(title, message);
    default:
      console.error(`[session-stop] Notifications not supported on ${platform}`);
      return false;
  }
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  try {
    // Get session info if available
    const stopReason = context?.reason || 'completed';

    let title = 'Claude Code Complete';
    let message = 'Session finished successfully';

    // Customize message based on stop reason
    if (stopReason === 'error') {
      title = 'Claude Code Stopped';
      message = 'Session ended with an error';
    } else if (stopReason === 'user_cancelled') {
      title = 'Claude Code Cancelled';
      message = 'Session cancelled by user';
    }

    const sent = await sendNotification(title, message);

    if (sent) {
      console.error(`[session-stop] Notification sent: ${title}`);
    }

  } catch (err) {
    // Don't fail on notification errors
    console.error(`[session-stop] Notification error: ${err.message}`);
  }

  return {};
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  // Read JSON from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch (err) {
    // If we can't parse input, just return empty
    console.log(JSON.stringify({}));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[session-stop] Fatal error: ${err.message}`);
  console.log(JSON.stringify({}));
});
