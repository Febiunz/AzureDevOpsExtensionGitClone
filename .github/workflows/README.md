# GitHub Actions Workflows

## Publish Extension to Marketplace

The `publish-extension.yml` workflow automates the process of packaging and publishing the Azure DevOps extension to the Visual Studio Marketplace.

### Triggers

The workflow can be triggered in two ways:

1. **Manual Dispatch**: Manually trigger the workflow from the GitHub Actions tab
   - Optional input: Version to publish (defaults to version in `vss-extension.json`)

2. **Release Published**: Automatically triggered when a GitHub release is published

### Prerequisites

Before running the workflow, you need to set up the following secret in your GitHub repository:

#### Required Secret: `AZURE_DEVOPS_PUBLISHER_PAT`

This is a Personal Access Token (PAT) from the Azure DevOps Marketplace that allows the workflow to publish extensions.

**Steps to create the PAT:**

1. Go to [Visual Studio Marketplace Publisher Management](https://marketplace.visualstudio.com/manage/publishers/)
2. Sign in with your publisher account (`febiunz`)
3. Click on your publisher name
4. Go to "Personal Access Tokens" or navigate to [Azure DevOps](https://dev.azure.com/)
5. Create a new token with the following settings:
   - **Name**: GitHub Actions Publishing
   - **Organization**: All accessible organizations
   - **Scopes**: Select "Marketplace" → "Manage"
   - **Expiration**: Set an appropriate expiration date
6. Copy the generated token (you won't be able to see it again)
7. In your GitHub repository, go to Settings → Secrets and variables → Actions
8. Click "New repository secret"
9. Name: `AZURE_DEVOPS_PUBLISHER_PAT`
10. Value: Paste the PAT you copied
11. Click "Add secret"

### Workflow Steps

1. **Checkout repository**: Checks out the code
2. **Setup Node.js**: Installs Node.js 20.x
3. **Install tfx-cli**: Installs the Azure DevOps Extension CLI tool
4. **Package extension**: Creates the VSIX package from the extension source
5. **Publish extension**: Publishes the extension to the Azure DevOps Marketplace using the PAT
6. **Upload VSIX artifact**: Uploads the generated VSIX file as a workflow artifact for reference

### Manual Execution

To manually trigger the workflow:

1. Go to the "Actions" tab in your GitHub repository
2. Select "Publish Extension to Marketplace" workflow
3. Click "Run workflow"
4. (Optional) Enter a version number to override the version in `vss-extension.json`
5. Click "Run workflow"

### Automatic Execution on Release

When you create and publish a release in GitHub:

1. Go to the "Releases" section in your GitHub repository
2. Click "Draft a new release"
3. Create a tag (e.g., `v2.5.2`)
4. Fill in the release notes
5. Click "Publish release"
6. The workflow will automatically trigger and publish the extension

### Troubleshooting

#### Authentication Errors

If you see authentication errors during publishing:
- Verify that the `AZURE_DEVOPS_PUBLISHER_PAT` secret is correctly set
- Check that the PAT hasn't expired
- Ensure the PAT has "Marketplace (Manage)" scope

#### Publishing Failures

If the extension fails to publish:
- Check that the extension version in `vss-extension.json` hasn't already been published
- Verify that the publisher ID (`febiunz`) matches your marketplace publisher
- Review the workflow logs for specific error messages

#### Package Creation Errors

If the VSIX package fails to create:
- Verify that `vss-extension.json` is valid JSON
- Check that all referenced files exist in the repository
- Ensure task.json files are present in the correct locations

### Version Management

The extension version is controlled by:
- **Extension version**: `vss-extension.json` → `version` field (e.g., "2.5.2")
- **V1 task version**: `gitclone/v1/task.json` → `version` object
- **V2 task version**: `gitclone/v2/task.json` → `version` object

When preparing a new release:
1. Update the version in `vss-extension.json`
2. Update the task version in the appropriate `task.json` file(s)
3. Commit the changes
4. Create and publish a GitHub release
5. The workflow will automatically publish to the marketplace
