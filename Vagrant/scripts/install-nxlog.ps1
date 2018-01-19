# Purpose: Installs nxlog on the host

If (-not (Test-Path "C:\Program Files (x86)\nxlog\nxlog.exe")) {
  Write-Host "Downloading nxlog..."
  $msiFile = $env:Temp + "\nxlog-ce-2.9.1716.msi"

  Write-Host "Installing & Starting nxlog"
  (New-Object System.Net.WebClient).DownloadFile('https://nxlog.co/system/files/products/files/348/nxlog-ce-2.9.1716.msi', $msiFile)
  Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList '/i', "$msiFile", '/quiet' -Wait

  $conf = @"
define ROOT C:\Program Files (x86)\nxlog

Moduledir %ROOT%\modules
CacheDir %ROOT%\data
Pidfile %ROOT%\data\nxlog.pid
SpoolDir %ROOT%\data
LogFile %ROOT%\data\nxlog.log

<Extension json>
	Module xm_json
</Extension>

<Input eventlog>
	Module			im_msvistalog
	FlowControl		FALSE
	SavePos			TRUE
	Query <QueryList>\
		<Query Id="0"> \
			<Select Path="Microsoft-Windows-Sysmon/Operational">*</Select> \
			<Select Path="Application">*</Select> \
			<Select Path="System">*</Select> \
			<Select Path="Security">*</Select> \
		</Query> \
		</QueryList>
</Input>

<Output elasticsearch>
	Module			om_http
	URL			http://192.168.38.5:9200
	ContentType		application/json
	Exec			set_http_request_path(strftime(`$EventTime, "/nxlog-%Y%m%d/" + `$SourceModuleName)); rename_field("timestamp","@timestamp"); to_json();
</Output>

<Route 1>
	Path 			eventlog => elasticsearch
</Route>
"@
  Set-Content -Path "C:\Program Files (x86)\nxlog\conf\nxlog.conf" -Value $conf
  Start-Service nxlog
  
} Else {
  Write-Host "nxlog is already installed. Moving on."
}
Write-Host "nxlog installation complete!"
