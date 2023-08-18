class AxiomLogger {
	hidden [System.Collections.ArrayList]$logsBatch
	hidden [DateTime]$lastSent
	hidden [string]$tags
	hidden [int]$flushAfterSeconds
	hidden [int]$flushAfterLogs
	hidden [string]$ingestUri
	hidden [object]$ingestHeaders

	AxiomLogger([string]$apiToken, [string]$dataSetName, $tags = @{}) {
		if ($null -eq $apiToken) {
			Write-Error '$apiToken is required in AxiomLogger!'
		}
		if ($null -eq $dataSetName) {
			Write-Error '$dataSetName is required in AxiomLogger!'
		}
		$this.logsBatch = [System.Collections.ArrayList]::new()
		$this.lastSent = (Get-Date)
		$this.ingestURI = "https://api.axiom.co/v1/datasets/$($dataSetName)/ingest"
		$this.ingestHeaders = @{"Authorization" = "Bearer $($apiToken)" }
		$this.flushAfterSeconds = 10
		$this.flushAfterLogs = 20
        $this.tags = $tags
	}

	[AxiomLogger] FlushAfterSeconds([int]$seconds) {
		$this.flushAfterSeconds = $seconds
		return $this
	}

	[AxiomLogger] FlushAfterLogs([int]$count) {
		$this.flushAfterLogs = $count
		return $this
	}

	[void] sendLogs() {
		$now = (Get-Date)
		$timeSinceFlush = ($now - $this.lastSent).TotalSeconds
		if ($this.logsBatch.Count -ge $this.flushAfterLogs -or 
			$timeSinceFlush -ge $this.flushAfterSeconds) {
			$batchJson = (ConvertTo-Json -Depth 100 -Compress $this.logsBatch)
			try {
				Invoke-RestMethod -Uri $this.ingestUri `
					-Method Post `
					-Headers $this.ingestHeaders `
					-ContentType "application/json" `
					-Body $batchJson `
					-ErrorAction:Stop | Out-Null

				$this.logsBatch.Clear()
				$this.lastSent = $now
			} catch {
				# Hopefully it will work next time
				Write-Warning "Failed to send logs: $_"
			}
		}
	}

	[void] Flush() {
		$current = $this.flushAfterLogs
		$this.flushAfterLogs = 1
		$this.sendLogs()
		$this.flushAfterLogs = $current
	}

	[void] Log([object]$data) {
		$log = @{
			"_time" = (Get-Date -Format 'o' -AsUTC)
			"data"  = ($data)
			"tags"  = $this.tags
		}
		$this.logsBatch.Add($log)
		$this.sendLogs()
	}
}

Function New-AxiomLogger {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true)]
		[string]$ApiToken,
		[Parameter(Mandatory = $true)]
		[string]$DataSetName,
		[object]$Tags
	)

	return [AxiomLogger]::new($ApiToken, $DataSetName, $Tags)
}

Export-ModuleMember New-AxiomLogger
