# axiom-powershell
A PowerShell module for [Axiom.co](https://axiom.co/)

## Example

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
