#!/usr/bin/env bun
/**
 * Claudin Discord MCP Server
 *
 * Servidor MCP que expõe ferramentas para o agente Claude Code
 * enviar mensagens e alertas para o Discord via webhook.
 *
 * Uso: bun run claudin/channels/discord-mcp.ts
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;
const MACHINE_NAME = process.env.MACHINE_NAME || "agent";

if (!DISCORD_WEBHOOK_URL) {
  process.stderr.write(
    "DISCORD_WEBHOOK_URL environment variable is required\n",
  );
  process.exit(1);
}

type StatusType =
  | "success"
  | "stuck"
  | "waiting"
  | "warning"
  | "question"
  | "info";

const STATUS_COLORS: Record<StatusType, number> = {
  success: 0x00c853, // verde
  stuck: 0xd50000, // vermelho
  waiting: 0xff6d00, // laranja
  warning: 0xffd600, // amarelo
  question: 0x2962ff, // azul
  info: 0x546e7a, // cinza
};

const STATUS_EMOJIS: Record<StatusType, string> = {
  success: "✅",
  stuck: "🆘",
  waiting: "💤",
  warning: "⚠️",
  question: "❓",
  info: "ℹ️",
};

async function sendToDiscord(
  message: string,
  status: StatusType,
  title?: string,
): Promise<void> {
  const emoji = STATUS_EMOJIS[status];
  const color = STATUS_COLORS[status];
  const embedTitle = title || `${emoji} Claudin — ${status.toUpperCase()}`;

  const payload = {
    username: `Claudin (${MACHINE_NAME})`,
    embeds: [
      {
        title: embedTitle,
        description: message,
        color,
        timestamp: new Date().toISOString(),
        footer: {
          text: `🤖 ${MACHINE_NAME} · ${new Date().toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" })}`,
        },
      },
    ],
  };

  const response = await fetch(DISCORD_WEBHOOK_URL!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(
      `Discord webhook failed: ${response.status} ${response.statusText}`,
    );
  }
}

// ── MCP Server ────────────────────────────────────────────────────────────────

const server = new Server(
  { name: "claudin-discord", version: "1.0.0" },
  {
    capabilities: {
      tools: {},
    },
    instructions: `
      Use estas ferramentas para comunicar com o Discord:
      - send_to_discord: envia mensagem de status (success, stuck, waiting, warning, question, info)
      - send_heartbeat: envia sinal de vida (use a cada tarefa concluída ou a cada 10 min sem atividade)
    `,
  },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "send_to_discord",
      description:
        "Envia uma mensagem de status para o canal Discord do projeto. Use para reportar conclusão de tarefas, problemas, bloqueios ou dúvidas que precisam de decisão humana.",
      inputSchema: {
        type: "object",
        properties: {
          message: {
            type: "string",
            description:
              "Mensagem a ser enviada. Pode usar markdown do Discord.",
          },
          status: {
            type: "string",
            enum: [
              "success",
              "stuck",
              "waiting",
              "warning",
              "question",
              "info",
            ],
            description:
              "success=tarefa concluída, stuck=travado/loop, waiting=sem tarefas, warning=alerta, question=precisa de decisão humana, info=informativo",
          },
          title: {
            type: "string",
            description:
              "Título opcional para o embed. Se omitido, usa o status como título.",
          },
        },
        required: ["message", "status"],
      },
    },
    {
      name: "send_heartbeat",
      description:
        "Envia um sinal de vida silencioso para o sistema de monitoramento. Use a cada tarefa concluída ou a cada 10 minutos sem atividade.",
      inputSchema: {
        type: "object",
        properties: {
          task: {
            type: "string",
            description: "Nome ou descrição breve da tarefa atual (opcional).",
          },
        },
        required: [],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;

  if (name === "send_to_discord") {
    const { message, status, title } = args as {
      message: string;
      status: StatusType;
      title?: string;
    };

    await sendToDiscord(message, status, title);

    return {
      content: [
        {
          type: "text",
          text: `Mensagem enviada ao Discord (status: ${status})`,
        },
      ],
    };
  }

  if (name === "send_heartbeat") {
    const { task } = (args || {}) as { task?: string };

    // Ping para serviço externo de dead man's switch (ex: healthchecks.io)
    const pingUrl = process.env.HEALTHCHECK_PING_URL;
    if (pingUrl) {
      await fetch(pingUrl, { method: "GET" }).catch(() => {
        // Silencioso — não interrompe o agente se o ping falhar
      });
    }

    const taskInfo = task ? ` | Tarefa: ${task}` : "";
    await sendToDiscord(
      `💓 Heartbeat — agente ativo${taskInfo}`,
      "info",
      `💓 Claudin vivo (${MACHINE_NAME})`,
    );

    return {
      content: [{ type: "text", text: "Heartbeat enviado" }],
    };
  }

  throw new Error(`Ferramenta desconhecida: ${name}`);
});

await server.connect(new StdioServerTransport());
