# Contributing to SD Card Monitor Add-on

Thank you for considering contributing to this project!

## Development Setup

### Prerequisites

- Docker installed on your system
- Home Assistant installation (for testing)
- Git

### Building Locally

To build the add-on locally:

```bash
docker build \
  --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:3.19" \
  --build-arg SDMON_VERSION="v0.9.0" \
  -t local/sdmon-addon \
  -f sdmon/Dockerfile \
  sdmon/
```

### Testing

1. Copy the `sdmon` directory to your Home Assistant `addons` folder
2. Restart the Supervisor
3. Install the add-on from the local add-ons section
4. Configure and start the add-on
5. Check logs for any issues

## Code Style

- Follow Home Assistant add-on best practices
- Use semantic commit messages (as per project rules)
- Test on multiple architectures when possible

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes using semantic commit messages
4. Push to your branch
5. Open a Pull Request

### Commit Message Format

Use semantic commit messages:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `test:` - Adding tests

Example: `feat: add support for new SD card model`

## Reporting Issues

When reporting issues, please include:

- Add-on version
- Home Assistant version
- SD card model and manufacturer
- Add-on logs
- Configuration (sanitized)

## License

By contributing, you agree that your contributions will be licensed under the GPL-2.0 License.

