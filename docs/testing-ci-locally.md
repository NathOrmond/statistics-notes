# Testing GitHub Actions Locally with `act`

This guide explains how to test your GitHub Actions workflows locally using [`act`](https://github.com/nektos/act).

## Prerequisites

1. **Docker installed and running** - `act` uses Docker to simulate the GitHub Actions environment
2. **`act` installed** - You can install it with:
   ```bash
   brew install act  # macOS
   ```

Check if Docker is running:
```bash
docker ps
```

## Quick Start

### Unified script

Use the unified test runner for both manual local builds and CI simulation with `act`.

Manual build test (recommended for reliability):

```bash
./scripts/test.sh
```

CI test with `act`:

```bash
# Basic
./scripts/test.sh --ci

# On Apple Silicon
./scripts/test.sh --ci --amd64

# Provide explicit token (otherwise uses gh auth token if available)
./scripts/test.sh --ci --token YOUR_GITHUB_TOKEN
```

## For This Project

### Limitations of act for This Workflow

⚠️ **Important**: Your workflow uses actions that require the GitHub CLI (`gh`) tool, which isn't available in act's Docker containers. This means:
- ✅ Workflow syntax validation works
- ✅ Action repository cloning works
- ❌ Quarto setup step will fail (requires `gh` CLI)
- ❌ Full R/renv testing may be limited

**For comprehensive testing**, push to a branch and check the GitHub Actions logs.

### Details

- Manual mode runs the same steps as CI: `renv::restore()`, `scripts/generate_nav.R`, `quarto render`, and verifies `_site/`.
- CI mode runs your GitHub Actions workflow with `act` and an artifact server; it’s best for workflow syntax/flow validation, but may fail at Quarto setup due to missing `gh` CLI in containers.

**Option 2: Comment out the publish step temporarily**

For a cleaner test, you can temporarily comment out the publish step in `.github/workflows/publish.yml` while testing.

**Option 3: Use act's list functionality**

```bash
# See what jobs are available
act push --list

# Run specific job steps
act push --job build-deploy --dryrun
```

## Common Issues

### Docker Not Running

If you get Docker errors:
```bash
# Start Docker Desktop (macOS/Windows) or:
sudo systemctl start docker  # Linux
```

### Missing Secrets

Some workflows need secrets. You can provide them with `-s`:

```bash
act push -s GITHUB_TOKEN=your_token_here
```

For testing, you can use a dummy value since we're just testing the build.

### Large R Packages

The workflow installs R packages via `renv`, which can take time. Be patient during the restore step.

## Quick Test Command

Here's a one-liner to test your build pipeline:

```bash
# Test the workflow (will fail at publish, but shows if build works)
act push --job build-deploy -s GITHUB_TOKEN=dummy
```

## Tips

1. **Use `-v` for verbose output** to see detailed logs:
   ```bash
   act push -v
   ```

2. **Skip specific steps** if needed using act's configuration (create `.actrc` file)

3. **Test incrementally** - Test individual steps before running the full workflow

4. **Check Docker resources** - Running full workflows can be resource-intensive. Ensure Docker has enough memory allocated (4GB+ recommended).

## Alternative: Manual Testing

Instead of using `act`, you can also manually test the pipeline steps:

```bash
# 1. Restore renv
renv::restore()

# 2. Generate navigation
Rscript scripts/generate_nav.R

# 3. Render
quarto render

# 4. Check output in _site/
ls _site/
```

This won't test the GitHub Actions environment, but it will verify the commands work locally.

## Resources

- [act Documentation](https://github.com/nektos/act)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

