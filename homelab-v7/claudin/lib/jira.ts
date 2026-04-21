/**
 * jira.ts — JIRA Cloud REST client
 *
 * Used by JiraProvider for task lifecycle management (fetch, transition, comment).
 * Authentication: Basic Auth (email:api_token base64-encoded).
 *
 * Required env vars:
 *   JIRA_BASE_URL   — https://your-domain.atlassian.net
 *   JIRA_EMAIL      — atlassian account email
 *   JIRA_API_TOKEN  — from id.atlassian.net/manage-profile/security/api-tokens
 *   JIRA_PROJECT    — project key, e.g. "DEV"
 */

import type { Task } from "./task.ts";

const BASE_URL    = (process.env.JIRA_BASE_URL ?? "").replace(/\/$/, "");
const EMAIL       = process.env.JIRA_EMAIL ?? "";
const API_TOKEN   = process.env.JIRA_API_TOKEN ?? "";
const PROJECT_KEY = process.env.JIRA_PROJECT ?? "";

const AUTH = "Basic " + Buffer.from(`${EMAIL}:${API_TOKEN}`).toString("base64");
const API  = `${BASE_URL}/rest/api/3`;

async function req(path: string, opts: RequestInit = {}): Promise<unknown> {
  const res = await fetch(`${API}${path}`, {
    ...opts,
    headers: {
      Authorization: AUTH,
      "Content-Type": "application/json",
      Accept: "application/json",
      ...opts.headers,
    },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`JIRA ${opts.method ?? "GET"} ${path} → ${res.status}: ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : null;
}

function adfDoc(text: string) {
  return {
    type: "doc", version: 1,
    content: [{ type: "paragraph", content: [{ type: "text", text }] }],
  };
}

function priorityFromIssue(fields: Record<string, unknown>): string {
  return (fields.priority as Record<string, string> | null)?.name?.toLowerCase()
    ?.replace("highest", "alta").replace("high", "alta")
    .replace("medium", "média").replace("low", "baixa").replace("lowest", "baixa")
    ?? "média";
}

// ── Public API ────────────────────────────────────────────────────────────────

export interface JiraClient {
  readonly enabled: boolean;
  fetchByStatuses(statuses: string[]): Promise<Task[]>;
  transition(issueKey: string, targetStatus: string): Promise<void>;
  addComment(issueKey: string, body: string): Promise<void>;
}

export class JiraRestClient implements JiraClient {
  readonly enabled: boolean;

  constructor() {
    this.enabled = !!(BASE_URL && EMAIL && API_TOKEN && PROJECT_KEY);
  }

  async fetchByStatuses(statuses: string[]): Promise<Task[]> {
    if (!this.enabled) return [];

    const statusList = statuses.map((s) => `"${s}"`).join(",");
    const jql = `project=${PROJECT_KEY} AND status in (${statusList}) ORDER BY priority DESC, created ASC`;

    const data = await req("/search/jql", {
      method: "POST",
      body: JSON.stringify({
        jql,
        maxResults: 50,
        fields: ["summary", "description", "status", "priority", "assignee"],
      }),
    }) as Record<string, unknown>;

    const issues = (data.issues as Record<string, unknown>[]) ?? [];

    return issues.map((issue) => {
      const fields = issue.fields as Record<string, unknown>;
      return {
        id:          issue.key as string,
        description: (fields.summary as string) ?? "",
        priority:    priorityFromIssue(fields),
        details:     undefined, // fetch on demand via MCP tool
        providerRef: issue.key as string,
      };
    });
  }

  async transition(issueKey: string, targetStatus: string): Promise<void> {
    if (!this.enabled) return;

    const data = await req(`/issue/${issueKey}/transitions`) as Record<string, unknown>;
    const transitions = (data.transitions as Record<string, unknown>[]) ?? [];

    const match = transitions.find(
      (t) => (t.name as string).toLowerCase() === targetStatus.toLowerCase(),
    );

    if (!match) {
      const available = transitions.map((t) => t.name).join(", ");
      process.stderr.write(
        `[jira] transition "${targetStatus}" not found for ${issueKey}. Available: ${available}\n`,
      );
      return;
    }

    await req(`/issue/${issueKey}/transitions`, {
      method: "POST",
      body: JSON.stringify({ transition: { id: match.id } }),
    });
  }

  async addComment(issueKey: string, body: string): Promise<void> {
    if (!this.enabled) return;
    await req(`/issue/${issueKey}/comment`, {
      method: "POST",
      body: JSON.stringify({ body: adfDoc(body) }),
    });
  }
}
