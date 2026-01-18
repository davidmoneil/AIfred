#!/usr/bin/env node
/**
 * Startup Greeting Helper (evo-2026-01-020)
 *
 * Generates contextual greeting components for Jarvis startup.
 * Can be called from session-start.sh or used standalone.
 *
 * Created: 2026-01-18 (R&D Cycle implementation)
 *
 * Features:
 * - Time-of-day detection
 * - Weather fetching via wttr.in
 * - Greeting template generation
 * - JSON output for shell integration
 *
 * Usage:
 *   node startup-greeting.js                    # Full greeting JSON
 *   node startup-greeting.js --weather-only     # Weather data only
 *   node startup-greeting.js --time-only        # Time/greeting only
 *
 * Environment Variables:
 *   JARVIS_WEATHER_LOCATION - Location for weather (default: Salt+Lake+City)
 *   JARVIS_DISABLE_WEATHER  - Set to "true" to skip weather fetch
 */

const https = require('https');
const http = require('http');

// Configuration
const CONFIG = {
  weatherLocation: process.env.JARVIS_WEATHER_LOCATION || 'Salt+Lake+City',
  disableWeather: process.env.JARVIS_DISABLE_WEATHER === 'true',
  weatherTimeoutMs: 5000,
  wttrUrl: 'https://wttr.in'
};

/**
 * Get time-of-day greeting
 */
function getTimeOfDayGreeting() {
  const hour = new Date().getHours();

  if (hour >= 5 && hour < 12) {
    return { timeOfDay: 'morning', greeting: 'Good morning' };
  } else if (hour >= 12 && hour < 17) {
    return { timeOfDay: 'afternoon', greeting: 'Good afternoon' };
  } else if (hour >= 17 && hour < 21) {
    return { timeOfDay: 'evening', greeting: 'Good evening' };
  } else {
    return { timeOfDay: 'night', greeting: 'Good evening' };
  }
}

/**
 * Fetch weather from wttr.in
 */
function fetchWeather(location) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${CONFIG.wttrUrl}/${encodeURIComponent(location)}`);
    url.searchParams.set('format', 'j1');

    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      timeout: CONFIG.weatherTimeoutMs,
      headers: {
        'User-Agent': 'curl/7.79.1',
        'Accept': 'application/json'
      }
    };

    const request = https.get(options, (response) => {
      let data = '';

      response.on('data', chunk => { data += chunk; });

      response.on('end', () => {
        try {
          const json = JSON.parse(data);
          const current = json.current_condition?.[0];

          if (!current) {
            resolve(null);
            return;
          }

          resolve({
            tempF: current.temp_F || '?',
            feelsLikeF: current.FeelsLikeF || '?',
            description: current.weatherDesc?.[0]?.value || 'Unknown',
            humidity: current.humidity || '?',
            location: location.replace(/\+/g, ' ')
          });
        } catch (e) {
          resolve(null);
        }
      });
    });

    request.on('error', () => resolve(null));
    request.on('timeout', () => {
      request.destroy();
      resolve(null);
    });
  });
}

/**
 * Format weather for display
 */
function formatWeather(weather) {
  if (!weather) return null;

  return `${weather.tempF}°F (feels like ${weather.feelsLikeF}°F), ${weather.description}, ${weather.humidity}% humidity`;
}

/**
 * Generate full greeting object
 */
async function generateGreeting() {
  const time = getTimeOfDayGreeting();
  let weather = null;
  let weatherFormatted = null;

  if (!CONFIG.disableWeather) {
    weather = await fetchWeather(CONFIG.weatherLocation);
    weatherFormatted = formatWeather(weather);
  }

  return {
    timestamp: new Date().toISOString(),
    localTime: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    ...time,
    weather: weather,
    weatherFormatted: weatherFormatted,
    greetingFull: weatherFormatted
      ? `${time.greeting}, sir. ${weatherFormatted}.`
      : `${time.greeting}, sir.`
  };
}

/**
 * Main entry point
 */
async function main() {
  const args = process.argv.slice(2);

  try {
    if (args.includes('--weather-only')) {
      if (CONFIG.disableWeather) {
        console.log(JSON.stringify({ weather: null, disabled: true }));
        return;
      }
      const weather = await fetchWeather(CONFIG.weatherLocation);
      console.log(JSON.stringify({
        weather: weather,
        formatted: formatWeather(weather)
      }));
    } else if (args.includes('--time-only')) {
      const time = getTimeOfDayGreeting();
      console.log(JSON.stringify(time));
    } else {
      // Full greeting
      const greeting = await generateGreeting();
      console.log(JSON.stringify(greeting));
    }
  } catch (error) {
    console.error(JSON.stringify({ error: error.message }));
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

// Export for require() usage
module.exports = {
  getTimeOfDayGreeting,
  fetchWeather,
  formatWeather,
  generateGreeting
};
