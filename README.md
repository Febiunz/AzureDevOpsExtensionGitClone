# Azure DevOps Extension Git Repository Clone
Azure DevOps extension to clone an additional Git repository and checkout a specific branch.

## Parameters
### V1
- Repository URL: Full Repository URL to clone. Should be in the same Azure DevOps organization.
- Repository Path: Full path to store the git repository. If empty then default working folder.
- Branch: Branch to checkout (or pull).
- Clean: If ticked then (delete and) clone, else pull latest changes.
- Depth: Create a shallow clone with a history truncated to the specified number of commits. Leave empty for full clone.
### V2
V2 includes all V1 parameters plus the following additional parameters:
- Fallback Branch: Branch to checkout (or pull) if initial Branch failes.
- Base Branch: Branch to checkout (or pull) if fallback Branch failes.

## Requirements
- Only for an additional Git repository in the same Azure DevOps organization.
- Pipeline Agent agent version greater then 1.95.1
- "Allow scripts to access the OAuth token" box ticked in the Agent job (Run on agent) settings.
- Agent machine should have Git installed in PATH environment variable or at %ProgramFiles%\Git (Azure Pipelines Agents work!).

Inspired on an existing extension created by Fakhrulhilal Maktum: https://marketplace.visualstudio.com/items?itemName=fakhrulhilal-maktum.GitDownloader
Privacy policy: https://github.com/Febiunz/AzureDevOpsExtensionGitClone/blob/master/PRIVACY.md