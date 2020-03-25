[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
	# get the inputs
	[string]$RepositoryURL = Get-VstsInput -Name RepositoryURL
	[string]$RepositoryPath = Get-VstsInput -Name RepositoryPath
	[string]$Branch = Get-VstsInput -Name Branch
	[bool]$Clean = Get-VstsInput -Name Clean -AsBool
	
	# import the helpers
	. "$PSScriptRoot\GitDownloader.ps1"

	Save-GitRepository -RepositoryURL $RepositoryURL -RepositoryPath $RepositoryPath -Branch $Branch -Clean $Clean
}
finally {
	Trace-VstsLeavingInvocation $MyInvocation
}