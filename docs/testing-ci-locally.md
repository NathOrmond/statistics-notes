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

## Basic Usage

### Run All Workflows

```bash
# From the project root
act
```

This will:
- Detect workflows in `.github/workflows/`
- Show you which workflows match
- Ask which ones to run

### Run Specific Event

```bash
# Run workflows triggered by push events
act push

# Run workflows triggered by pull requests
act pull_request
```

### Dry Run (Preview Only)

See what would happen without actually executing:

```bash
act --dryrun
```

## For This Project

### Testing the Build Pipeline

Since your workflow publishes to GitHub Pages (which requires GitHub authentication), you'll want to test just the build steps. You can use `act` with the `--job` flag to run specific jobs, or modify the command to skip the publish step.

**Option 1: Run only the build job (without publish)**

```bash
act push --job build-deploy -s GITHUB_TOKEN=dummy_token
```

This will:
- ✅ Set up Quarto
- ✅ Set up R and install packages
- ✅ Generate navigation
- ✅ Render the website
- ⚠️ Attempt to publish (will fail without real token, but you can see the build succeeded)

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

