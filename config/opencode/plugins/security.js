const BLOCKED_PATTERNS = [
  /\.env/,
  /\.env\./,
  /\/secrets\//,
  /\/secret\//,
  /\.pem$/,
  /\.key$/,
  /\.p12$/,
  /\.pfx$/,
  /\.jks$/,
  /id_rsa/,
  /id_ed25519/,
  /id_ecdsa/,
  /\.netrc$/,
  /\.npmrc/,
  /\.pypirc$/,
  /credentials$/,
  /credentials\.json/,
  /service\.account/,
  /serviceaccount/,
  /\.aws\/credentials/,
  /\.aws\/config/,
  /kubeconfig/,
  /\.kube\/config/,
  /terraform\.tfvars/,
  /\.tfvars$/,
  /vault\.hcl/,
  /auth\.json$/,
  /token\.json$/,
  /client_secret/,
]

const FILE_TOOLS = [
  "read",
  "view",
  "edit",
  "create",
  "write",
  "str_replace",
  "insert",
  "webfetch",
  "websearch",
  "codesearch",
  "external_directory",
  "doom_loop",
]

export const SecurityPlugin = async ({ $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = input.tool
      const args = output?.args || input?.args || {}

      if (FILE_TOOLS.includes(tool)) {
        const targetPath = args?.filePath || args?.path || args?.file || args?.url || ""
        for (const pattern of BLOCKED_PATTERNS) {
          if (pattern.test(targetPath)) {
            throw new Error(
              `Secret file access blocked. Path matched pattern: ${pattern.source}. ` +
              "Do not attempt to read, write, or reference this file."
            )
          }
        }
      }

      if (tool === "bash") {
        const cmd = args?.command || ""
        for (const pattern of BLOCKED_PATTERNS) {
          if (pattern.test(cmd)) {
            throw new Error(
              `Shell command references secret file path (pattern: ${pattern.source}). Blocked by security plugin.`
            )
          }
        }

        if (cmd.includes("compact")) {
          const status = await $`git status --porcelain`.nothrow().text()
          if (status.trim().length > 0) {
            throw new Error(
              "Cannot compact with uncommitted changes. Commit or restore all changes first."
            )
          }
        }
      }
    },
  }
}
