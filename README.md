# axiom-powershell
A PowerShell module for [Axiom.co](https://axiom.co/)

## Examples

### Log a message

```powershell
Import-Module $PSScriptRoot/AxiomLogger.psm1

$logger = New-AxiomLogger `
	-ApiToken $env:AXIOM_TOKEN `
	-DataSetName 'mini-backups' `
	-Tags @{
		"server" = "mini"
		"source" = "backup.ps1"
	}

# Optionally set custom flush settings
$logger.FlushAfterSeconds(5) # default 10
$logger.FlushAfterLogs(10) # Default 20

# Log some data
$logger.Log(@{
	"message" = "Backup started"
	"level" = "info"
})

# ... do some work

$logger.Flush() # Flush remaining logs
```

### Pipe rclone logs into Axiom

```powershell
Import-Module $PSScriptRoot/AxiomLogger.psm1

rclone --use-json-log copy ./ ../tmp --dry-run 2>&1 | ForEach-Object {
	if ($_.ToString().StartsWith('{"level":')) {
		# Send json logs directly to Axiom
		$logger.Log((ConvertFrom-Json $_))
	} else {
		# Send non-json logs as info
		$logger.Log(@{
				"msg"   = $_
				"level" = "info"
			})
	}
}
