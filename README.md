# Frappe Mac Local Install

Set up a local Frappe / ERPNext development server on macOS. Two scripts
walk you through it; this README walks you through THEM.

This is the macOS counterpart to
[askysh/frappe_wsl_dev_server](https://github.com/askysh/frappe_wsl_dev_server)
(for Windows / WSL).

## Who this is for

You want to try Frappe or ERPNext locally on a Mac, without renting a
server, paying for cloud hosting, or setting up a Linux VM by hand.

You don't need to be a Frappe person — the scripts handle the Frappe
parts. You DO need to be comfortable typing commands when this README
tells you what to type. If terms like "open Terminal", "Homebrew", or
"`sudo`" are new to you, that's fine — they're explained inline.

## What you'll have at the end

- A Frappe v15 + ERPNext v15 dev server running at `http://macdev:8000`,
  open in any browser on your Mac.
- Logged in as `Administrator` with a password you choose.
- About 5 GB of disk used.
- Whenever you want to use Frappe again, you'll run two commands:
  `cd ~/frappe-bench && bench start`.

## Before you start

You need:

- **macOS** on Apple Silicon (M1/M2/M3/M4). Intel Macs may work but
  aren't tested first — Apple Silicon is the primary target.
- **Homebrew** installed. To check: `brew --version` in Terminal. If
  that fails, install it from <https://brew.sh> (one paste-and-run
  command on the homepage).
- **Xcode Command Line Tools** installed. To check: `xcode-select -p`
  prints a path. If it errors, run `xcode-select --install` and click
  through the installer.
- **Internet** for downloads.
- **~5 GB free disk** under your home folder.

You do NOT need:

- Docker, a separate VM, or any pre-installed Linux
- Frappe, Python, Node, MariaDB, or anything else installed beforehand —
  the scripts handle all of it via Homebrew

## How long this takes

About **30–60 minutes**, mostly waiting on Homebrew downloads, MariaDB
setup, and `bench init` building the frontend. You'll be at your
computer the whole time but most of it is reading log output.

Things you can't skip:

- **Two passwords** to set during the install (next section).
- One `sudo` line to add `macdev` to `/etc/hosts` so the browser URL
  resolves (Phase 3).

## Heads-up: two passwords to write down

You'll set two different passwords at two different points during this
install. **Write each one down as you set it.** They unlock different
things and you'll be asked for them later — sometimes minutes later,
sometimes weeks later when you log back in to use Frappe.

| # | Where you set it | What it's for | When you'll need it again |
|---|---|---|---|
| 1 | Phase 1, the `mariadb-secure-installation` step ("Change the root password?") | The **MariaDB root password** — full admin access to the database | Phase 2 (the `MariaDB root password:` prompt). Also any time you connect to the DB as root later. |
| 2 | Phase 2 (`Site admin password:` prompt) | Your **ERPNext Administrator password** — login to the web UI | Every time you log in at `http://macdev:8000` as `Administrator`. |

These are two SEPARATE accounts. Do not reuse the same password for
both — when something rejects you later, you want to know exactly which
password is wrong without trying both.

If you forget either one later:

- **#1 (MariaDB root):** reset via MariaDB's password-reset procedure
  (`brew services stop mariadb@10.11`, start in `--skip-grant-tables`
  mode, set a new password, restart). Workable but annoying.
- **#2 (ERPNext Administrator):** reset via
  `bench --site macdev set-admin-password <new-password>` from inside
  `~/frappe-bench`. Much easier.

## The two windows you'll use

You'll bounce between two windows during install. Most of the work
happens in Terminal.

| Window | Used in | How to open |
|---|---|---|
| **Terminal** (or iTerm2) | Phases 1, 2, 3 setup, and every time you start Frappe | `Cmd+Space`, type "Terminal", hit Return. Or open iTerm2 if you have it. |
| **Web browser** (Safari, Chrome, Firefox) | Phase 3 login | However you normally open one. |

When this README says "in Terminal", that's the window to use.

---

## Phase 1 — Install system dependencies

This installs everything Frappe needs at the system level: Homebrew
formulas (Python, Node, MariaDB, Redis), then a small set of manual
steps for things Homebrew can't do safely on its own (the MariaDB
hardening wizard, Frappe's MariaDB charset config, and the
patched-Qt PDF generator).

### 1.1 — Get the scripts onto your computer

In Terminal:

```bash
cd ~
git clone https://github.com/askysh/frappe_mac_local_install.git
cd frappe_mac_local_install
```

If `git clone` fails with "command not found", run
`xcode-select --install` first (it ships git as part of the Command Line
Tools), then retry.

### 1.2 — Run the system-deps script

```bash
./00-mac-system-deps.sh
```

What it does:

- Checks your macOS version, Homebrew install, and Xcode CLT
- Installs the v15-lts Homebrew formulas: Python 3.11, Node 20,
  MariaDB 10.11, Redis, and a few support libraries
- Reports which `[OK]` / `[WARN]` checks pass
- Ends with a **PENDING MANUAL STEPS** list — the things you need to
  do yourself before script 02 can run

The first run can take 5–15 minutes depending on which formulas Homebrew
has to fetch. Re-runs are nearly instant — formulas already installed
just print `[OK]`.

### 1.3 — Work through the PENDING MANUAL STEPS the script printed

The script will tell you exactly which of the four sub-steps below it
needs you to do. Skip any sub-step it didn't list.

#### 1.3a — Append the profile exports to `~/.zshrc`

The script prints an exact `cat >> ~/.zshrc <<'BLOCK' ... BLOCK` block.
Copy-paste it into Terminal and run it. Then load the changes into the
current shell:

```bash
source ~/.zshrc
```

Why: Homebrew installs `python@3.11`, `node@20`, and `mariadb@10.11` as
"keg-only" or versioned formulas, which means their binaries aren't on
your `PATH` by default. The exports point your shell at them.

#### 1.3b — Set a MariaDB root password (`mariadb-secure-installation`)

```bash
mariadb-secure-installation
```

This is MariaDB's interactive hardening wizard. **Pay attention** — it
asks several yes/no questions, and the right answers for a Frappe dev
box are NOT all defaults.

| Prompt | Answer |
|---|---|
| `Enter current password for root` | Just press Enter (no password yet on a fresh install) |
| `Switch to unix_socket authentication` | `n` (Frappe needs password auth, not socket-only) |
| `Change the root password?` | `y`, then **pick a strong password — write it down.** This is **MariaDB Password #1**. You'll re-enter it in Phase 2. |
| `Remove anonymous users?` | `y` |
| `Disallow root login remotely?` | `y` |
| `Remove test database and access to it?` | `y` |
| `Reload privilege tables now?` | `y` |

(If you get socket-auth or "old data dir" errors, the script's printed
hint includes a `mariadb-install-db` recovery sequence — run that, then
retry `mariadb-secure-installation`.)

#### 1.3c — Drop in Frappe's utf8mb4 MariaDB config

The script prints an exact heredoc that creates
`<homebrew>/etc/my.cnf.d/frappe.cnf` and restarts MariaDB. Copy-paste
and run it.

Why: Frappe expects server-wide `utf8mb4` / `utf8mb4_unicode_ci`. The
default MariaDB charset is `utf8mb3` (legacy 3-byte). Without this
override, `bench new-site` silently creates utf8mb3 tables, which
breaks emoji and 4-byte characters and triggers the well-known
"Specified key was too long" error during site creation.

#### 1.3d — Install patched-Qt wkhtmltopdf

Download the official `.pkg` for macOS from:

<https://github.com/wkhtmltopdf/packaging/releases>

(Pick the latest `0.12.6.x` macOS-cocoa `.pkg`. Open it and click
through.)

Verify:

```bash
wkhtmltopdf --version
```

The output **must** contain the words `with patched qt`. If it doesn't,
you've got a wrong build.

Why: Homebrew's `wkhtmltopdf` formula is the upstream-unpatched build
and crashes when Frappe asks it to render real templates. The official
packaging release ships a Qt fork with the patches Frappe relies on.
There's no Homebrew formula that ships the patched build.

### 1.4 — Re-run the script to confirm

```bash
./00-mac-system-deps.sh
```

This time the SUMMARY should end with `READY` and `All dependencies are
configured.` instead of `PENDING MANUAL STEPS`. If anything still
shows up under pending, repeat the relevant sub-step.

---

## Phase 2 — Create the bench and site

This installs `frappe-bench` (Frappe's CLI) via `pipx`, clones the
Frappe and ERPNext codebases, builds the frontend, creates a site
called `macdev`, and installs ERPNext into it.

### 2.1 — Run the bench-and-site script

```bash
./01-install-bench-and-site.sh
```

What it does:

- Re-checks that all Phase 1 commands are on `PATH`
- Asks you to confirm bench dir name (default `frappe-bench`) and site
  name (default `macdev`) — just press Enter to accept defaults
- Asks for the **MariaDB root password** (from Phase 1.3b)
- Asks for an **Administrator password** for the new site
- Verifies it can log in to MariaDB with the password you gave
- Installs `frappe-bench` via `pipx` (one-time)
- Runs `bench init` — clones Frappe v15 and builds the frontend
  (~5 min)
- Runs `bench get-app erpnext` — clones ERPNext and builds (~5 min)
- Runs `bench new-site macdev` and `bench install-app erpnext`
- Sets `macdev` as the default site

### 2.2 — The two prompts during this script

You'll be asked twice for passwords. **They are different passwords.**
Both go on your written list.

| Prompt | What to type |
|---|---|
| `MariaDB root password:` | The password from Phase 1.3b. (If this rejects, run `mariadb -u root -p` in another tab to confirm what you actually set.) |
| `Site admin password:` then `Repeat:` | A NEW password (different from the one above). This is what you log in to ERPNext with. |

### 2.3 — Skip the prompts (optional)

If you'd rather pass passwords as environment variables to avoid
prompting:

```bash
MARIADB_ROOT_PASSWORD='your-mariadb-root-pw' \
ADMIN_PASSWORD='your-erpnext-admin-pw' \
./01-install-bench-and-site.sh --yes
```

`--yes` runs non-interactively — defaults are accepted for everything
that has a default (bench dir, site name, app bundle).

---

## Phase 3 — Add the hostname and start the server

### 3.1 — Add `macdev` to `/etc/hosts`

The script ends by telling you to do this if the line isn't already
there:

```bash
echo "127.0.0.1 macdev" | sudo tee -a /etc/hosts
```

You'll be asked for your **Mac login password** (not MariaDB, not
Administrator) — that's `sudo` asking for permission to edit a system
file.

Why: macOS doesn't resolve made-up hostnames like `macdev` by default.
This line tells your Mac that `macdev` means the local machine, so the
URL `http://macdev:8000` works in your browser. (The reason Frappe
prefers a custom hostname over `localhost` is multi-tenancy: each
Frappe site is keyed by hostname, and the bench's web server routes
based on what the browser asks for.)

### 3.2 — Start the dev server

```bash
cd ~/frappe-bench
bench start
```

This boots all the Frappe processes — web server, two Redis instances,
background worker, scheduler, asset watcher — and streams their output
to your terminal. After ~5 seconds you'll see lines like:

```
17:37:22 web.1 | * Running on http://0.0.0.0:8000
```

That means Frappe is ready.

**Leave this Terminal window running.** Do not close it. You can switch
to other Terminal tabs or windows for other work, but `Ctrl+C` or
closing this window stops Frappe immediately.

### 3.3 — Open ERPNext in your browser

Open `http://macdev:8000` in any browser (Safari, Chrome, Firefox —
all work).

You'll see a Frappe login page.

**Login:**

- Username: `Administrator`
- Password: the **Administrator password** from Phase 2.2 (NOT MariaDB,
  NOT your Mac login)

### 3.4 — Walk through the ERPNext setup wizard

First login shows a setup wizard. Answer the prompts:

- Country (sets currency, fiscal year, default chart of accounts)
- Company name
- Currency
- A user record for yourself

When the wizard finishes, you're at the ERPNext desk home — modules
list on the left, onboarding cards in the middle. **You're done.**

---

## Daily use after install

To start Frappe whenever you want to use it:

1. Open Terminal
2. `cd ~/frappe-bench && bench start`
3. Open `http://macdev:8000` in a browser
4. Log in as `Administrator`

To stop: in the Terminal running `bench start`, press `Ctrl+C`.

---

## Common stumbles

**`mariadb`: command not found right after Phase 1.**
Either `~/.zshrc` exports weren't appended (re-run sub-step 1.3a) or
they were appended but not yet loaded — open a new Terminal tab, or
run `source ~/.zshrc` in the existing one.

**`mariadb-secure-installation` complains about socket auth or rejects
all passwords.**
The script's PENDING output for `MARIADB_PASSWORD` includes a
`mariadb-install-db` recovery block — run that to re-init the MariaDB
data dir, then re-run `mariadb-secure-installation`. Don't skip the
data dir backup line.

**Phase 2 says "MariaDB root password is wrong" but I'm sure I typed
it right.**
Triple-check by running `mariadb -u root -p` in a separate Terminal
tab and entering the same password. If that fails too, the password
isn't what you think it is — re-run `mariadb-secure-installation`
and pick a new one.

**`bench: command not found` after Phase 2.**
`pipx` installs binaries to `~/.local/bin` which isn't on `PATH` by
default. Run:

```bash
pipx ensurepath
```

then close and reopen Terminal.

**Browser shows "can't connect to macdev" or "server not found".**
The `/etc/hosts` line from Phase 3.1 is missing. Re-run the
`echo "127.0.0.1 macdev" | sudo tee -a /etc/hosts` command.

**`bench start` runs but `http://macdev:8000` shows a blank page or
404.**
Check the Terminal output of `bench start` — early errors (port in
use, missing site, Redis failed) show up as red lines. Often `lsof
-iTCP:8000 -sTCP:LISTEN` reveals another process holding port 8000.

**"Specified key was too long" or emoji breakage in Frappe forms.**
Phase 1.3c (utf8mb4 config) was skipped. Drop in `frappe.cnf`, restart
MariaDB, drop the site (`bench drop-site macdev`), and re-run
script 01.

**PDFs render blank, garbled, or crash the request.**
You installed Homebrew's `wkhtmltopdf` instead of the patched-Qt build
from the packaging release. Run `wkhtmltopdf --version` — if it doesn't
say `with patched qt`, uninstall (`brew uninstall wkhtmltopdf`) and
install the official `.pkg` per Phase 1.3d.

**Apple Silicon: a Homebrew binary isn't found at all.**
Homebrew on Apple Silicon lives under `/opt/homebrew/...`, not
`/usr/local/...`. Confirm `/opt/homebrew/bin/brew shellenv` is sourced
from `~/.zshrc`:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

**I want to start over with a clean slate.**
See "Wiping it" below.

**Anything else.**
Re-run the script — both scripts are designed to be re-runnable and
will tell you what's still missing via `[OK]` / `[WARN]` / `[FAIL]`
lines.

---

## Customizing

The defaults (one ERPNext site at `macdev` on profile `v15-lts`) work
for most people. Below is what to change when you outgrow them.

### App bundles

| Bundle | Apps |
|---|---|
| `minimal` | `erpnext` |
| `common` | `erpnext hrms payments` |
| `extended` | `erpnext hrms payments crm helpdesk insights` |

```bash
APP_BUNDLE=common ./01-install-bench-and-site.sh
APP_BUNDLE=extended ./01-install-bench-and-site.sh
```

Or specify your own list explicitly:

```bash
APPS="erpnext hrms crm" ./01-install-bench-and-site.sh
```

You can inspect or edit bundle definitions in `config/app-bundles.tsv`.

### Profiles (Frappe / ERPNext major version)

| Profile | Frappe | ERPNext | Python | Node | MariaDB |
|---|---|---|---|---|---|
| `v15-lts` (default) | `version-15` | `version-15` | `python@3.11` | `node@20` | `mariadb@10.11` |
| `v16-lts` | `version-16` | `version-16` | `python@3.14` | `node@24` | `mariadb@11.8` |

`v15-lts` is the default because it's the conservative local dev path.
Use `v16-lts` only when you explicitly want to experiment with v16:

```bash
./00-mac-system-deps.sh --profile v16-lts
./01-install-bench-and-site.sh --profile v16-lts
```

List known profiles:

```bash
./00-mac-system-deps.sh --list-profiles
./01-install-bench-and-site.sh --list-profiles
```

### Custom branches / tags / commits

```bash
./01-install-bench-and-site.sh --advanced
```

This prompts for a custom Frappe branch / tag / commit and the same
for ERPNext. Use this only when you know you need a specific upstream
revision.

### Update checks

Check remote Frappe and ERPNext version branches:

```bash
./01-install-bench-and-site.sh --check-updates
```

If you are offline, print the newest cached result:

```bash
./01-install-bench-and-site.sh --check-updates --offline
```

### Recovery

If `frappe-bench` exists but is incomplete (e.g. `bench init` was
interrupted), the bench script stops instead of deleting anything.
To move the incomplete bench aside and retry:

```bash
./01-install-bench-and-site.sh --repair-bench
```

State is stored in `.frappe-local/state.env` (local-only, ignored by
Git).

### Dry-run

```bash
./00-mac-system-deps.sh --profile v15-lts --dry-run
MARIADB_ROOT_PASSWORD=dry ADMIN_PASSWORD=dry \
  ./01-install-bench-and-site.sh --yes --offline --dry-run
```

Prints every mutating command without executing it.

---

## Wiping it

To remove the bench and site without uninstalling Homebrew packages:

```bash
# Stop bench if it's running (Ctrl+C in the bench start Terminal)
rm -rf ~/frappe-bench
rm -rf ~/frappe_mac_local_install/.frappe-local
```

To also drop the site database and DB user:

```bash
mariadb -u root -p
```

then in the MariaDB prompt:

```sql
SHOW DATABASES;
DROP DATABASE `_<your-site-db-hash>`;
DROP USER '_<your-site-db-hash>'@'localhost';
EXIT;
```

(The site DB and user are named after a hash of the site name. `SHOW
DATABASES` lists them — they start with an underscore.)

For a complete reset including MariaDB and Redis state:

```bash
brew services stop mariadb@10.11
brew services stop redis
rm -rf "$(brew --prefix)/var/mysql"
rm -rf "$(brew --prefix)/var/db/redis"
brew services start mariadb@10.11
brew services start redis
# then re-run mariadb-secure-installation
```

To remove the Homebrew formulas entirely:

```bash
brew uninstall mariadb@10.11 redis node@20 python@3.11
```

---

## For AI coding agents

If you're an AI coding agent helping a user install Frappe locally on
macOS: this README is structured to be agent-followable. Each Phase
has explicit numbered sub-steps that, in sequence, produce a working
install. Defer to the script's own `[OK]` / `[WARN]` / `[FAIL]` /
`PENDING MANUAL STEPS` output for diagnostics.

Key things to call out for the user that the README already covers
but that you should reinforce in your own voice:

- They will be prompted twice for two different passwords across
  Phase 1 and Phase 2 — write each one down as it's set, do not
  reuse them.
- The PENDING MANUAL STEPS output between the two scripts is the
  most error-prone part of the install — walk the user through each
  printed step explicitly rather than letting them gloss over it.
- The `mariadb-secure-installation` answers are NOT all defaults —
  use the table in Phase 1.3b verbatim.
- After Phase 2, they need ONE `sudo` line to add `macdev` to
  `/etc/hosts` before the browser URL works.
- `bench start` (Phase 3.2) runs in the foreground; the user must
  leave that Terminal open while using Frappe.

---

## Files

```text
00-mac-system-deps.sh         # Phase 1: Homebrew formulas + pending steps
01-install-bench-and-site.sh  # Phase 2: bench init + site + ERPNext
lib/frappe-local/             # Shared shell helpers
config/                       # Profile and app-bundle definitions
tests/                        # Mocked-bench/git test harness
```

Keep `lib/`, `config/`, and `tests/` next to the two top-level scripts
when sharing or cloning the repo.

See [CHANGELOG.md](CHANGELOG.md) for release notes and
[ROADMAP.md](ROADMAP.md) for planned directions.

## Tests

Run the local test harness:

```bash
tests/run-tests.sh
```

The tests mock `git` and `bench`, so they do not create a real Frappe
bench. If `shellcheck` is installed, the harness also runs shell
linting.

---

## Important notes

- **Don't use the unversioned Homebrew `mariadb` formula** for the v15
  profile — pin to `mariadb@10.11` (which is what `--profile v15-lts`
  selects).
- **Don't `brew install wkhtmltopdf`** — Homebrew's build isn't
  patched-Qt and crashes on real Frappe templates. Use the official
  packaging release `.pkg`.
- **Don't switch MariaDB root to `unix_socket`-only** during
  `mariadb-secure-installation` (Phase 1.3b). Frappe needs password
  auth.
- **Don't delete your MariaDB data directory** without a backup —
  blowing away `$(brew --prefix)/var/mysql` removes every database
  on your machine, not just Frappe's.
- **Don't put `frappe-bench` under iCloud-synced paths** like
  `~/Desktop` or `~/Documents` if "Desktop & Documents" sync is
  enabled in System Settings. iCloud will fight `bench` for file
  ownership and you'll get random failures. `~/frappe-bench` (under
  the home folder root) is safe.
- **If a public app branch changes upstream**, use `APPS="erpnext"`
  first, then add apps one at a time so you can pinpoint which one
  broke.

## License

MIT — see [LICENSE](LICENSE).
