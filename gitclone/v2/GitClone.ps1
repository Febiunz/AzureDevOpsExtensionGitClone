[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
	# get the inputs
	[string]$RepositoryURL = Get-VstsInput -Name RepositoryURL
	[string]$RepositoryPath = Get-VstsInput -Name RepositoryPath
	[string]$Branch = Get-VstsInput -Name Branch
	[string]$FallbackBranch = Get-VstsInput -Name FallbackBranch
	[string]$BaseBranch = Get-VstsInput -Name BaseBranch
	[bool]$Clean = Get-VstsInput -Name Clean -AsBool
	[string]$Depth = Get-VstsInput -Name Depth
	
	# import the helpers
	. "$PSScriptRoot\GitDownloader.ps1"

	Save-GitRepository -RepositoryURL $RepositoryURL -RepositoryPath $RepositoryPath -Branch $Branch -FallbackBranch $FallbackBranch -BaseBranch $BaseBranch -Clean $Clean -Depth $Depth
}
finally {
	Trace-VstsLeavingInvocation $MyInvocation
}