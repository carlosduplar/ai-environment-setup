# hooks/notification.ps1
# Hook 3: Desktop Notifications
# Fires a native desktop alert when Claude needs user permission

$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$message = $inputData.message

if ($message) {
	try {
		if (Get-Command BurntToast -ErrorAction SilentlyContinue) {
			New-BurntToastNotification -Title "Claude Code" -Message $message
		} else {
			$script = @"
`$xml = @'
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">Claude Code</text>
            <text id="2">$message</text>
        </binding>
    </visual>
</toast>
'@
Windows.UI.Notifications.ToastNotificationManager.CreateToastNotifier("Claude Code").Show([Windows.UI.Notifications.ToastNotification]::new([Windows.Data.Xml.Dom.XmlDocument]::new()"))
"@
			Add-Type -AssemblyName System.Runtime.WindowsRuntime
			$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
			$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]
		}
	} catch {
		Write-Host "Notification: $message"
	}
}

exit 0