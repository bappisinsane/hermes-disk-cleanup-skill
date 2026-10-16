---
name: windows-disk-cleanup
description: Use when reclaiming space on a Windows drive.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [windows, disk, cleanup, storage, space-reclamation, filesystem]
    related_skills: [windows-cli-tools]
---

# Windows Disk Cleanup

Reclaim space on a Windows drive by finding unused files, classifying them by how
safe they are to delete, and removing only what the user approved.

Covers: ranking directories by size on Windows, separating regenerable junk from
structural system files and user data, verifying a backup before touching a
project directory, and running a cleanup that skips locked files.

**Machine-specific findings (C: drive, Windows 11, 16GB RAM):**
- Largest regenerable paths: `.cache` (13 GB), `Temp` (9.8 GB), `NVIDIA` driver cache
  (6.8 GB), `AppData\Roaming\npm` (5.2 GB — use `npm cache clean --force`),
  `Google` (2.9 GB), `uv` caches (3.1 GB across Local and Roaming),
  `BraveSoftware` (2.4 GB), plus smaller Cline/Playwright/Cypress/GitHubDesktop caches.
- `pagefile.sys` is 10.5 GB. Resizable to 4 GB via System Properties or WMI.
- No system restore points or hibernation file on this machine.
- Total reclaim from cache/temp alone: ~50 GB.

## Non-negotiable gates

These are not optional. Run the scan, present the tiers, then wait.

1. **Never delete before the user approves.** Present findings grouped by safety
   tier and stop. Approval of one tier is not approval of the others.
2. **Verify a backup exists before deleting anything inside a project directory.**
   Check the remote and the commit history, not just that the path looks
   disposable: `git remote -v`, `git rev-list --all --count`, `git log --oneline -3`,
   `git ls-files | wc -l`, and `gh repo list --limit 300 | grep -i <name>`.
   Zero commits with no remote means the working tree is the only copy — say so
   in plain terms and offer to push before deleting anything.
3. **Verify a build artifact is regenerable before deleting it.** Confirm a
   manifest exists (`pyproject.toml`, `package.json`, `requirements.txt`,
   `Cargo.toml`), that the artifact dir is gitignored, and that no files under it
   are tracked: `git ls-files | grep -c "^<dir>/"` must return 0. Then check the
   largest files inside it are third-party runtime blobs, not project data.
4. **Skip locked files silently, do not force them.** A running app holds its own
   temp files. Report them as skipped; they free on reboot.
5. **Explain system internals when you recommend touching them.** If the
   recommendation involves `pagefile.sys`, hibernation, restore points, or the
   component store, say what it is and what breaks before asking for a decision.

## Classification tiers

Present findings in these tiers, largest first within each:

- **Regenerable (delete now)** — package-manager caches, temp files, crash dumps,
  stale `*-updater` payload folders, vendor driver/OS-update download caches (e.g.
  NVIDIA `ota-artifacts`), old driver `.exe` installers, browser installer
  leftovers. All redownload on next use.
- **Structural (needs a decision, not a delete)** — `pagefile.sys`, hibernation
  file, restore points. Moving or resizing frees space; deleting can destabilize
  the OS. Offer the option, never just do it.
- **Judgment call (user's data)** — game saves, model weights, installed apps,
  stale project folders. Report size plus last-modified date and let the user
  choose. Age is evidence, not permission.

## Procedure

1. Get the baseline and every drive's free space, not just the target:
   `Get-PSDrive -PSProvider FileSystem | Select Name,@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}`
2. Rank directories by size one level at a time (see `references/scan-recipes.md`).
   Keep each walk scoped — a combined multi-root walk will hit the tool timeout.
3. Drill into the top consumers, again scoped, until each finding is attributable
   to a named path.
4. Present the tiers. Wait for approval.
5. Run `scripts/cleanup-c-drive.ps1` (add machine-specific paths to `$targets`
   first — it ships portable `$env:`-based paths plus auto-discovery of
   `*-updater` folders). It skips locked files, prints per-path and total freed,
   and reports free space before and after.
6. Report the real before/after numbers. Name anything you deliberately left.

## Pitfalls

- **Answer a "can we just delete everything in <folder>" request with what is
  inside it, not with a yes/no.** These folders hold live user data far more
  often than they hold junk: a game's `saves` and `backup` trees live under
  `AppData\Roaming/<game>/`, so "delete the whole app folder" destroys
  irreplaceable progress while regenerating nothing. Lead with the concrete
  content ("317 MB of Minecraft worlds are in here"), name the largest genuine
  reclaim inside it, and offer tiers. Say plainly that the biggest entries are
  not junk — a package manager's `node_modules` or a Python toolchain are the
  user's working toolchain, and removing them frees nothing usable. When the
  user declines after the walk, that is a complete outcome: report that nothing
  was deleted and stop.
- **A walk that sizes every entry in one call will time out.** A single
  `os.walk` summing a whole 18 GB profile root took ~90s, and drilling into four
  subtrees in one cell exceeded the 300s kernel limit and lost the work. Size the
  top level in one call, then drill into only the few largest entries in
  separate calls — the same scoping rule as the multi-root warning below.
- **Escape `$` as `\$` when passing PowerShell through the MSYS/bash terminal.**
  `powershell.exe -NoProfile -Command "Get-ChildItem \$p"` — an unescaped `$p`
  is expanded to empty by bash and the command silently walks the wrong tree.
- **Never put a recursive walk of a large root next to a slow native command**
  (e.g. `dism /analyzecomponentstore`) in one call. The native command holds the
  pipeline and the whole call times out, losing all results. One operation per call.
- **Measure before deleting, then measure after.** Report `Get-PSDrive C` free
  space both times; a cleanup script's own byte total is a claim, not proof.
- **Deleting a `.venv` is safe only after confirming the manifest.** CUDA/ONNX
  runtime libs are the bulk and redownload, but a stray hand-written script inside
  the venv does not.
- **Interrupted cleanup: a user may ask you to verify a backup AFTER you have
  already deleted something.** Drop the current step and run the gate-2 verification
  before resuming; approval given before the check is not approval after it.
- **Flag unbacked-up work you notice in passing.** A project tree with no remote
  and no commits is a standing risk; mention it once, plainly, and offer to push.
- **npm cache is enormous and slow to walk.** On this machine `AppData\Roaming\npm`
  held 5.18 GB. A PowerShell `Remove-Item -Recurse` over it timed out at 300s.
  Use `npm cache clean --force` instead — it cleared 3.2 GB in seconds. The
  remaining ~2 GB is in-use/locked and will free on reboot.
- **Some paths report 0 GB freed — that is not a failure.** `Windows\Temp`,
  `Windows\SoftwareDistribution\Download`, and `ProgramData\Package Cache`
  often show 0 GB freed because the files are already gone (cleaned by their
  parent app) or locked by the OS. Report the 0 GB honestly; do not retry.
- **Run the cleanup as a .ps1 file, not a giant inline command.** A 20-path
  cleanup script inline in bash will hit quoting/escaping issues. Write it to a
  .ps1 file under `hermes-storage\`, then execute with
  `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <path>`.
- **pagefile.sys resize procedure:** Never delete pagefile.sys. To resize:
  `System Properties > Advanced > Performance Settings > Advanced > Virtual
  Memory > Change`. Uncheck "automatically manage", set custom size (4096 MB
  for a 16GB RAM machine), click Set, OK, reboot. Or via WMI:
  `(Get-WmiObject Win32_PageFileSetting).InitialSize = 4096`.

## Related

- [[windows-cli-tools]] — installing CLI tooling on this box
