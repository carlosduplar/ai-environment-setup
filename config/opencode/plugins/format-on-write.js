import { existsSync } from "node:fs"
import path from "node:path"

const FILE_EDIT_TOOLS = new Set(["edit", "write", "create", "insert", "str_replace"])
const FORMATTABLE_EXTENSIONS = new Set([
  ".js",
  ".ts",
  ".jsx",
  ".tsx",
  ".json",
  ".css",
  ".scss",
  ".html",
  ".vue",
  ".yaml",
  ".yml",
  ".md",
])

function extractPath(output) {
  return (
    output?.result?.path ||
    output?.path ||
    output?.args?.path ||
    output?.args?.filePath ||
    output?.args?.file ||
    ""
  )
}

export const FormatOnWritePlugin = async ({ $ }) => {
  return {
    "tool.execute.after": async (input, output) => {
      const tool = String(input?.tool || "").toLowerCase()
      if (!FILE_EDIT_TOOLS.has(tool)) return

      const filePath = extractPath(output)
      if (!filePath || !existsSync(filePath)) return

      const ext = path.extname(filePath).toLowerCase()
      if (!FORMATTABLE_EXTENSIONS.has(ext)) return

      await $`prettier --write ${filePath}`.nothrow()
    },
  }
}
