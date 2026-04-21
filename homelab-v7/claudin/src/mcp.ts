/**
 * mcp.ts — MCP server config builder
 *
 * Pure function: receives provider name + config, returns the MCP servers
 * map consumed by the Agent SDK query() call.
 *
 * Discord MCP: always included when DISCORD_WEBHOOK_URL is set.
 * JIRA MCP:    only when providerName === "mcp-jira".
 */

import { resolve } from "path";
import { existsSync } from "fs";
import type { Config } from "./config.ts";

type McpServers = Record<string, {
  command: string;
  args: string[];
  env: Record<string, string>;
}>;

export function buildMcpConfig(providerName: string, cfg: Config): McpServers | undefined {
  const servers: McpServers = {};

  const discordMcp = resolve(cfg.claudinDir, "channels", "discord-mcp.ts");
  if (existsSync(discordMcp) && process.env.DISCORD_WEBHOOK_URL) {
    servers["claudin-discord"] = {
      command: "bun",
      args: ["run", discordMcp],
      env: {
        DISCORD_WEBHOOK_URL:  process.env.DISCORD_WEBHOOK_URL ?? "",
        HEALTHCHECK_PING_URL: process.env.HEALTHCHECK_PING_URL ?? "",
        MACHINE_NAME: cfg.machine,
      },
    };
  }

  if (providerName === "jira" || providerName === "mcp-jira") {
    const jiraMcp = resolve(cfg.claudinDir, "channels", "jira-mcp.ts");
    servers["claudin-jira"] = {
      command: "bun",
      args: ["run", jiraMcp],
      env: {
        JIRA_BASE_URL:  process.env.JIRA_BASE_URL  ?? "",
        JIRA_EMAIL:     process.env.JIRA_EMAIL      ?? "",
        JIRA_API_TOKEN: process.env.JIRA_API_TOKEN  ?? "",
        JIRA_PROJECT:   process.env.JIRA_PROJECT    ?? "",
      },
    };
  }

  return Object.keys(servers).length > 0 ? servers : undefined;
}
