# Roadmap

This project stays focused on simple local Frappe / ERPNext setup flows
that are easy to audit, rerun, and adapt.

## Now

The Windows / WSL path is shipped and lives in its own repo:
[askysh/frappe_wsl_dev_server](https://github.com/askysh/frappe_wsl_dev_server).
The two READMEs cross-link each other.

## Near term

The WSL install journal surfaced several script-level gaps that apply
to the Mac path too. These would close the README's "PENDING MANUAL
STEPS" gap and bring the Mac install closer to the WSL repo's "two
bash commands and you're done" UX:

- **Install `uv` via pipx before `bench init` runs.**
  `frappe-bench` 5.29.1 silently shells out to `uv venv` and fails
  with `FileNotFoundError: 'uv'` if it's missing. Mac currently
  installs `pipx` and `frappe-bench` but not `uv` — see
  [lib/frappe-local/bench.sh](lib/frappe-local/bench.sh).

- **Run `mariadb-secure-installation` inline** from
  [00-mac-system-deps.sh](00-mac-system-deps.sh), with a
  recommended-answers table printed before the wizard, instead of
  leaving it as a manual pending step. The WSL repo demonstrates this
  is workable — interactive wizards run cleanly inside the install
  script.

- **Auto-drop the utf8mb4 `frappe.cnf` and restart MariaDB** from
  [00-mac-system-deps.sh](00-mac-system-deps.sh) instead of printing
  the heredoc as a pending step.

- **Auto-install patched-Qt wkhtmltopdf** by downloading the official
  `.pkg` from the wkhtmltopdf packaging releases and running
  `installer -pkg ... -target /` (with checksum verification). The WSL
  repo automates the `.deb` install for Ubuntu — the Mac equivalent is
  a `.pkg`.

- **Add `127.0.0.1 macdev` to `/etc/hosts` automatically** from
  [01-install-bench-and-site.sh](01-install-bench-and-site.sh) (with a
  `--no-hosts` opt-out for users who manage `/etc/hosts` themselves),
  instead of printing it as a post-install instruction.

- Improve first-run diagnostics when Homebrew, MariaDB, Redis, or
  wkhtmltopdf are missing or misconfigured.

- Add more mocked tests for failure paths in bench creation and app
  installation.

## Later

- Keep the default macOS path stable for Frappe / ERPNext v15.
- Decide whether to land a `99-mac-uninstall.sh` rollback that
  automates the "Wiping it" recipe in the README.
