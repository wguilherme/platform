/**
 * backlog.ts — backlog.md reader/writer
 *
 * Parses and updates `claudin/tasks/backlog.md`.
 * Used as fallback when Trello is not configured.
 */

import { readFileSync, writeFileSync } from "fs";
import type { Task } from "./task.ts";

// Regex for lines like: - [ ] ID-001 | Description | alta
const LINE_RE = /^- \[( |→|x|⚠)\] (\S+) \| (.+?) \| (alta|média|baixa|\S+)(?: \|.*)?$/;

export class BacklogFile {
  constructor(private readonly path: string) {}

  readPendingTasks(): Task[] {
    const lines = this.readLines();
    const tasks: Task[] = [];

    for (const line of lines) {
      const m = line.match(LINE_RE);
      if (!m) continue;
      const [, status, id, description, priority] = m;
      if (status === " ") {
        tasks.push({ id, description: description.trim(), priority: priority.trim() });
      }
    }

    return tasks;
  }

  markInProgress(id: string): void {
    this.updateLine(id, (line) => line.replace(/^- \[ \]/, "- [→]")
      + ` | Iniciada: ${timestamp()}`);
  }

  markDone(id: string, commitHash?: string): void {
    const extra = commitHash ? ` | Commit: ${commitHash}` : "";
    this.updateLine(id, (line) =>
      line
        .replace(/^- \[→\]/, "- [x]")
        .replace(/ \| Iniciada:.*$/, "")
      + ` | Concluída: ${timestamp()}${extra}`
    );
  }

  markBlocked(id: string, reason: string): void {
    this.updateLine(id, (line) =>
      line
        .replace(/^- \[→\]/, "- [⚠]")
        .replace(/^- \[ \]/, "- [⚠]")
        .replace(/ \| Iniciada:.*$/, "")
      + ` | Bloqueada: ${reason.slice(0, 120)}`
    );
  }

  private readLines(): string[] {
    try {
      return readFileSync(this.path, "utf8").split("\n");
    } catch {
      return [];
    }
  }

  private updateLine(id: string, transform: (line: string) => string): void {
    const lines = this.readLines();
    const updated = lines.map((line) => {
      const m = line.match(LINE_RE);
      if (m && m[2] === id) return transform(line);
      return line;
    });
    writeFileSync(this.path, updated.join("\n"), "utf8");
  }
}

function timestamp(): string {
  return new Date().toLocaleString("pt-BR", {
    timeZone: "America/Sao_Paulo",
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
}
