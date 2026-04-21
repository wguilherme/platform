/**
 * markdown.provider.ts — Markdown/backlog.md task provider
 *
 * Reads and writes tasks from `claudin/tasks/backlog.md`.
 * Default provider — requires no external services.
 *
 * Activate with: TASK_PROVIDER=markdown (or omit, it's the default)
 */

import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { BacklogFile } from "../backlog.ts";
import type { TaskProvider, Task } from "./task-provider.ts";

const CLAUDIN_DIR = dirname(resolve(fileURLToPath(import.meta.url), "../.."));

export class MarkdownProvider implements TaskProvider {
  readonly name = "markdown";
  private readonly backlog: BacklogFile;

  constructor(backlogPath?: string) {
    const path = backlogPath ?? resolve(CLAUDIN_DIR, "tasks", "backlog.md");
    this.backlog = new BacklogFile(path);
  }

  async fetchPending(): Promise<Task[]> {
    return this.backlog.readPendingTasks();
  }

  async markInProgress(task: Task): Promise<void> {
    this.backlog.markInProgress(task.id);
  }

  async markDone(task: Task): Promise<void> {
    this.backlog.markDone(task.id);
  }

  async markBlocked(task: Task, reason: string): Promise<void> {
    this.backlog.markBlocked(task.id, reason);
  }
}
