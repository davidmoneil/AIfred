/**
 * @deprecated Use docker-validator.js instead (consolidated 2025-12-24)
 *
 * Network Validator Hook
 *
 * Validates Docker network configuration:
 * - Checks if referenced networks exist
 * - Validates network connectivity between containers
 * - Warns about missing network attachments
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-06
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const fs = require('fs').promises;

// Known networks that should exist
const KNOWN_NETWORKS = [
  'proxy-network',
  'logging',
  'bridge',
  'host',
  'none'
];

/**
 * Get list of existing Docker networks
 */
async function getExistingNetworks() {
  try {
    const { stdout } = await execAsync('docker network ls --format "{{.Name}}" 2>/dev/null');
    return stdout.trim().split('\n').filter(n => n);
  } catch {
    return [];
  }
}

/**
 * Extract networks from compose file
 */
async function extractNetworksFromCompose(composePath) {
  const networks = {
    defined: [],      // Networks defined in networks: section
    referenced: []    // Networks referenced in services
  };

  try {
    const content = await fs.readFile(composePath, 'utf-8');

    // Find networks section
    const networksMatch = content.match(/^networks:\s*\n((?:[ \t]+\S[^\n]*\n?)+)/m);
    if (networksMatch) {
      const networkLines = networksMatch[1].split('\n');
      networkLines.forEach(line => {
        const match = line.match(/^\s{2}(\S+):/);
        if (match) {
          networks.defined.push(match[1]);
        }
      });
    }

    // Find service network references
    const serviceNetworksPattern = /networks:\s*\n((?:\s+-\s*\S+\n?)+)/g;
    let match;
    while ((match = serviceNetworksPattern.exec(content)) !== null) {
      const networkLines = match[1].split('\n');
      networkLines.forEach(line => {
        const netMatch = line.match(/^\s+-\s*(\S+)/);
        if (netMatch) {
          networks.referenced.push(netMatch[1]);
        }
      });
    }

    // Also check for network_mode
    const networkModePattern = /network_mode:\s*["']?(\S+)["']?/g;
    while ((match = networkModePattern.exec(content)) !== null) {
      if (match[1] !== 'host' && match[1] !== 'bridge' && match[1] !== 'none') {
        networks.referenced.push(match[1].replace(/^container:/, ''));
      }
    }

  } catch {
    // File not readable
  }

  return {
    defined: [...new Set(networks.defined)],
    referenced: [...new Set(networks.referenced)]
  };
}

/**
 * Check if container is on network
 */
async function containerOnNetwork(containerName, networkName) {
  try {
    const { stdout } = await execAsync(
      `docker network inspect ${networkName} --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null`
    );
    return stdout.includes(containerName);
  } catch {
    return false;
  }
}

module.exports = {
  name: 'network-validator',
  description: 'Validate Docker network configuration',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Check for docker-compose up
    const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start)/i);

    if (composeMatch) {
      const composePath = composeMatch[1] || 'docker-compose.yml';

      console.log('\n[network-validator] Checking network configuration...');

      try {
        const existingNetworks = await getExistingNetworks();
        const composeNetworks = await extractNetworksFromCompose(composePath);

        const issues = [];
        const warnings = [];

        // Check each referenced network
        for (const network of composeNetworks.referenced) {
          // Skip built-in networks
          if (['bridge', 'host', 'none', 'default'].includes(network)) {
            continue;
          }

          // Check if it's defined in compose or exists externally
          const isDefinedInCompose = composeNetworks.defined.includes(network);
          const existsExternally = existingNetworks.includes(network);

          if (!isDefinedInCompose && !existsExternally) {
            issues.push(`Network "${network}" does not exist and is not defined in compose`);
          } else if (existsExternally && !isDefinedInCompose) {
            // External network should be marked as external in compose
            // This is a warning, not an error
            warnings.push(`Network "${network}" is external - ensure it's marked with "external: true"`);
          }
        }

        // Check known networks
        const usesKnownNetwork = composeNetworks.referenced.some(n => KNOWN_NETWORKS.includes(n));

        if (!usesKnownNetwork && composeNetworks.referenced.length > 0) {
          warnings.push('No standard network (proxy-network, logging) detected');
        }

        if (issues.length > 0) {
          console.log('─'.repeat(50));
          console.log('❌ NETWORK ISSUES:');
          issues.forEach(i => console.log(`  • ${i}`));
          console.log('─'.repeat(50));
          console.log('\nTo fix:');
          console.log('  1. Create the network: docker network create <name>');
          console.log('  2. Or add to compose networks section with "external: true"');
          console.log('  3. Or define the network in the compose file\n');

          return {
            proceed: false,
            message: `Missing networks: ${issues.join('; ')}`
          };
        }

        if (warnings.length > 0) {
          console.log('─'.repeat(50));
          console.log('⚠️  WARNINGS:');
          warnings.forEach(w => console.log(`  • ${w}`));
          console.log('─'.repeat(50) + '\n');
        } else {
          console.log('✓ Network configuration valid\n');
        }

      } catch (err) {
        console.log(`[network-validator] Warning: ${err.message}\n`);
      }
    }

    // Check for docker network connect
    if (command.includes('docker network connect')) {
      const match = command.match(/docker network connect\s+(\S+)\s+(\S+)/);
      if (match) {
        const [, networkName, containerName] = match;

        const existingNetworks = await getExistingNetworks();
        if (!existingNetworks.includes(networkName)) {
          console.log(`\n[network-validator] ❌ Network "${networkName}" does not exist`);
          console.log(`Create it with: docker network create ${networkName}\n`);

          return {
            proceed: false,
            message: `Network "${networkName}" does not exist`
          };
        }
      }
    }

    return { proceed: true };
  }
};
