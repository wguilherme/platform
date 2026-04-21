/**
 * executor.ts — TaskExecutor
 *
 * Owns the Agent SDK interaction for a single task execution.
 * No knowledge of the loop, retry logic, or Discord notifications.
 */

import { query, type SDKMessage } from "@anthropic-ai/claude-agent-sdk";
import type { Config } from "./config.ts";
import type { Task } from "../lib/task.ts";
import { SessionStore } from "../lib/session-store.ts";
import { buildMcpConfig } from "./mcp.ts";

export interface TaskResult {
  outcome: "success" | "max_turns" | "error";
  sessionId?: string;
  errorDetail?: string;
}

function log(msg: string): void {
  const ts = new Date().toLocaleTimeString("pt-BR", { timeZone: "America/Sao_Paulo" });
  process.stdout.write(`[${ts}] ${msg}\n`);
}

function buildPrompt(task: Task, resumeId?: string): string {
  if (resumeId) {
    return `Continue task ${task.id}: ${task.description}. Resume from where you left off. Priority: ${task.priority}.`;
  }
  return [
    `Implement the following task:\n`,
    `**ID**: ${task.id}`,
    `**Task**: ${task.description}`,
    `**Priority**: ${task.priority}`,
    task.details ? `**Details**: ${task.details}` : "",
    `\nIMPORTANT: Do NOT call send_to_discord for task completion — the loop handles notifications.`,
    `Use send_to_discord only if you are genuinely stuck mid-task and need human input.`,
  ].filter(Boolean).join("\n");
}

export class TaskExecutor {
  constructor(
    private readonly cfg: Config,
    private readonly store: SessionStore,
    private readonly providerName: string,
  ) {}

  async run(task: Task, isResume: boolean): Promise<TaskResult> {
    const savedSession = this.store.get(task.id);
    const resumeId     = isResume && savedSession ? savedSession : undefined;

    if (this.cfg.dryRun) {
      log(`[DRY_RUN] Would execute: ${task.id} — ${task.description}`);
      await new Promise((r) => setTimeout(r, 1000));
      return { outcome: "success" };
    }

    const prompt     = buildPrompt(task, resumeId);
    const mcpServers = buildMcpConfig(this.providerName, this.cfg);

    let sessionId: string | undefined;
    let outcome: TaskResult["outcome"] = "error";
    let errorDetail: string | undefined;

    try {
      const stream = query({
        prompt,
        options: {
          maxTurns: this.cfg.maxTurns,
          cwd: this.cfg.projectDir,
          allowedTools: [
            "Task", "Bash", "Glob", "Grep", "Read", "Edit", "Write",
            "WebFetch", "WebSearch", "TodoWrite",
          ],
          permissionMode: "bypassPermissions",
          appendSystemPrompt: this.cfg.systemPrompt,
          settingSources: ["project"],
          ...(mcpServers ? { mcpServers } : {}),
          ...(resumeId ? { resume: resumeId } : {}),
        } as Parameters<typeof query>[0]["options"],
      });

      for await (const msg of stream as AsyncIterable<SDKMessage>) {
        if (msg.type === "system" && msg.subtype === "init") {
          sessionId = (msg as any).session_id;
          if (sessionId) this.store.save(task.id, sessionId);
          log(`  Session: ${sessionId}`);
        }

        if (msg.type === "assistant") {
          const content = (msg as any).message?.content ?? [];
          for (const block of content) {
            if (block.type === "text" && block.text) {
              process.stdout.write(`  > ${block.text.slice(0, 200)}\n`);
            }
          }
        }

        if (msg.type === "result") {
          sessionId = (msg as any).session_id ?? sessionId;
          const subtype = (msg as any).subtype;

          if (subtype === "success") {
            outcome = "success";
            this.store.clear(task.id);
          } else if (subtype === "error_max_turns") {
            outcome = "max_turns";
            if (sessionId) this.store.save(task.id, sessionId);
          } else {
            outcome = "error";
            errorDetail = subtype;
            this.store.clear(task.id);
          }
        }
      }
    } catch (err) {
      errorDetail = String(err);
      outcome = "error";
    }

    return { outcome, sessionId, errorDetail };
  }
}
