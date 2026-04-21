/**
 * mcp-jira.provider.ts — MCP-based JIRA task provider
 *
 * Instead of the loop fetching tasks via REST, the agent receives a
 * broad instruction and uses jira-mcp.ts tools to find, claim and
 * update issues autonomously.
 *
 * Trade-off vs REST provider:
 *   + Agent can use JIRA context (description, comments, priority)
 *   + No extra HTTP calls in the loop
 *   - Loop loses granular task-lifecycle control
 *   - Task selection is non-deterministic (LLM decides)
 *
 * Activate with: TASK_PROVIDER=mcp-jira
 *
 * Required env: JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN, JIRA_PROJECT
 */

import type { TaskProvider, Task } from "./task-provider.ts";

const REQUIRED = ["JIRA_BASE_URL", "JIRA_EMAIL", "JIRA_API_TOKEN", "JIRA_PROJECT"];

export class McpJiraProvider implements TaskProvider {
  readonly name = "mcp-jira";

  constructor() {
    const missing = REQUIRED.filter((k) => !process.env[k]);
    if (missing.length) {
      throw new Error(
        `McpJiraProvider requires: ${missing.join(", ")}`,
      );
    }
  }

  /**
   * Always returns a single synthetic task.
   * The agent's prompt + MCP tools do the real fetching.
   */
  async fetchPending(): Promise<Task[]> {
    return [{
      id:          "JIRA-AUTO",
      description: `Use the jira_search_issues tool to find the next open issue in project ${process.env.JIRA_PROJECT}. ` +
                   `Read its full details with jira_get_issue, transition it to "In Progress", implement it, ` +
                   `then transition to "Done" and add a comment summarising what was done. ` +
                   `If you cannot complete it, add a comment explaining why and transition to "Blocked".`,
      priority: "alta",
    }];
  }

  /** No-op — agent manages status via MCP tools directly. */
  async markInProgress(_task: Task): Promise<void> {}

  /** No-op — agent already transitioned to Done via jira_transition. */
  async markDone(_task: Task): Promise<void> {}

  /**
   * No-op — agent already transitioned to Blocked via jira_transition.
   * The loop's Discord notification still fires via notifyTaskStuck().
   */
  async markBlocked(_task: Task, _reason: string): Promise<void> {}
}
