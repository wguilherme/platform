/**
 * config.ts — Runtime configuration
 *
 * Reads all env vars once at startup. All other modules import Config
 * instead of reading process.env directly.
 */

import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { readFileSync, existsSync } from "fs";

const CLAUDIN_DIR = dirname(resolve(fileURLToPath(import.meta.url), ".."));

export class Config {
  // ── Paths ──────────────────────────────────────────────────────────────────
  readonly claudinDir: string  = CLAUDIN_DIR;
  readonly projectDir: string  = resolve(CLAUDIN_DIR, "..");
  readonly sessionFile: string = resolve(CLAUDIN_DIR, "health", ".agent_session");
  readonly claudeMd: string    = resolve(CLAUDIN_DIR, "CLAUDE.md");

  // ── Loop tuning ────────────────────────────────────────────────────────────
  readonly maxTurns:    number  = parseInt(process.env.MAX_TURNS_PER_TASK      ?? "40");
  readonly sleepMs:     number  = parseInt(process.env.SLEEP_BETWEEN_CYCLES_MS ?? "10000");
  readonly retryLimit:  number  = parseInt(process.env.RETRY_LIMIT             ?? "3");
  readonly hbInterval:  number  = parseInt(process.env.HEARTBEAT_INTERVAL_MS   ?? "300000");

  // ── Runtime flags ──────────────────────────────────────────────────────────
  readonly dryRun:  boolean = process.env.DRY_RUN === "1";
  readonly machine: string  = process.env.MACHINE_NAME ?? "agent";

  // ── System prompt (loaded once) ────────────────────────────────────────────
  readonly systemPrompt: string = existsSync(this.claudeMd)
    ? readFileSync(this.claudeMd, "utf8")
    : "";
}
