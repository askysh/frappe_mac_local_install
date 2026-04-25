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

## 0.1.0 - 2026-04-25

### Added

- Initial public macOS Frappe/ERPNext local installer.
- Added profile-driven system dependency setup.
- Added bench and site setup with public app bundles.
- Added local shell tests with mocked `bench` and `git` behavior.
