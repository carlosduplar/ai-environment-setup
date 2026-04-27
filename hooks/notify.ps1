param()
$ErrorActionPreference = 'Stop'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$msg = $payload.message
if (-not $msg) { exit 0 }
try {
  $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
  $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
  $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
  $escaped = [System.Security.SecurityElement]::Escape($msg)
  $xml.LoadXml("<toast><visual><binding template=`"ToastText01`"><text id=`"1`">$escaped</text></binding></visual></toast>")
  $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
  [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Windows PowerShell').Show($toast)
} catch {
  Write-Error "Notification failed: $_"
  exit 1
}
exit 0