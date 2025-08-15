# Azure DevOps Extension Git Repository Clone

Azure DevOps extension written in PowerShell that allows cloning additional Git repositories during pipeline execution. The extension has two versions (v1 and v2) with v2 adding fallback and base branch functionality.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively
- Install the Azure DevOps Extension CLI:
  - `npm install -g tfx-cli` -- takes 45-60 seconds. NEVER CANCEL. Set timeout to 120+ seconds.
- Validate PowerShell script syntax:
  - `pwsh -Command "Get-ChildItem -Path . -Recurse -Include '*.ps1' | ForEach-Object { Write-Host 'Checking:' \$_.FullName; \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content \$_.FullName -Raw), [ref]\$null) }"` -- takes 5-10 seconds.
- Package the extension:
  - `tfx extension create --root . --manifest-globs vss-extension.json` -- takes less than 1 second. Creates febiunz.GitClone-X.X.X.vsix file.
- Clean up generated packages:
  - `rm -f *.vsix` -- Generated VSIX files are excluded from git via .gitignore.

## Validation
- ALWAYS validate PowerShell script syntax before making changes using the syntax validation command above.
- You cannot fully test the extension functionality outside of an Azure DevOps pipeline environment, but you can validate:
  - PowerShell script syntax is correct
  - Extension packages successfully without errors
  - Core PowerShell functions can be loaded (e.g., `pwsh -Command ". ./gitclone/v2/GitDownloader.ps1; Get-EnvironmentVariable -Name 'PATH'"`)
- ALWAYS test packaging after making changes to ensure the extension builds correctly.
- The extension requires Azure DevOps pipeline environment variables that are not available in development environments.

## Common Tasks
The following are validated commands and their expected outputs:

### Repository Structure
```
ls -la /
.devcontainer/          # Development container configuration
.git/                   # Git repository metadata  
.gitignore             # Git ignore rules (includes *.vsix)
LICENSE                # GPL-3.0 license
PRIVACY.md             # Privacy policy
README.md              # Project documentation
gitclone/              # Extension source code
  v1/                  # Version 1 of the extension
    GitClone.ps1       # Main entry point
    GitDownloader.ps1  # Core functionality
    task.json          # Task definition
    ps_modules/        # PowerShell modules (vststasksdk)
  v2/                  # Version 2 with enhanced features
    GitClone.ps1       # Main entry point with fallback branches
    GitDownloader.ps1  # Enhanced core functionality
    task.json          # Enhanced task definition
    ps_modules/        # PowerShell modules (vststasksdk)
icon.png               # Extension icon
vss-extension.json     # Extension manifest
```

### Key Extension Files
- **vss-extension.json**: Extension manifest defining metadata, version (2.4.3), and task contributions
- **gitclone/v1/task.json**: V1 task definition with basic clone functionality
- **gitclone/v2/task.json**: V2 task definition adding FallbackBranch and BaseBranch parameters
- **GitClone.ps1**: Entry point scripts that parse inputs and call GitDownloader functions
- **GitDownloader.ps1**: Core PowerShell logic for git operations

### Extension Differences
- **V1**: Basic git clone with Branch and Clean parameters
- **V2**: Enhanced with FallbackBranch and BaseBranch for better reliability

### tfx-cli Commands
```bash
# Install extension CLI
npm install -g tfx-cli

# Package extension
tfx extension create --root . --manifest-globs vss-extension.json

# Get help
tfx extension --help
```

### PowerShell Validation
```bash
# Validate all PowerShell scripts
pwsh -Command "Get-ChildItem -Path . -Recurse -Include '*.ps1' | ForEach-Object { Write-Host 'Checking:' \$_.FullName; \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content \$_.FullName -Raw), [ref]\$null) }"

# Test function loading
pwsh -Command ". ./gitclone/v2/GitDownloader.ps1; Get-EnvironmentVariable -Name 'PATH'"
```

### Available Tools
- **PowerShell 7.4.10**: Available via `pwsh` command
- **Node.js**: Available for npm package management
- **Git 2.50.1**: Available for basic git operations
- **tfx-cli**: Azure DevOps Extension CLI (install via npm)

## Important Notes
- This is a PowerShell-based extension with NO traditional build system (no npm build, dotnet build, etc.)
- The extension is packaged as a .vsix file for Azure DevOps marketplace
- PowerShell Gallery is not accessible in this environment, so PSScriptAnalyzer is unavailable for advanced linting
- The extension requires Azure DevOps pipeline environment (SYSTEM_ACCESSTOKEN, etc.) to function properly
- Extension functionality cannot be fully tested outside of Azure DevOps pipelines
- Always validate PowerShell syntax and packaging after code changes
- Generated .vsix files are automatically excluded from git commits

## Extension Functionality
The extension allows Azure DevOps pipelines to clone additional git repositories with these features:
- Clone or update git repositories within the same Azure DevOps organization
- Support for branch selection with fallback options (v2)
- Clean mode to force fresh clones
- OAuth token authentication using pipeline system token
- Cross-platform support (Windows/Linux agents)

## Versioning Guidelines
When making changes to the extension, follow these versioning rules:

### Task Version Updates
- **Update task versions when source code is changed** in PowerShell scripts (GitClone.ps1, GitDownloader.ps1)
- Task versions are in `gitclone/v1/task.json` and `gitclone/v2/task.json` under the `version` object
- Follow semantic versioning: increment Minor for new features, Patch for bug fixes

### Extension Version Updates  
- **Update extension version when one of the task versions is updated**
- Extension version is in `vss-extension.json` under the `version` field
- The extension version should align with the highest task version (typically v2)

### Version Synchronization
- V1 task maintains its own version line (currently 1.x.x)
- V2 task version should match the extension version (currently 2.x.x)
- When updating versions, increment at the same level (minor or patch) across all components

## Development Workflow
1. Make changes to PowerShell scripts in gitclone/v1/ or gitclone/v2/
2. Validate PowerShell syntax using the validation command
3. Test extension packaging with tfx-cli
4. Update task.json files if adding new parameters
5. Update vss-extension.json if changing extension metadata
6. **Update versions following the versioning guidelines above**
7. Clean up any generated .vsix files before committing