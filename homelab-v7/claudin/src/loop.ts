/**
 * loop.ts — AgentLoop
 *
 * Orchestrates the autonomous work cycle:
 *   pick task → mark in-progress → execute (with retries) → mark done/blocked → repeat
 *
 * Owns retry logic and Discord lifecycle notifications.
 * Delegates execution to TaskExecutor and task state to TaskProvider.
 */

import type { Config } from "./config.ts";
import type { TaskExecutor } from "./executor.ts";
import type { TaskProvider } from "../lib/providers/index.ts";
import type { SessionStore } from "../lib/session-store.ts";
import {
  sendToDiscord,
  notifyTaskStarted,
  notifyTaskDone,
  notifyTaskResuming,
  notifyTaskRetry,
  notifyTaskStuck,
  notifyIdle,
} from "../lib/discord.ts";

function log(msg: string): void {
  const ts = new Date().toLocaleTimeString("pt-BR", { timeZone: "America/Sao_Paulo" });
  process.stdout.write(`[${ts}] ${msg}\n`);
}

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

export class AgentLoop {
  shuttingDown = false;
  totalCycles  = 0;

  constructor(
    private readonly cfg: Config,
    private readonly executor: TaskExecutor,
    private readonly provider: TaskProvider,
    private readonly store: SessionStore,
  ) {}

  async runCycle(): Promise<void> {
    this.totalCycles++;
    log(`Cycle ${this.totalCycles} — picking next task`);

    const pending = await this.provider.fetchPending();
    const task    = pending[0] ?? null;

    if (!task) {
      const fetched = pending.length;
      log(`Backlog empty — waiting (provider: ${this.provider.name}, fetched: ${fetched})`);
      await notifyIdle(this.totalCycles, this.provider.name, fetched, this.providerContext());
      await sleep(this.cfg.sleepMs * 6);
      return;
    }

    log(`Task: ${task.id} — ${task.description} [${task.priority}]`);
    await this.provider.markInProgress(task);

    let retries   = 0;
    let lastError: string | undefined;

    while (!this.shuttingDown) {
      await notifyTaskStarted(task, retries + 1, this.cfg.retryLimit);
      const result = await this.executor.run(task, retries > 0);

      if (result.outcome === "success") {
        log(`Task ${task.id} completed`);
        await this.provider.markDone(task);
        this.store.clear(task.id);
        await notifyTaskDone(task, result.sessionId);
        await sleep(this.cfg.sleepMs);
        return;
      }

      if (result.outcome === "max_turns") {
        log(`Task ${task.id} hit max_turns — resuming (session: ${result.sessionId})`);
        if (result.sessionId) await notifyTaskResuming(task, result.sessionId);
        continue;
      }

      // Real error
      retries++;
      lastError = result.errorDetail ?? "Unknown error";
      log(`Task ${task.id} error (attempt ${retries}/${this.cfg.retryLimit}): ${lastError}`);

      if (retries > this.cfg.retryLimit) break;
      await notifyTaskRetry(task, retries, this.cfg.retryLimit, lastError);
      await sleep(this.cfg.sleepMs);
    }

    // Exceeded retries → stuck
    log(`Task ${task.id} stuck after ${retries} attempts`);
    await this.provider.markBlocked(task, lastError ?? "Unknown");
    this.store.clear(task.id);
    await notifyTaskStuck(task, retries, this.cfg.retryLimit, lastError ?? "Unknown");
    await sleep(this.cfg.sleepMs);
  }

  async handleUnhandledError(err: unknown): Promise<void> {
    log(`Unhandled error in cycle: ${err}`);
    await sendToDiscord(
      `\`\`\`\n${String(err).slice(0, 500)}\n\`\`\``,
      "warning",
      "⚠️ Erro no agent-loop",
    ).catch(() => {});
    await sleep(this.cfg.sleepMs * 3);
  }

  private providerContext(): string | undefined {
    const name = this.provider.name;
    if (name === "jira" || name === "mcp-jira") {
      return process.env.JIRA_TODO_STATUSES ?? "To Do";
    }
    if (name === "trello") return process.env.TRELLO_BACKLOG_LIST_ID;
    if (name === "markdown") return "claudin/tasks/backlog.md";
    return undefined;
  }
}
