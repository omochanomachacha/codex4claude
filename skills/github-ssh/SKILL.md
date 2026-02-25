# Skill: GitHub Operations via SSH

**Purpose**: To perform GitHub actions in environments where the `gh` CLI is unavailable and only Git over SSH is configured.

## 1. Environment Detection & Remote Discovery

Before any operation, you MUST determine the correct remote name and SSH URL.

**Command:**
```bash
git remote -v
```

**Example Output:**
```
origin  git@github-personal:my-org/my-repo.git (fetch)
origin  git@github-personal:my-org/my-repo.git (push)
upstream        git@github-work:upstream-org/another-repo.git (fetch)
upstream        git@github-work:upstream-org/another-repo.git (push)
```

**Parsing the Output:**
- The first column is the **remote name** (e.g., `origin`, `upstream`).
- The second column is the **SSH URL**. The part after `git@` and before the colon is the **SSH host alias** (e.g., `github-personal`, `github-work`). You must use this alias.

## 2. Common Operations

Always use the appropriate remote name discovered in Step 1.

### Push
```bash
# Usage: git push <remote_name> <branch_name>
git push origin main
```

### Pull
```bash
# Usage: git pull <remote_name> <branch_name>
git pull upstream master
```

### Clone
This skill is typically used within an existing repository. To clone a new repository, you must first obtain the correct SSH clone URL from the GitHub UI.

```bash
# Usage: git clone git@<ssh_host_alias>:<org>/<repo>.git
git clone git@github-personal:my-org/new-repo.git
```

### Create a Pull Request (via API)

Creating a PR requires using the GitHub API with `curl`. A valid GitHub Personal Access Token with `repo` scope must be available as the `$GITHUB_TOKEN` environment variable.

**Step 1: Identify Repository and Branches**
- From `git remote -v`, identify the target repository slug (e.g., `upstream-org/another-repo`).
- Identify your head branch (the branch you want to merge) and the base branch (the branch you want to merge into, e.g., `main`).

**Step 2: Construct and Run the `curl` command**
```bash
# Replace <TARGET_REPO_SLUG>, <PR_TITLE>, <HEAD_BRANCH>, and <BASE_BRANCH>
curl -L 
  -X POST 
  -H "Accept: application/vnd.github+json" 
  -H "Authorization: Bearer $GITHUB_TOKEN" 
  -H "X-GitHub-Api-Version: 2022-11-28" 
  https://api.github.com/repos/<TARGET_REPO_SLUG>/pulls 
  -d '{"title":"<PR_TITLE>","head":"<HEAD_BRANCH>","base":"<BASE_BRANCH>"}'
```
*Example*:
`curl -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/upstream-org/another-repo/pulls -d '{"title":"My Awesome Feature","head":"my-feature-branch","base":"main"}'`

### View PR Status (via API)
```bash
# Replace <TARGET_REPO_SLUG> and <PR_NUMBER>
curl -L 
  -H "Accept: application/vnd.github+json" 
  -H "Authorization: Bearer $GITHUB_TOKEN" 
  -H "X-GitHub-Api-Version: 2022-11-28" 
  https://api.github.com/repos/<TARGET_REPO_SLUG>/pulls/<PR_NUMBER>
```

## 3. Error Handling
- **`Permission denied (publickey)`**: Your SSH key is not correctly configured for the host alias.
  - **Debug**: Run `ssh -T git@<ssh_host_alias>` to test the connection.
  - **Verify**: Check that the host alias is correctly defined in `~/.ssh/config`.
- **`curl` API Errors (401, 403, 404, 422)**:
  - **401/403 (Unauthorized)**: `$GITHUB_TOKEN` is missing, invalid, or lacks `repo` scope.
  - **404 (Not Found)**: The repository slug is incorrect. Check for typos.
  - **422 (Unprocessable Entity)**: The request is malformed. This often means the head branch has not been pushed, or the base branch name is wrong.
