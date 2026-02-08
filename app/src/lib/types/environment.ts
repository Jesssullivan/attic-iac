// Generated environment configuration
// This file loads environment configs from the generated environments.json
// which is created from config/organization.yaml during the prebuild step

import environmentsJson from '../config/environments.json';

// Environment configuration interface
export interface EnvironmentConfig {
	name: string;
	label: string;
	domain: string;
	namespace: string;
	gitlab_url: string;
	gitlab_project_id: string;
	role: string;
	context: string;
}

// Load environments from generated JSON
const environments = environmentsJson as EnvironmentConfig[];

// Export environment names as const array
export const ENVIRONMENTS = environments.map((env) => env.name) as string[];
export type Environment = (typeof ENVIRONMENTS)[number];

// Generate lookup records from the environment configs
export const ENV_LABELS: Record<string, string> = Object.fromEntries(
	environments.map((env) => [env.name, env.label])
);

export const ENV_DOMAINS: Record<string, string> = Object.fromEntries(
	environments.map((env) => [env.name, env.domain])
);

export const ENVIRONMENT_CONFIGS: Record<string, EnvironmentConfig> = Object.fromEntries(
	environments.map((env) => [env.name, env])
);

// Helper function to get environment config by name
export function getEnvironmentConfig(name: string): EnvironmentConfig | undefined {
	return ENVIRONMENT_CONFIGS[name];
}

// Helper function to check if an environment name is valid
export function isValidEnvironment(name: string): name is Environment {
	return ENVIRONMENTS.includes(name);
}
