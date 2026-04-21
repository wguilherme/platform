/**
 * discord.ts — Discord webhook notifications
 *
 * Plain fetch-based helper used by agent-loop.ts to send status messages.
 * No MCP dependency — this runs in the loop process, not the agent.
 */

import type { Task } from "./trello.ts";

export type StatusType =
  | "success"
  | "stuck"
  | "waiting"
  | "warning"
  | "question"
  | "info"
  | "running"
  | "retry";

const STATUS_COLORS: Record<StatusType, number> = {
  success:  0x00c853, // green
  stuck:    0xd50000, // red
  waiting:  0x546e7a, // grey
  warning:  0xffd600, // yellow
  question: 0x2962ff, // blue
  info:     0x546e7a, // grey
  running:  0x00b0ff, // cyan
  retry:    0xff6d00, // orange
};

interface EmbedField {
  name: string;
  value: string;
  inline?: boolean;
}

interface SendOptions {
  title?: string;
  fields?: EmbedField[];
}

async function post(
  status: StatusType,
  description: string,
  opts: SendOptions = {},
): Promise<void> {
  const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
  if (!webhookUrl) return;

  const machine = process.env.MACHINE_NAME ?? "agent";
  const color   = STATUS_COLORS[status];
  const ts      = new Date().toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" });

  const body: Record<string, unknown> = {
    username: "Claudin",
    embeds: [{
      title:       opts.title ?? "",
      description: description || undefined,
      color,
      fields:      opts.fields ?? [],
      timestamp:   new Date().toISOString(),
      footer:      { text: `🤖 ${machine} · ${ts}` },
    }],
  };

  await fetch(webhookUrl, {
    method:  "POST",
    headers: { "Content-Type": "application/json" },
    body:    JSON.stringify(body),
  }).catch((err) => {
    process.stderr.write(`[discord] webhook failed: ${err}\n`);
  });
}

// ── Public API ────────────────────────────────────────────────────────────────

/** Task picked up and starting execution */
export async function notifyTaskStarted(task: Task, attempt: number, totalRetries: number): Promise<void> {
  await post("running", "", {
    title: `🔄 Iniciando — ${task.id}`,
    fields: [
      { name: "Tarefa",      value: task.description,           inline: false },
      { name: "Prioridade",  value: `\`${task.priority}\``,     inline: true  },
      { name: "Tentativa",   value: `${attempt} / ${totalRetries}`, inline: true },
    ],
  });
}

/** Task completed successfully */
export async function notifyTaskDone(task: Task, sessionId?: string): Promise<void> {
  const fields: EmbedField[] = [
    { name: "Tarefa",     value: task.description,       inline: false },
    { name: "Prioridade", value: `\`${task.priority}\``, inline: true  },
  ];
  if (sessionId) fields.push({ name: "Sessão", value: `\`${sessionId.slice(0, 20)}…\``, inline: true });

  await post("success", "", {
    title: `✅ Concluída — ${task.id}`,
    fields,
  });
}

/** Task hit max_turns and will resume next cycle */
export async function notifyTaskResuming(task: Task, sessionId: string): Promise<void> {
  await post("info", "", {
    title: `🔁 Continuando — ${task.id}`,
    fields: [
      { name: "Tarefa",  value: task.description,                       inline: false },
      { name: "Motivo",  value: "Atingiu limite de turnos, vai retomar", inline: false },
      { name: "Sessão",  value: `\`${sessionId.slice(0, 20)}…\``,       inline: true  },
    ],
  });
}

/** Task failed and will be retried */
export async function notifyTaskRetry(task: Task, attempt: number, totalRetries: number, error: string): Promise<void> {
  await post("retry", "", {
    title: `🔁 Retry ${attempt}/${totalRetries} — ${task.id}`,
    fields: [
      { name: "Tarefa", value: task.description,                 inline: false },
      { name: "Erro",   value: `\`\`\`${error.slice(0, 200)}\`\`\``, inline: false },
    ],
  });
}

/** Task blocked after exhausting retries */
export async function notifyTaskStuck(task: Task, attempts: number, totalRetries: number, error: string): Promise<void> {
  await post("stuck", "", {
    title: `🆘 Travada — ${task.id}`,
    fields: [
      { name: "Tarefa",      value: task.description,                   inline: false },
      { name: "Tentativas",  value: `${attempts} / ${totalRetries}`,    inline: true  },
      { name: "Último erro", value: `\`\`\`${error.slice(0, 300)}\`\`\``, inline: false },
      { name: "Ação",        value: "Movida para `[⚠]`. Análise humana necessária.", inline: false },
    ],
  });
}

/** Backlog empty — agent is idle */
export async function notifyIdle(
  cycles: number,
  provider: string,
  fetched: number,
  context?: string,
): Promise<void> {
  const fetchedLabel = fetched === 0
    ? "Nenhuma encontrada"
    : `${fetched} encontrada${fetched > 1 ? "s" : ""} (todas em progresso ou bloqueadas)`;

  await post("waiting", "", {
    title: "💤 Sem tarefas pendentes",
    fields: [
      { name: "Provider",          value: `\`${provider}\``,  inline: true  },
      { name: "Consultadas",       value: fetchedLabel,        inline: true  },
      { name: "Ciclos executados", value: `${cycles}`,         inline: true  },
      ...(context ? [{ name: "Filtro", value: `\`${context}\``, inline: false }] : []),
    ],
  });
}

/** Agent shutting down */
export async function notifyShutdown(signal: string, cycles: number): Promise<void> {
  await post("warning", "", {
    title: `⚠️ Encerrando — ${process.env.MACHINE_NAME ?? "agent"}`,
    fields: [
      { name: "Sinal",             value: `\`${signal}\``, inline: true  },
      { name: "Ciclos executados", value: `${cycles}`,     inline: true  },
    ],
  });
}

/** Heartbeat — only pings healthcheck.io, no Discord spam */
export async function sendHeartbeat(task?: string): Promise<void> {
  const pingUrl = process.env.HEALTHCHECK_PING_URL;
  if (pingUrl) {
    await fetch(pingUrl).catch(() => {});
  }
  // Discord heartbeat only if explicitly enabled via HEARTBEAT_DISCORD=1
  if (process.env.HEARTBEAT_DISCORD === "1") {
    const machine  = process.env.MACHINE_NAME ?? "agent";
    const taskInfo = task ? `\`${task}\`` : "ocioso";
    await post("info", "", {
      title: `💓 Vivo — ${machine}`,
      fields: [{ name: "Trabalhando em", value: taskInfo, inline: true }],
    });
  }
}

/** Generic send (used by discord-mcp.ts tool and legacy callers) */
export async function sendToDiscord(message: string, status: StatusType, title?: string): Promise<void> {
  await post(status, message, { title });
}
