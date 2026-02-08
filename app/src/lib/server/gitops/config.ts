/**
 * GitOps configuration helpers
 *
 * Provides functions to construct paths and config values based on the current environment.
 */

import type { Environment } from '$lib/types/environment';

/**
 * Get the tfvars file path for a given environment and runner stack.
 *
 * @param environment - Target environment name (e.g., "beehive", "rigel")
 * @param stack - Stack name (default: "bates-ils-runners")
 * @returns Path to the tfvars file relative to repo root
 */
export function getTfvarsPath(
	environment: Environment | string,
	stack: string = 'bates-ils-runners'
): string {
	return `tofu/stacks/${stack}/${environment}.tfvars`;
}

/**
 * Get the default environment for GitOps operations.
 * This is typically the first/primary cluster in the organization config.
 *
 * @returns Default environment name
 */
export function getDefaultEnvironment(): string {
	// Default to "beehive" for Bates, but this could be loaded from config
	return 'beehive';
}
