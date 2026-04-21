#!/usr/bin/env bun
/**
 * main.ts — Claudin entry point
 *
 * Composition root: wires Config → TaskExecutor → AgentLoop, then runs.
 *
 * Usage:
 *   bun run claudin/src/main.ts
 *   make start-loop
 *   DRY_RUN=1 make test-loop
 */

import { spawnSync } from "child_process";
import { resolve } from "path";

import { Config }             from "./config.ts";
import { TaskExecutor }       from "./executor.ts";
import { AgentLoop }          from "./loop.ts";
import { createTaskProvider } from "../lib/providers/index.ts";
import { SessionStore }       from "../lib/session-store.ts";
import { notifyShutdown, sendHeartbeat } from "../lib/discord.ts";

// ── Bootstrap ─────────────────────────────────────────────────────────────────
const cfg      = new Config();
const provider = await createTaskProvider();
const store    = new SessionStore(cfg.sessionFile);
const executor = new TaskExecutor(cfg, store, provider.name);
const loop     = new AgentLoop(cfg, executor, provider, store);

function log(msg: string): void {
  const ts = new Date().toLocaleTimeString("pt-BR", { timeZone: "America/Sao_Paulo" });
  process.stdout.write(`[${ts}] ${msg}\n`);
}

// ── Signal handlers ───────────────────────────────────────────────────────────
async function shutdown(sig: string): Promise<void> {
  if (loop.shuttingDown) return;
  loop.shuttingDown = true;
  log(`Received ${sig} — shutting down`);
  await notifyShutdown(sig, loop.totalCycles).catch(() => {});
  process.exit(0);
}

process.on("SIGINT",  () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

// ── Heartbeat timer ───────────────────────────────────────────────────────────
function heartbeat(task?: string): void {
  spawnSync("bash", [resolve(cfg.claudinDir, "health", "heartbeat.sh")], {
    stdio: "inherit",
    env: { ...process.env },
  });
  sendHeartbeat(task).catch(() => {});
}

setInterval(() => heartbeat(), cfg.hbInterval);

// ── Startup ───────────────────────────────────────────────────────────────────
log(`Claudin starting (machine: ${cfg.machine}, max_turns: ${cfg.maxTurns}, retries: ${cfg.retryLimit})`);
log(`Task provider: ${provider.name}`);
log(`Dry run: ${cfg.dryRun}`);

spawnSync("bash", [resolve(cfg.claudinDir, "health", "startup-notify.sh")], {
  stdio: "inherit",
  env: { ...process.env },
});

// ── Main loop ─────────────────────────────────────────────────────────────────
while (!loop.shuttingDown) {
  try {
    await loop.runCycle();
  } catch (err) {
    await loop.handleUnhandledError(err);
  }
}
