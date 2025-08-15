[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
	# get the inputs
	[string]$RepositoryURL = Get-VstsInput -Name RepositoryURL
	[string]$RepositoryPath = Get-VstsInput -Name RepositoryPath
	[string]$Branch = Get-VstsInput -Name Branch
	[bool]$Clean = Get-VstsInput -Name Clean -AsBool
	[string]$Depth = Get-VstsInput -Name Depth
	
	# import the helpers
	. "$PSScriptRoot\GitDownloader.ps1"

	Save-GitRepository -RepositoryURL $RepositoryURL -RepositoryPath $RepositoryPath -Branch $Branch -Clean $Clean -Depth $Depth
}
finally {
	Trace-VstsLeavingInvocation $MyInvocation
}