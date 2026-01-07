# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-01-08

### Fixed

- Fixed multi-line secret values not being exported correctly to `$GITHUB_ENV`
- Clarified dependencies in README (bash, curl, jq - all pre-installed on GitHub runners)

## [1.0.0] - 2025-01-08

### Added

- Initial release
- Fetch secrets from KeyEnv API
- Export secrets as GitHub Actions environment variables
- Write secrets to `.env` file
- Automatic masking of secret values in logs
- Support for project-scoped service tokens
- Multi-line secret value support
- Configurable API URL for self-hosted instances
