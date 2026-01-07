# KeyEnv GitHub Action

Fetch secrets from [KeyEnv](https://keyenv.dev) and inject them into your GitHub Actions workflows.

## Features

- Fetches secrets from KeyEnv and exports them as environment variables
- Optionally writes secrets to a `.env` file
- Automatically masks secret values in logs
- Supports project-scoped service tokens (no project-id required)
- Zero dependencies - uses only bash and curl

## Usage

### Basic Usage

```yaml
steps:
  - uses: keyenv/keyenv-action@v1
    with:
      token: ${{ secrets.KEYENV_TOKEN }}
      environment: production

  - run: echo "Database is at $DATABASE_URL"
```

### With Project ID

If your service token isn't project-scoped, specify the project:

```yaml
steps:
  - uses: keyenv/keyenv-action@v1
    with:
      token: ${{ secrets.KEYENV_TOKEN }}
      project-id: proj_abc123def456
      environment: staging
```

### Write to .env File

```yaml
steps:
  - uses: keyenv/keyenv-action@v1
    with:
      token: ${{ secrets.KEYENV_TOKEN }}
      environment: production
      env-file: .env

  - run: |
      # Secrets are now in .env file
      source .env
      ./run-tests.sh
```

### Disable Environment Export

If you only want the `.env` file without exporting to `$GITHUB_ENV`:

```yaml
steps:
  - uses: keyenv/keyenv-action@v1
    with:
      token: ${{ secrets.KEYENV_TOKEN }}
      environment: production
      export-env: false
      env-file: .env
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | KeyEnv service token | Yes | - |
| `environment` | Environment name (e.g., `production`, `staging`) | Yes | - |
| `project-id` | Project ID. Optional if using project-scoped token. | No | - |
| `api-url` | KeyEnv API URL | No | `https://api.keyenv.dev` |
| `export-env` | Export secrets to `$GITHUB_ENV` | No | `true` |
| `env-file` | Path to write `.env` file | No | - |
| `mask-values` | Mask secret values in logs | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `count` | Number of secrets fetched |

## Examples

### Deploy to Production

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: keyenv/keyenv-action@v1
        with:
          token: ${{ secrets.KEYENV_TOKEN }}
          environment: production

      - run: ./deploy.sh
        # All secrets are available as env vars
```

### Multi-Environment Matrix

```yaml
name: Test All Environments

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
    steps:
      - uses: actions/checkout@v4

      - uses: keyenv/keyenv-action@v1
        with:
          token: ${{ secrets.KEYENV_TOKEN }}
          environment: ${{ matrix.environment }}

      - run: npm test
```

### Docker Build with Secrets

```yaml
name: Build Docker Image

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: keyenv/keyenv-action@v1
        with:
          token: ${{ secrets.KEYENV_TOKEN }}
          environment: production
          env-file: .env.production
          export-env: false

      - run: |
          docker build \
            --secret id=env,src=.env.production \
            -t myapp:latest .
```

### Use Output Count

```yaml
steps:
  - uses: keyenv/keyenv-action@v1
    id: secrets
    with:
      token: ${{ secrets.KEYENV_TOKEN }}
      environment: production

  - run: echo "Loaded ${{ steps.secrets.outputs.count }} secrets"
```

## Setting Up Your Token

1. Go to your KeyEnv dashboard
2. Navigate to **Settings > Service Tokens**
3. Create a new token with:
   - **Scope**: Select your project
   - **Permissions**: `secrets:read`
4. Add the token to your GitHub repository:
   - Go to **Settings > Secrets and variables > Actions**
   - Click **New repository secret**
   - Name: `KEYENV_TOKEN`
   - Value: Your service token

## Security

- All secret values are automatically masked in GitHub Actions logs
- The service token is masked immediately upon use
- Secrets are fetched over HTTPS
- Service tokens can be scoped to specific projects and environments

## Self-Hosted KeyEnv

If you're running a self-hosted KeyEnv instance:

```yaml
- uses: keyenv/keyenv-action@v1
  with:
    token: ${{ secrets.KEYENV_TOKEN }}
    environment: production
    api-url: https://keyenv.your-company.com
```

## Troubleshooting

### "Authentication failed"

- Verify your token is correct
- Check the token hasn't expired
- Ensure the token is stored in GitHub Secrets correctly

### "Access denied"

- The token may not have access to the specified project
- The token may not have access to the specified environment
- Check token permissions in KeyEnv dashboard

### "Project or environment not found"

- Verify the `project-id` is correct
- Verify the `environment` name matches exactly
- Check the project/environment exists in KeyEnv

## License

MIT License - see [LICENSE](LICENSE) for details.
