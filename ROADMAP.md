# Roadmap

This project stays focused on simple local Frappe/ERPNext setup flows that are easy to audit, rerun, and adapt.

## Near Term

- Keep the default macOS path stable for Frappe/ERPNext v15.
- Improve first-run diagnostics when Homebrew, MariaDB, Redis, or wkhtmltopdf are missing or misconfigured.
- Add more mocked tests for failure paths in bench creation and app installation.

## Later

- Add a Windows setup shell script that uses WSL and follows the same clone-and-run style as the macOS scripts.
- Document tested WSL distributions and package versions once the Windows path exists.
