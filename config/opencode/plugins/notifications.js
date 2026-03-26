function firstNonEmpty(...values) {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) return value
  }
  return ""
}

async function sendNotification($, title, message) {
  const escapedTitle = title.replace(/"/g, "'")
  const escapedMessage = message.replace(/"/g, "'")

  if (process.platform === "darwin") {
    await $`osascript -e 'display notification "${escapedMessage}" with title "${escapedTitle}"'`.nothrow()
    return
  }

  if (process.platform === "linux") {
    await $`notify-send ${title} ${message}`.nothrow()
    return
  }

  if (process.platform === "win32") {
    await $`powershell -NoProfile -Command "Write-Host '${escapedTitle}: ${escapedMessage}'"`.nothrow()
    return
  }

  console.log(`[${title}] ${message}`)
}

export const NotificationsPlugin = async ({ $ }) => {
  return {
    "permission.asked": async (input) => {
      const message = firstNonEmpty(
        input?.message,
        input?.permission?.reason,
        input?.permission?.tool,
        "Permission requested"
      )
      await sendNotification($, "OpenCode", message)
    },
    "session.idle": async () => {
      await sendNotification($, "OpenCode", "Session completed")
    },
  }
}
