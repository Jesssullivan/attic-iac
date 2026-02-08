#!/usr/bin/env tsx
/**
 * Generate environments.json from organization.yaml
 *
 * This script reads the organization configuration and generates a JSON file
 * that the runner dashboard can import for environment-specific settings.
 */

import { existsSync, readFileSync, writeFileSync, copyFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { parse } from 'yaml';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface OrganizationConfig {
	organization: {
		name: string;
		full_name: string;
		group_path: string;
	};
	gitlab: {
		url: string;
		project_id: string;
		agent_group: string;
	};
	clusters: Array<{
		name: string;
		role: string;
		domain: string;
		context: string;
	}>;
	namespaces: {
		attic: Record<string, string>;
		runners: {
			all: string;
		};
	};
}

interface EnvironmentConfig {
	name: string;
	label: string;
	domain: string;
	namespace: string;
	gitlab_url: string;
	gitlab_project_id: string;
	role: string;
	context: string;
}

function generateLabel(cluster: OrganizationConfig['clusters'][0]): string {
	const roleLabels: Record<string, string> = {
		development: 'Dev',
		staging: 'Staging',
		production: 'Prod'
	};

	const roleLabel = roleLabels[cluster.role] || cluster.role;
	const clusterName = cluster.name.charAt(0).toUpperCase() + cluster.name.slice(1);

	return `${clusterName} (${roleLabel})`;
}

async function main() {
	try {
		// Read organization.yaml from parent directory, fall back to example
		const orgConfigPath = resolve(__dirname, '../../config/organization.yaml');
		const exampleConfigPath = resolve(__dirname, '../../config/organization.example.yaml');

		if (!existsSync(orgConfigPath)) {
			if (existsSync(exampleConfigPath)) {
				console.log(`organization.yaml not found, using example config`);
				copyFileSync(exampleConfigPath, orgConfigPath);
			} else {
				throw new Error('Neither organization.yaml nor organization.example.yaml found');
			}
		}

		console.log(`Reading organization config from: ${orgConfigPath}`);

		const orgConfigYaml = readFileSync(orgConfigPath, 'utf-8');
		const orgConfig = parse(orgConfigYaml) as OrganizationConfig;

		// Generate environment configs for each cluster
		const environments: EnvironmentConfig[] = orgConfig.clusters.map((cluster) => ({
			name: cluster.name,
			label: generateLabel(cluster),
			domain: cluster.domain,
			namespace: orgConfig.namespaces.runners.all,
			gitlab_url: orgConfig.gitlab.url,
			gitlab_project_id: orgConfig.gitlab.project_id,
			role: cluster.role,
			context: cluster.context
		}));

		// Write to app/src/lib/config/environments.json
		const outputPath = resolve(__dirname, '../src/lib/config/environments.json');
		writeFileSync(outputPath, JSON.stringify(environments, null, 2) + '\n');

		console.log(`✅ Generated ${environments.length} environment configs to: ${outputPath}`);
		environments.forEach((env) => {
			console.log(`   - ${env.name}: ${env.domain} (${env.role})`);
		});
	} catch (error) {
		console.error('❌ Failed to generate environments.json:');
		console.error(error);
		process.exit(1);
	}
}

main();
