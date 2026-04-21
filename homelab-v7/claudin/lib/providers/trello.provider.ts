/**
 * trello.provider.ts — Trello task provider
 *
 * Uses Trello REST API to manage tasks as cards across lists.
 * Requires: TRELLO_API_KEY, TRELLO_TOKEN, TRELLO_BACKLOG_LIST_ID
 * Optional: TRELLO_IN_PROGRESS_LIST_ID, TRELLO_DONE_LIST_ID, TRELLO_BLOCKED_LIST_ID
 *
 * Activate with: TASK_PROVIDER=trello
 *
 * Card name convention: "Task description | priority"
 * Priority falls back to first label name, then "média".
 */

import { TrelloClient } from "../trello.ts";
import type { TaskProvider, Task } from "./task-provider.ts";

export class TrelloProvider implements TaskProvider {
  readonly name = "trello";
  private readonly client: TrelloClient;

  constructor() {
    this.client = new TrelloClient();
    if (!this.client.enabled) {
      throw new Error(
        "TrelloProvider requires TRELLO_API_KEY, TRELLO_TOKEN and TRELLO_BACKLOG_LIST_ID env vars.",
      );
    }
  }

  async fetchPending(): Promise<Task[]> {
    return this.client.fetchBacklogCards();
  }

  async markInProgress(task: Task): Promise<void> {
    if (task.providerRef) await this.client.moveToInProgress(task.providerRef);
  }

  async markDone(task: Task): Promise<void> {
    if (task.providerRef) await this.client.moveToDone(task.providerRef);
  }

  async markBlocked(task: Task, reason: string): Promise<void> {
    if (task.providerRef) await this.client.moveToBlocked(task.providerRef);
    process.stderr.write(`[trello] blocked reason: ${reason}\n`);
  }
}
