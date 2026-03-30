// Log all permission requests to build auto-allow lists
// Logs to: ~/.config/opencode/permission-log.jsonl

import { appendFile } from "fs/promises"
import { homedir } from "os"
import { join } from "path"

const LOG_FILE = join(homedir(), ".config", "opencode", "permission-log.jsonl")

export const PermissionLoggerPlugin = async ({ $ }) => {
  return {
    "permission.asked": async (input) => {
      const timestamp = new Date().toISOString()
      const tool = input?.permission?.tool || "unknown"
      const command = input?.args?.command || input?.args?.filePath || ""
      const reason = input?.permission?.reason || ""
      
      const logEntry = {
        timestamp,
        tool,
        command: command.slice(0, 200), // Truncate long commands
        reason: reason.slice(0, 500),
        approved: true // You manually approved this
      }
      
      await appendFile(LOG_FILE, JSON.stringify(logEntry) + "\n").catch(() => {})
    },
  }
}
