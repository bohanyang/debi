# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Debi is a Debian Network Reinstall Script that allows reinstalling any VPS or physical machine to minimal Debian via network boot. It's a single POSIX-compliant shell script that automates the entire Debian installation process.

## Commands

### Running the Script
```bash
# Basic execution (requires root)
sudo ./debi.sh

# With options
sudo ./debi.sh --user debian --timezone UTC --cloudflare

# Dry run (generate config without installing)
sudo ./debi.sh --dry-run

# With cloud-init configuration
sudo ./debi.sh --cidata ./cidata-example/
```

### Testing Changes
```bash
# Check shell script syntax
sh -n debi.sh

# Run shellcheck for linting (if available)
shellcheck debi.sh

# Test in a VM environment (recommended)
# No automated test suite exists - manual testing required
```

## Architecture

The script operates in distinct phases:

1. **Configuration Phase**: Parses command-line arguments and validates environment
2. **Download Phase**: Fetches Debian installer components to `/boot/debian-$VERSION/`
3. **Preseed Generation**: Creates automated installation configuration
4. **GRUB Modification**: Adds installer entry to bootloader menu
5. **Initramfs Injection**: Embeds preseed and network configuration into installer
6. **Execution**: Updates GRUB and prepares for reboot

Key architectural decisions:
- Single-file design for easy distribution
- POSIX compliance for maximum compatibility
- No external dependencies beyond standard Linux utilities
- Modular function design with clear separation of concerns
- Extensive error handling with rollback capabilities

## Key Functions and Their Purposes

- `download()`: Handles file downloads with proxy support and multiple backend options (wget/curl/busybox)
- `set_debian_version()` / `set_suite()`: Manages Debian version selection and mirror URLs
- `configure_sshd()`: Sets up SSH access during installation for remote monitoring
- `in_target()`: Executes commands within the target installation environment
- `prompt_password()`: Securely handles password input with validation

## Important Configuration Variables

The script uses 80+ configuration options. Key ones include:
- `$suite`: Debian version (bookworm, bullseye, etc.)
- `$mirror_protocol` / `$mirror_host`: APT repository configuration
- `$disk`: Target installation disk
- `$authorized_keys_url`: SSH key provisioning
- `$cidata`: Cloud-init configuration directory

## Development Guidelines

1. **Maintain POSIX compliance** - Script must work with dash/sh, not just bash
2. **Test on real systems** - No test suite exists; changes require VM or physical testing
3. **Preserve backward compatibility** - Many users rely on specific option behaviors
4. **Document all options** - Update README.md for any new configuration options
5. **Handle errors gracefully** - Always provide rollback paths for critical operations

## Common Development Tasks

### Adding New Configuration Options
1. Add option to the case statement in the argument parsing section
2. Define corresponding variable with sensible default
3. Implement logic in appropriate phase function
4. Update README.md documentation

### Debugging Installation Issues
1. Use `--dry-run` to generate and inspect preseed configuration
2. Enable network console with `--ssh` for remote debugging
3. Check `/boot/debian-$VERSION/` for downloaded components
4. Review GRUB configuration changes in `/boot/grub/grub.cfg`

### Testing Platform Compatibility
Focus areas for testing:
- Network configuration (static IP vs DHCP)
- Disk detection and partitioning
- GRUB installation and boot entries
- Architecture-specific installer components