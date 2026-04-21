/**
 * task.ts — Shared Task type
 *
 * Single source of truth for the Task interface used across all providers.
 */

export interface Task {
  id: string;
  description: string;
  priority: "alta" | "média" | "baixa" | string;
  details?: string;
  /** Provider-specific opaque reference (e.g. Trello card ID). */
  providerRef?: string;
}
