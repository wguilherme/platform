/**
 * task-provider.ts — TaskProvider interface
 *
 * Any task source (Markdown, Trello, Linear, GitHub Issues…) must implement this.
 * The agent-loop only depends on this interface — zero vendor lock-in.
 */

import type { Task } from "../task.ts";

export type { Task };

export interface TaskProvider {
  /** Human-readable name shown in logs (e.g. "markdown", "trello"). */
  readonly name: string;

  /** Returns pending tasks ordered by priority / insertion order. */
  fetchPending(): Promise<Task[]>;

  /** Mark a task as in-progress. */
  markInProgress(task: Task): Promise<void>;

  /** Mark a task as done. */
  markDone(task: Task): Promise<void>;

  /** Mark a task as blocked with a reason. */
  markBlocked(task: Task, reason: string): Promise<void>;
}
