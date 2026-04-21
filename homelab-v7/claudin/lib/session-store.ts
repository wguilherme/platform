/**
 * session-store.ts — Persists Agent SDK session IDs to disk
 *
 * Allows the loop to resume an interrupted session after crash/restart.
 * File format: { "TASK-001": "sess_abc123", ... }
 */

import { readFileSync, writeFileSync, existsSync } from "fs";

export class SessionStore {
  private store: Record<string, string> = {};

  constructor(private readonly path: string) {
    this.load();
  }

  save(taskId: string, sessionId: string): void {
    this.store[taskId] = sessionId;
    this.flush();
  }

  get(taskId: string): string | undefined {
    return this.store[taskId];
  }

  clear(taskId: string): void {
    delete this.store[taskId];
    this.flush();
  }

  private load(): void {
    if (!existsSync(this.path)) return;
    try {
      this.store = JSON.parse(readFileSync(this.path, "utf8"));
    } catch {
      this.store = {};
    }
  }

  private flush(): void {
    try {
      writeFileSync(this.path, JSON.stringify(this.store, null, 2), "utf8");
    } catch (err) {
      process.stderr.write(`[session-store] failed to write ${this.path}: ${err}\n`);
    }
  }
}
