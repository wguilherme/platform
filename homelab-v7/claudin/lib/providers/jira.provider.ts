/**
 * jira.provider.ts — Hybrid JIRA task provider
 *
 * Hybrid approach — best of both worlds:
 *   • Loop fetches tasks via REST (deterministic, zero token cost)
 *   • Agent executes with JIRA MCP tools available (reads full descriptions,
 *     adds comments, transitions — all during task execution)
 *
 * vs mcp-jira.provider.ts (pure MCP):
 *   mcp-jira: agent picks AND executes — flexible but non-deterministic + costly
 *   jira:     loop picks (REST) + agent executes (MCP tools) — deterministic + rich context
 *
 * Activate with: TASK_PROVIDER=jira
 *
 * Required env:
 *   JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN, JIRA_PROJECT
 *
 * Optional env:
 *   JIRA_TODO_STATUSES      — comma-separated statuses to fetch (default: "To Do")
 *   JIRA_IN_PROGRESS_STATUS — target status when starting a task (default: "In Progress")
 *   JIRA_DONE_STATUS        — target status when task succeeds  (default: "Done")
 *   JIRA_BLOCKED_STATUS     — target status when task is stuck  (default: "Blocked")
 */

import { JiraRestClient } from "../jira.ts";
import type { TaskProvider, Task } from "./task-provider.ts";

function parseCsv(value: string | undefined, fallback: string): string[] {
  return (value ?? fallback).split(",").map((s) => s.trim()).filter(Boolean);
}

export class JiraProvider implements TaskProvider {
  readonly name = "jira";

  private readonly client: JiraRestClient;
  private readonly todoStatuses: string[];
  private readonly inProgressStatus: string;
  private readonly doneStatus: string;
  private readonly blockedStatus: string;

  constructor() {
    this.client = new JiraRestClient();

    if (!this.client.enabled) {
      throw new Error(
        "JiraProvider requires JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN and JIRA_PROJECT.",
      );
    }

    this.todoStatuses      = parseCsv(process.env.JIRA_TODO_STATUSES,      "To Do");
    this.inProgressStatus  = process.env.JIRA_IN_PROGRESS_STATUS ?? "In Progress";
    this.doneStatus        = process.env.JIRA_DONE_STATUS        ?? "Done";
    this.blockedStatus     = process.env.JIRA_BLOCKED_STATUS     ?? "Blocked";
  }

  async fetchPending(): Promise<Task[]> {
    return this.client.fetchByStatuses(this.todoStatuses);
  }

  async markInProgress(task: Task): Promise<void> {
    if (task.providerRef) await this.client.transition(task.providerRef, this.inProgressStatus);
  }

  async markDone(task: Task): Promise<void> {
    if (task.providerRef) await this.client.transition(task.providerRef, this.doneStatus);
  }

  async markBlocked(task: Task, reason: string): Promise<void> {
    if (!task.providerRef) return;
    await this.client.addComment(task.providerRef, `Blocked by Claudin agent:\n${reason}`);
    await this.client.transition(task.providerRef, this.blockedStatus);
  }
}
