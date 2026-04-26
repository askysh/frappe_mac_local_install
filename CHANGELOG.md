# Changelog

All notable changes to this project are documented here.

## Unreleased

### Added

- Added preflight checks for running as a normal user, available disk space, and internet access.
- Added a timeout guard around `bench init`.
- Added handling for background commands that stop while waiting for terminal input.
- Added safe reuse guidance when an existing MariaDB/MySQL service is detected on port `3306`.
- Added README status badges.
- Added a roadmap file.

### Changed

- Rewrote README as a phased beginner walkthrough (two-passwords callout, MariaDB hardening-wizard answer table, explicit `/etc/hosts` step, common stumbles, wiping recipe, AI-agent guidance). Advanced flags (`--profile`, `--advanced`, `--check-updates`, `--repair-bench`, `--dry-run`, app bundles) moved after the happy path.
- Refreshed roadmap: the WSL/Windows path now lives in [askysh/frappe_wsl_dev_server](https://github.com/askysh/frappe_wsl_dev_server). Near-term items capture the script gaps surfaced by the WSL install journal (install `uv` before `bench init`, inline `mariadb-secure-installation`, auto utf8mb4 drop, auto patched-Qt wkhtmltopdf install, auto `/etc/hosts` macdev entry).

## 0.1.0 - 2026-04-25

### Added

- Initial public macOS Frappe/ERPNext local installer.
- Added profile-driven system dependency setup.
- Added bench and site setup with public app bundles.
- Added local shell tests with mocked `bench` and `git` behavior.
