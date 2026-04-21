/**
 * providers/index.ts — TaskProvider factory
 *
 * Reads TASK_PROVIDER env var and returns the right implementation.
 *
 * Supported values:
 *   markdown  (default) — reads/writes claudin/tasks/backlog.md
 *   trello              — uses Trello REST API
 *
 * Usage:
 *   TASK_PROVIDER=trello bun run claudin/agent-loop.ts
 *   make start-loop TASK_PROVIDER=trello
 */

import type { TaskProvider } from "./task-provider.ts";

const SUPPORTED = ["markdown", "trello", "jira", "mcp-jira"] as const;
type ProviderName = (typeof SUPPORTED)[number];

export type { TaskProvider };
export type { Task } from "./task-provider.ts";

export async function createTaskProvider(): Promise<TaskProvider> {
  const name = (process.env.TASK_PROVIDER ?? "markdown") as ProviderName;

  switch (name) {
    case "markdown": {
      const { MarkdownProvider } = await import("./markdown.provider.ts");
      return new MarkdownProvider();
    }
    case "trello": {
      const { TrelloProvider } = await import("./trello.provider.ts");
      return new TrelloProvider();
    }
    case "jira": {
      const { JiraProvider } = await import("./jira.provider.ts");
      return new JiraProvider();
    }
    case "mcp-jira": {
      const { McpJiraProvider } = await import("./mcp-jira.provider.ts");
      return new McpJiraProvider();
    }
    default: {
      const valid = SUPPORTED.join(" | ");
      throw new Error(
        `Unknown TASK_PROVIDER="${name}". Valid options: ${valid}`,
      );
    }
  }
}
