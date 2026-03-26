import { existsSync, readFileSync } from "node:fs"

function countMatches(content, pattern) {
  const matches = content.match(pattern)
  return matches ? matches.length : 0
}

function readPlanSummary() {
  if (!existsSync("PLAN.md")) return null

  const content = readFileSync("PLAN.md", "utf8")
  const done = countMatches(content, /^### \[DONE\]/gm)
  const pending = countMatches(content, /^### \[PENDING\]/gm)
  const blocked = countMatches(content, /^### \[BLOCKED\]/gm)
  const total = done + pending + blocked

  return { done, pending, blocked, total }
}

export const SessionLifecyclePlugin = async ({ $ }) => {
  return {
    "session.created": async () => {
      if (!existsSync("PLAN.md")) {
        console.warn("Session start warning: PLAN.md not found in repo root.")
      }
      if (!existsSync("AGENTS.md")) {
        console.warn("Session start warning: AGENTS.md not found in repo root.")
      }

      const gitStatus = await $`git status --porcelain`.nothrow().text()
      if (gitStatus.trim().length > 0) {
        console.warn("Session start warning: uncommitted changes detected.")
      }
    },
    "session.idle": async () => {
      const summary = readPlanSummary()
      if (!summary) return
      console.log(
        `Session idle summary: ${summary.done}/${summary.total} done | ${summary.pending} pending | ${summary.blocked} blocked`
      )
    },
    "session.deleted": async () => {
      const summary = readPlanSummary()
      if (!summary) return
      console.log(
        `Session end summary: ${summary.done}/${summary.total} done | ${summary.pending} pending | ${summary.blocked} blocked`
      )
    },
  }
}
