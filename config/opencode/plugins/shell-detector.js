export const ShellDetector = async ({ project, client, $, directory, worktree }) => {
  // Detect environment at plugin load time
  const isWindows = process.platform === "win32";
  const isPowerShell = !!process.env.PSModulePath || process.env.TERM === "xterm-256color";
  const shellType = isWindows ? (isPowerShell ? "powershell" : "cmd") : "bash";
  
  return {
    "session.created": async (input, output) => {
      // Inject shell environment info into the session context
      output.env = {
        ...output.env,
        OPENCODE_SHELL_TYPE: shellType,
        OPENCODE_PLATFORM: process.platform,
      };
      
      // Log the detected environment
      await client.app.log({
        body: {
          service: "shell-detector",
          level: "info",
          message: `Session started with shell: ${shellType} on ${process.platform}`,
        },
      });
    },
    
    "shell.env": async (input, output) => {
      // Ensure all shell executions know the detected shell type
      output.env.OPENCODE_SHELL_TYPE = shellType;
      output.env.OPENCODE_PLATFORM = process.platform;
    },
  };
};
