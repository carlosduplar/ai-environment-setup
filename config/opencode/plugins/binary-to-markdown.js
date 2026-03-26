import { existsSync } from "node:fs"
import path from "node:path"
import { spawnSync } from "node:child_process"

const SUPPORTED_EXTENSIONS = new Set([
  ".pdf",
  ".docx",
  ".xlsx",
  ".xls",
  ".pptx",
  ".ppt",
  ".epub",
  ".ipynb",
])

function resolveConverterPath() {
  if (process.env.BINARY_TO_MARKDOWN_CONVERTER) {
    return process.env.BINARY_TO_MARKDOWN_CONVERTER
  }

  const localPath = path.resolve(process.cwd(), "hooks", "binary-to-markdown", "convert.py")
  if (existsSync(localPath)) {
    return localPath
  }

  return ""
}

function runConverter(converterPath, filePath) {
  const candidates = ["python3", "python"]

  for (const cmd of candidates) {
    const result = spawnSync(cmd, [converterPath, filePath], {
      encoding: "utf8",
    })

    if (result.error && result.error.code === "ENOENT") {
      continue
    }

    return {
      command: cmd,
      status: result.status ?? 1,
      stdout: result.stdout || "",
      stderr: result.stderr || "",
    }
  }

  return {
    command: "",
    status: 1,
    stdout: "",
    stderr: "python3/python not found in PATH",
  }
}

export const BinaryToMarkdownPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool || "").toLowerCase()
      if (tool !== "read") {
        return
      }

      const args = output?.args || input?.args || {}
      const filePath = String(args?.filePath || args?.path || args?.file || "")
      if (!filePath) {
        return
      }

      const extension = path.extname(filePath).toLowerCase()
      if (!SUPPORTED_EXTENSIONS.has(extension)) {
        return
      }

      const converterPath = resolveConverterPath()
      if (!converterPath) {
        console.warn("[binary-to-markdown] Converter not found. Set BINARY_TO_MARKDOWN_CONVERTER or keep hooks/binary-to-markdown/convert.py in the repo.")
        return
      }

      const result = runConverter(converterPath, filePath)
      const fileName = path.basename(filePath)

      if (result.status === 0) {
        const markdown = result.stdout
        throw new Error(
          `[binary-to-markdown] Converted \`${fileName}\` -> Markdown\n\n${markdown}`
        )
      }

      if (result.stderr.trim().length > 0) {
        console.warn(`[binary-to-markdown] Conversion stderr: ${result.stderr.trim()}`)
      }
      throw new Error(
        `[binary-to-markdown] Conversion failed for \`${fileName}\`. See stderr for details.`
      )
    },
  }
}