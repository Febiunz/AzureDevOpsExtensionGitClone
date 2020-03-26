Function Get-EnvironmentVariable {
    param([string]$Name)
    Return [Environment]::GetEnvironmentVariable($Name)
}

Function Get-GitRepositoryUri {
    $VstsUri = Get-EnvironmentVariable -Name 'SYSTEM_TEAMFOUNDATIONCOLLECTIONURI'
    $TeamProject = Get-EnvironmentVariable -Name 'SYSTEM_TEAMPROJECT'
    $Uris =  @($VstsUri, $TeamProject, '_git') | %{ $_.Trim('/') }
    Return $Uris -join '/'
}

Function Get-GitDirectory {
    $AgentBuildDir = Get-EnvironmentVariable -Name 'AGENT_BUILDDIRECTORY'
    $AgentReleaseDir = Get-EnvironmentVariable -Name 'AGENT_RELEASEDIRECTORY'
	If (-not ([string]::IsNullOrWhiteSpace($AgentBuildDir)) -and (Test-Path -Path $AgentBuildDir -PathType Container)) {
		$Directory = $AgentBuildDir
	} ElseIf (-not ([string]::IsNullOrWhiteSpace($AgentReleaseDir)) -and (Test-Path $AgentReleaseDir -PathType Container)) {
		$Directory = $AgentReleaseDir
	}

	Return ([System.IO.Path]::Combine($Directory, 's'))
}

Function Get-GitBranchExists {
    param([string]$branch_name)

    Write-Host "Checking if branch exists: $branch_name"

    $hash = (git rev-parse --verify --quiet origin/$branch_name)
    If (-not ([string]::IsNullOrEmpty($hash))) {
        Write-Host "Branch exists: $branch_name"
        Return $true
    }
    Write-Host "Branch does not exist: $branch_name"
    Return $false
}

Function Invoke-VerboseCommand {
    param(
        [ScriptBlock]$Command,
        [string] $StderrPrefix = "",
        [int[]]$AllowedExitCodes = @(0,128)
    )
    $Script = $Command.ToString()
    $Captures = Select-String '\$(\w+)' -Input $Script -AllMatches
    ForEach ($Capture in $Captures.Matches) {
        $Variable = $Capture.Groups[1].Value
        $Value = Get-Variable -Name $Variable -ValueOnly
        $Script = $Script.Replace("`$$($Variable)", $Value)
    }
    Write-Host $Script.Trim()
    If ($script:ErrorActionPreference -ne $null) {
        $backupErrorActionPreference = $script:ErrorActionPreference
    } ElseIf ($ErrorActionPreference -ne $null) {
        $backupErrorActionPreference = $ErrorActionPreference
    }
    $script:ErrorActionPreference = "Continue"
    try
    {
        & $Command 2>&1 | ForEach-Object -Process `
        {
            if ($_ -is [System.Management.Automation.ErrorRecord])
            {
                "$StderrPrefix$_"
            }
            else
            {
                "$_"
            }
        }
        if ($AllowedExitCodes -notcontains $LASTEXITCODE)
        {
            throw "Execution failed with exit code $LASTEXITCODE"
        }
    }
    finally
    {
        $script:ErrorActionPreference = $backupErrorActionPreference
    }
}

Function Update-GitRepository {
    param(
        [string]$Path,
        [string]$Branch,
        [string]$FallbackBranch,
        [string]$BaseBranch
    )

    Write-Host "Updating repository in $Path"
    Set-Location $Path | Out-Null
    Invoke-VerboseCommand -Command { git fetch origin }

    $branch_to_update = ""
    If (Get-GitBranchExists -branch_name $Branch) {
        $branch_to_update = $Branch
    }
    ElseIf (Get-GitBranchExists -branch_name $FallbackBranch) {
        $branch_to_update = $FallbackBranch
    }
    ElseIf (Get-GitBranchExists -branch_name $BaseBranch) {
        $branch_to_update = $BaseBranch
    }
    Else{
        throw "Execution failed: Branches not found on remote"
	}

    $SystemToken = Get-EnvironmentVariable -Name 'SYSTEM_ACCESSTOKEN'
    Invoke-VerboseCommand -Command { git config credential.interactive never }

    Invoke-VerboseCommand -Command { git reset --hard origin/$branch_to_update }
    Invoke-VerboseCommand -Command { git -c http.extraheader="Authorization: bearer $SystemToken" pull origin $branch_to_update }
}

Function Clone-GitRepository {
    param(
        [string]$Path,
        [string]$Uri,
        [string]$Branch,
        [string]$FallbackBranch,
        [string]$BaseBranch
    )

    # try to use token provided by server
    $SystemToken = Get-EnvironmentVariable -Name 'SYSTEM_ACCESSTOKEN'

    Write-Host "Try cloning $Uri with branch '$Branch' into $Path"
    Invoke-VerboseCommand -Command { git -c http.extraheader="Authorization: bearer $SystemToken" clone --progress -b $Branch "$Uri" "$Path" }
    If ($LastExitCode -ne 0) {
        if ($LastExitCode -eq 128){
            Write-Host "Try cloning $Uri with branch '$FallbackBranch' into $Path"
            Invoke-VerboseCommand -Command { git -c http.extraheader="Authorization: bearer $SystemToken" clone --progress -b $FallbackBranch "$Uri" "$Path" }
		}
        If ($LastExitCode -ne 0) {
            if ($LastExitCode -eq 128){
                Write-Host "Try cloning $Uri with branch '$BaseBranch' into $Path"
                Invoke-VerboseCommand -Command { git -c http.extraheader="Authorization: bearer $SystemToken" clone --progress -b $BaseBranch "$Uri" "$Path" }
		    }
        }
        If ($LastExitCode -ne 0) {
            Write-Error $output -ErrorAction Stop
        }
    }
}

Function Save-GitRepository {
    [CmdletBinding()]
    param(
        # repository name
        [string]
        [parameter(mandatory=$true)]
        $RepositoryURL,
    
        # the root directory to store all git repositories
        [string]
        [parameter(mandatory=$false)]
        $RepositoryPath,
    
        # branch name to checkout
        [parameter(mandatory=$false)]
        [string]
        $Branch = 'master',

        # fallback branch name to checkout
        [parameter(mandatory=$false)]
        [string]
        $FallbackBranch = 'master',
        
        # base branch name to checkout
        [parameter(mandatory=$false)]
        [string]
        $BaseBranch = 'master',

        # determine whether to clean the folder before downloading the repository or not (default: false)
        [parameter(mandatory=$false)]
        [string]
        [ValidateSet('true', 'false', 'yes', 'no')]
        $Clean = 'false'
    )
    try {
        # try to find git in PATH environment
        Get-Command -Name git -CommandType Application -ErrorAction Stop | Out-Null
    } catch [System.Management.Automation.CommandNotFoundException] {
        # try to find git in default location
        If (-not (Test-Path -Path "$($env:ProgramFiles)\Git\bin\git.exe" -PathType Leaf)) {
            Write-Error "Git command line not found or not installed" -ErrorAction Stop
        }
        Set-Alias -Name git -Value $env:ProgramFiles\Git\bin\git.exe -Force | Out-Null
    }

    $GitRepositoryUri = Get-GitRepositoryUri
    Write-Host "##vso[task.setvariable variable=Build.Repository.GitUri]$GitRepositoryUri"
    $RepositoryURL = $RepositoryURL -replace ([regex]::Escape('$(Build.Repository.GitUri)')), $GitRepositoryUri
    
    $GitDirectory = Get-GitDirectory
    Write-Host "##vso[task.setvariable variable=Build.GitDirectory]$GitDirectory"
    If ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
        $captured = [regex]::Match($RepositoryURL, '^(\w+:)?(?<separator>/|\\){1,2}')
        $Separator = '/'
        If ($captured.Success) {
            $Separator = $captured.Groups['separator'].Value[0]
        }
        # set default repository path
        $RepositoryName = $RepositoryURL.Substring($RepositoryURL.TrimEnd($Separator).LastIndexOf($Separator) + 1)
        $RepositoryPath = "`$(Build.GitDirectory)\$RepositoryName"
    }
    $RepositoryPath = $RepositoryPath -replace ([regex]::Escape('$(Build.GitDirectory)')), $GitDirectory

    # ensure containing git folder exists
    $RepositoryFolder = [System.IO.Path]::GetDirectoryName($RepositoryPath)
    If (-not (Test-Path -Path "$RepositoryFolder" -PathType Container)) {
        Write-Host "Creating git folder $RepositoryFolder"
        New-Item -Path "$RepositoryFolder" -ItemType Directory -Force | Out-Null
    }

    $CurrentDirectory = (Get-Location).Path
    If (Test-Path -Path "$RepositoryPath" -PathType Container) {
        If (@('true', 'yes').Contains($Clean.ToLower())) {
            Write-Host "Cleaning git folder $RepositoryPath"
            Remove-Item -Path "$RepositoryPath" -Recurse -Force | Out-Null
            Clone-GitRepository -Path "$RepositoryPath" -Uri "$RepositoryURL" -Branch $Branch -FallbackBranch $FallbackBranch -BaseBranch $BaseBranch
        }
        Else {
            Update-GitRepository -Path "$RepositoryPath" -Branch $Branch -FallbackBranch $FallbackBranch -BaseBranch $BaseBranch
        }
    }
    Else {
        Clone-GitRepository -Path "$RepositoryPath" -Uri "$RepositoryURL" -Branch $Branch -FallbackBranch $FallbackBranch -BaseBranch $BaseBranch
    }

    Set-Location "$CurrentDirectory"
}