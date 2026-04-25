# Frappe Mac Local Install

Two scripts for setting up a local Frappe / ERPNext development bench on macOS.

This is meant for people who want a repeatable local setup without reading every
Frappe, Homebrew, MariaDB, Redis, Python, and Node footnote first.

## What You Get

- Frappe Bench installed with `pipx`
- A local bench directory, default `frappe-bench`
- A local site, default `macdev`
- ERPNext installed by default
- Optional public Frappe apps such as HRMS, Payments, CRM, Helpdesk, and Insights
- Safe re-runs: existing bench, apps, site, and installed apps are skipped
- Preflight checks for user privileges, disk space, and internet access
- Timeout handling around long `bench init` runs

## Requirements

- macOS
- Homebrew installed from <https://brew.sh>
- Xcode Command Line Tools
- Internet access for the first install

Apple Silicon Macs are the main target. Intel Macs may work, but the scripts are
tested first on Apple Silicon.

## Quick Start

Clone the repo:

```bash
git clone https://github.com/askysh/frappe_mac_local_install.git
cd frappe_mac_local_install
```

Run the system dependency setup:

```bash
./00-mac-system-deps.sh
```

Complete any manual steps it prints. These usually include setting the MariaDB
root password, adding the utf8mb4 MariaDB config, or installing the patched-Qt
wkhtmltopdf package.

Then create the bench and site:

```bash
./01-install-bench-and-site.sh
```

When it finishes:

```bash
cd frappe-bench
bench start
```

Open:

```text
http://macdev:8000
```

Login:

```text
Administrator / the admin password you entered
```

## Normal Choices

Default install:

```bash
./01-install-bench-and-site.sh
```

This uses the `v15-lts` profile and installs ERPNext only.

Install a slightly larger public app set:

```bash
APP_BUNDLE=common ./01-install-bench-and-site.sh
```

Install the public app sampler:

```bash
APP_BUNDLE=extended ./01-install-bench-and-site.sh
```

Install your own app list:

```bash
APPS="erpnext hrms crm" ./01-install-bench-and-site.sh
```

## App Bundles

| Bundle | Apps |
| --- | --- |
| `minimal` | `erpnext` |
| `common` | `erpnext hrms payments` |
| `extended` | `erpnext hrms payments crm helpdesk insights` |

You can inspect or edit the bundle definitions in `config/app-bundles.tsv`.

## Profiles

List known release profiles:

```bash
./00-mac-system-deps.sh --list-profiles
./01-install-bench-and-site.sh --list-profiles
```

Current profiles:

| Profile | Frappe | ERPNext | Python | Node | MariaDB |
| --- | --- | --- | --- | --- | --- |
| `v15-lts` | `version-15` | `version-15` | `python@3.11` | `node@20` | `mariadb@10.11` |
| `v16-lts` | `version-16` | `version-16` | `python@3.14` | `node@24` | `mariadb@11.8` |

`v15-lts` is the default because it is the conservative local development path.
Use `v16-lts` only when you explicitly want to experiment with v16:

```bash
./00-mac-system-deps.sh --profile v16-lts
./01-install-bench-and-site.sh --profile v16-lts
```

The scripts check whether the selected Homebrew formulas are available before
trying to install them.

## Re-running Safely

Both scripts are designed to be re-run.

If MariaDB or MySQL is already listening on port `3306`, the scripts print safe
reuse guidance. The normal path is to keep your existing database data and auth
untouched, verify the root password, and let the bench/site script reuse it.

For non-interactive runs, provide passwords through environment variables:

```bash
MARIADB_ROOT_PASSWORD='your-db-root-password' \
ADMIN_PASSWORD='your-site-admin-password' \
./01-install-bench-and-site.sh --yes
```

Dry-run the dependency plan:

```bash
./00-mac-system-deps.sh --profile v15-lts --dry-run
```

Dry-run the bench/site plan:

```bash
MARIADB_ROOT_PASSWORD=dry \
ADMIN_PASSWORD=dry \
./01-install-bench-and-site.sh --yes --offline --dry-run
```

## Recovery

If `frappe-bench` exists but is incomplete, the bench script stops instead of
deleting anything. To move the incomplete bench aside and retry:

```bash
./01-install-bench-and-site.sh --repair-bench
```

State is stored in:

```text
.frappe-local/state.env
```

This file is local-only and ignored by Git.

## Advanced Version Mode

Use this only when you know you need a custom Frappe or ERPNext branch, tag, or
commit:

```bash
./01-install-bench-and-site.sh --advanced
```

## Update Checks

Check remote Frappe and ERPNext version branches:

```bash
./01-install-bench-and-site.sh --check-updates
```

If you are offline, print the newest cached result:

```bash
./01-install-bench-and-site.sh --check-updates --offline
```

## Tests

Run the local test harness:

```bash
tests/run-tests.sh
```

The tests mock `git` and `bench`, so they do not create a real Frappe bench. If
`shellcheck` is installed, the harness also runs shell linting.

## Files

The two public entrypoints are:

```text
00-mac-system-deps.sh
01-install-bench-and-site.sh
```

The supporting implementation is intentionally kept in:

```text
lib/frappe-local/
config/
tests/
```

Keep those directories with the scripts when sharing or cloning the repo.
See `CHANGELOG.md` for release notes and `ROADMAP.md` for planned directions.

## Important Notes

- Do not use the unversioned Homebrew `mariadb` formula for the v15 profile.
- Do not use Homebrew `wkhtmltopdf`; Frappe needs the patched-Qt build.
- Do not delete your MariaDB data directory without a backup.
- If a public app branch changes upstream, use `APPS="erpnext"` first, then add
  apps one at a time.
