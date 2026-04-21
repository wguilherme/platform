/**
 * trello.ts — Trello REST client for the agent loop
 *
 * Enabled only when TRELLO_API_KEY + TRELLO_TOKEN + TRELLO_BACKLOG_LIST_ID are set.
 * All methods are no-ops (return empty/void) when disabled.
 * The loop uses this transparently — it doesn't know if Trello is the source.
 */

import type { Task } from "./task.ts";
export type { Task };

const BASE = "https://api.trello.com/1";

export class TrelloClient {
  readonly enabled: boolean;
  private readonly key: string;
  private readonly token: string;
  private readonly backlogListId: string;
  private readonly inProgressListId: string;
  private readonly doneListId: string;
  private readonly blockedListId: string;

  constructor() {
    this.key             = process.env.TRELLO_API_KEY            ?? "";
    this.token           = process.env.TRELLO_TOKEN              ?? "";
    this.backlogListId   = process.env.TRELLO_BACKLOG_LIST_ID    ?? "";
    this.inProgressListId= process.env.TRELLO_IN_PROGRESS_LIST_ID ?? "";
    this.doneListId      = process.env.TRELLO_DONE_LIST_ID       ?? "";
    this.blockedListId   = process.env.TRELLO_BLOCKED_LIST_ID    ?? "";
    this.enabled         = !!(this.key && this.token && this.backlogListId);
  }

  async fetchBacklogCards(): Promise<Task[]> {
    if (!this.enabled) return [];

    const url = `${BASE}/lists/${this.backlogListId}/cards?key=${this.key}&token=${this.token}&fields=id,name,desc,labels`;
    const res = await fetch(url);
    if (!res.ok) {
      process.stderr.write(`[trello] fetchBacklogCards failed: ${res.status}\n`);
      return [];
    }

    const cards = (await res.json()) as Array<{
      id: string;
      name: string;
      desc: string;
      labels: Array<{ name: string }>;
    }>;

    return cards.map((card) => {
      // Convention: card name can include priority like "Task title | alta"
      const [rawDesc, rawPriority] = card.name.split("|").map((s) => s.trim());
      const priority = rawPriority ?? card.labels[0]?.name ?? "média";
      return {
        id: card.id.slice(-6).toUpperCase(), // short ID for logging
        description: rawDesc,
        priority,
        details: card.desc || undefined,
        providerRef: card.id,
      };
    });
  }

  async moveToInProgress(cardId: string): Promise<void> {
    if (!this.enabled || !this.inProgressListId) return;
    await this.moveCard(cardId, this.inProgressListId);
  }

  async moveToDone(cardId: string): Promise<void> {
    if (!this.enabled || !this.doneListId) return;
    await this.moveCard(cardId, this.doneListId);
  }

  async moveToBlocked(cardId: string): Promise<void> {
    if (!this.enabled || !this.blockedListId) return;
    await this.moveCard(cardId, this.blockedListId);
  }

  private async moveCard(cardId: string, listId: string): Promise<void> {
    const url = `${BASE}/cards/${cardId}?key=${this.key}&token=${this.token}`;
    const res = await fetch(url, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idList: listId }),
    });
    if (!res.ok) {
      process.stderr.write(`[trello] moveCard ${cardId} → ${listId} failed: ${res.status}\n`);
    }
  }
}
