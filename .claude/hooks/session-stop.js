/**
 * Session Stop Hook
 *
 * Sends desktop notification when Claude Code session ends.
 * Uses platform-specific notification methods:
 * - macOS: osascript
 * - Linux: notify-send (requires libnotify-bin)
 *
 * Priority: LOW (Notification)
 * Created: 2026-01-06
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const { exec } = require('child_process');
const os = require('os');

/**
 * Send desktop notification
 */
function sendNotification(title, message, isError = false) {
  const platform = os.platform();

  if (platform === 'darwin') {
    // macOS - use osascript
    const sound = isError ? 'Basso' : 'Glass';
    const script = `display notification "${message}" with title "${title}" sound name "${sound}"`;
    exec(`osascript -e '${script}'`, (err) => {
      if (err) {
        console.log(`[session-stop] Notification failed: ${err.message}`);
      }
    });
  } else if (platform === 'linux') {
    // Linux - use notify-send
    const urgency = isError ? 'critical' : 'normal';
    const icon = isError ? 'dialog-error' : 'dialog-information';
    exec(`notify-send -u ${urgency} -i ${icon} "${title}" "${message}"`, (err) => {
      if (err) {
        console.log(`[session-stop] Notification failed: ${err.message}`);
        console.log('Install libnotify-bin: sudo apt install libnotify-bin');
      }
    });
  } else {
    // Windows or other - just log
    console.log(`[session-stop] ${title}: ${message}`);
  }
}

module.exports = {
  name: 'session-stop',
  description: 'Send desktop notification when session ends',
  event: 'Stop',

  async handler(context) {
    const { stop_hook_active, session_id } = context;

    // Determine notification based on stop reason
    if (context.error) {
      sendNotification(
        '⚠️ Jarvis Session Stopped',
        'Session ended with an error',
        true
      );
    } else if (context.cancelled) {
      sendNotification(
        '🛑 Jarvis Session Cancelled',
        'Session was cancelled by user',
        false
      );
    } else {
      sendNotification(
        '✅ Jarvis Session Complete',
        'Claude Code session ended successfully',
        false
      );
    }

    return { proceed: true };
  }
};
