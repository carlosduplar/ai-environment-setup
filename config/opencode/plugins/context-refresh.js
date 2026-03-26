import { existsSync } from "node:fs"

const CRITICAL_FILES = [
  "~/.claude/CLAUDE.md",
  "~/.claude/ARCHITECTURE.md",
  "~/.claude/STYLE_GUIDE.md",
  "~/.claude/rules.md",
]

function resolveHome(file) {
  const home = process.env.HOME || process.env.USERPROFILE || ""
  return file.replace("~", home)
}

export const ContextRefreshPlugin = async () => {
  return {
    "experimental.session.compacting": async (_input, output) => {
      const available = CRITICAL_FILES.filter((file) => existsSync(resolveHome(file)))
      if (available.length === 0) return

      output.context.push(
        [
          "## Context Memory Refresh",
          "Critical reference files available on this machine:",
          ...available.map((file) => `- ${file}`),
          "",
          "If relevant, re-open these files after compaction before making high-impact changes.",
        ].join("\n")
      )
    },
    "session.compacted": async () => {
      const available = CRITICAL_FILES.filter((file) => existsSync(resolveHome(file)))
      if (available.length > 0) {
        console.log(`Context Memory Refresh: ${available.length} critical files available`)
      }
    },
  }
}
