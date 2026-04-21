#!/usr/bin/env bun
/**
 * jira-mcp.ts — JIRA MCP Server
 *
 * Exposes JIRA Cloud REST API v3 as MCP tools for the agent.
 * The agent uses these tools to find, claim, execute and update issues.
 *
 * Required env vars:
 *   JIRA_BASE_URL   — https://your-domain.atlassian.net
 *   JIRA_EMAIL      — your atlassian account email
 *   JIRA_API_TOKEN  — from id.atlassian.net/manage-profile/security/api-tokens
 *   JIRA_PROJECT    — project key, e.g. "PROJ" or "DEV"
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const BASE_URL    = (process.env.JIRA_BASE_URL ?? "").replace(/\/$/, "");
const EMAIL       = process.env.JIRA_EMAIL ?? "";
const API_TOKEN   = process.env.JIRA_API_TOKEN ?? "";
const PROJECT_KEY = process.env.JIRA_PROJECT ?? "";

if (!BASE_URL || !EMAIL || !API_TOKEN) {
  process.stderr.write("JIRA_BASE_URL, JIRA_EMAIL and JIRA_API_TOKEN are required\n");
  process.exit(1);
}

const AUTH = "Basic " + Buffer.from(`${EMAIL}:${API_TOKEN}`).toString("base64");
const API  = `${BASE_URL}/rest/api/3`;

async function jiraFetch(path: string, opts: RequestInit = {}): Promise<unknown> {
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
  if (!res.ok) {
    throw new Error(`JIRA ${opts.method ?? "GET"} ${path} → ${res.status}: ${text.slice(0, 300)}`);
  }
  return text ? JSON.parse(text) : null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function adfDoc(text: string) {
  return {
    type: "doc",
    version: 1,
    content: [{ type: "paragraph", content: [{ type: "text", text }] }],
  };
}

function extractText(adf: unknown): string {
  if (!adf || typeof adf !== "object") return "";
  const node = adf as Record<string, unknown>;
  if (node.type === "text" && typeof node.text === "string") return node.text;
  if (Array.isArray(node.content)) {
    return (node.content as unknown[]).map(extractText).join(" ");
  }
  return "";
}

function fmtIssue(issue: Record<string, unknown>): string {
  const f = issue.fields as Record<string, unknown>;
  const lines = [
    `Key: ${issue.key}`,
    `Summary: ${f.summary}`,
    `Status: ${(f.status as Record<string, unknown>)?.name}`,
    `Priority: ${(f.priority as Record<string, unknown>)?.name ?? "—"}`,
    `Assignee: ${(f.assignee as Record<string, unknown>)?.displayName ?? "Unassigned"}`,
  ];
  if (f.description) lines.push(`Description: ${extractText(f.description).slice(0, 400)}`);
  return lines.join("\n");
}

// ── MCP Server ────────────────────────────────────────────────────────────────

const server = new Server(
  { name: "claudin-jira", version: "1.0.0" },
  {
    capabilities: { tools: {} },
    instructions: `
      JIRA tools for the Claudin agent. Workflow:
      1. jira_search_issues — find open tasks
      2. jira_get_issue     — read full details before starting
      3. jira_transition    — move to "In Progress" when starting
      4. jira_comment       — add progress notes
      5. jira_transition    — move to "Done" when complete, or describe blocker in comment + transition to "Blocked"
    `,
  },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "jira_search_issues",
      description: "Search JIRA issues using JQL. Returns key, summary, status, priority.",
      inputSchema: {
        type: "object",
        properties: {
          jql: {
            type: "string",
            description: `JQL query. Default: project=${PROJECT_KEY} AND status="Open" ORDER BY priority DESC`,
          },
          max: { type: "number", description: "Max results (default 10)" },
        },
        required: [],
      },
    },
    {
      name: "jira_get_issue",
      description: "Get full details of a JIRA issue including description and comments.",
      inputSchema: {
        type: "object",
        properties: {
          key: { type: "string", description: "Issue key, e.g. PROJ-42" },
        },
        required: ["key"],
      },
    },
    {
      name: "jira_transition",
      description: 'Move a JIRA issue to a new status. Common statuses: "In Progress", "Done", "Blocked", "Open".',
      inputSchema: {
        type: "object",
        properties: {
          key:    { type: "string", description: "Issue key, e.g. PROJ-42" },
          status: { type: "string", description: 'Target status name, e.g. "In Progress"' },
        },
        required: ["key", "status"],
      },
    },
    {
      name: "jira_comment",
      description: "Add a comment to a JIRA issue.",
      inputSchema: {
        type: "object",
        properties: {
          key:  { type: "string", description: "Issue key" },
          body: { type: "string", description: "Comment text" },
        },
        required: ["key", "body"],
      },
    },
    {
      name: "jira_list_transitions",
      description: "List available transitions for a JIRA issue (useful to discover valid status names).",
      inputSchema: {
        type: "object",
        properties: {
          key: { type: "string", description: "Issue key" },
        },
        required: ["key"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;
  const a = (args ?? {}) as Record<string, unknown>;

  // ── jira_search_issues ────────────────────────────────────────────────────
  if (name === "jira_search_issues") {
    const jql = (a.jql as string | undefined)
      ?? `project=${PROJECT_KEY} AND status="Open" ORDER BY priority DESC`;
    const max = (a.max as number | undefined) ?? 10;

    const data = await jiraFetch("/search/jql", {
      method: "POST",
      body: JSON.stringify({
        jql,
        maxResults: max,
        fields: ["summary", "status", "priority", "assignee", "description"],
      }),
    }) as Record<string, unknown>;

    const issues = (data.issues as Record<string, unknown>[]) ?? [];
    if (issues.length === 0) {
      return { content: [{ type: "text", text: "No issues found." }] };
    }

    const text = issues.map(fmtIssue).join("\n---\n");
    return { content: [{ type: "text", text }] };
  }

  // ── jira_get_issue ────────────────────────────────────────────────────────
  if (name === "jira_get_issue") {
    const key = a.key as string;
    const issue = await jiraFetch(
      `/issue/${key}?fields=summary,status,priority,assignee,description,comment`,
    ) as Record<string, unknown>;

    const f     = issue.fields as Record<string, unknown>;
    const cmts  = ((f.comment as Record<string, unknown>)?.comments as Record<string, unknown>[]) ?? [];
    const last3 = cmts.slice(-3).map((c) =>
      `[${(c.author as Record<string, unknown>)?.displayName}]: ${extractText(c.body)}`
    ).join("\n");

    const text = [
      fmtIssue(issue),
      last3 ? `\nRecent comments:\n${last3}` : "",
    ].join("\n");

    return { content: [{ type: "text", text }] };
  }

  // ── jira_transition ───────────────────────────────────────────────────────
  if (name === "jira_transition") {
    const key    = a.key as string;
    const status = (a.status as string).toLowerCase();

    const data = await jiraFetch(`/issue/${key}/transitions`) as Record<string, unknown>;
    const transitions = (data.transitions as Record<string, unknown>[]) ?? [];

    const match = transitions.find(
      (t) => (t.name as string).toLowerCase() === status,
    );

    if (!match) {
      const available = transitions.map((t) => t.name).join(", ");
      return {
        content: [{
          type: "text",
          text: `Transition "${a.status}" not found. Available: ${available}`,
        }],
      };
    }

    await jiraFetch(`/issue/${key}/transitions`, {
      method: "POST",
      body: JSON.stringify({ transition: { id: match.id } }),
    });

    return {
      content: [{ type: "text", text: `${key} → ${match.name}` }],
    };
  }

  // ── jira_comment ──────────────────────────────────────────────────────────
  if (name === "jira_comment") {
    const key  = a.key as string;
    const body = a.body as string;

    await jiraFetch(`/issue/${key}/comment`, {
      method: "POST",
      body: JSON.stringify({ body: adfDoc(body) }),
    });

    return { content: [{ type: "text", text: `Comment added to ${key}` }] };
  }

  // ── jira_list_transitions ─────────────────────────────────────────────────
  if (name === "jira_list_transitions") {
    const key  = a.key as string;
    const data = await jiraFetch(`/issue/${key}/transitions`) as Record<string, unknown>;
    const list = (data.transitions as Record<string, unknown>[])
      .map((t) => `${t.id}: ${t.name}`)
      .join("\n");
    return { content: [{ type: "text", text: list }] };
  }

  throw new Error(`Unknown tool: ${name}`);
});

await server.connect(new StdioServerTransport());
