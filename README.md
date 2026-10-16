# 🧹 Windows Disk Cleanup — Hermes Skill

**Reclaim gigabytes of disk space on Windows with a tiered, safety-first cleanup system.**

Built for Hermes Agent. Tested on Windows 11, 16GB RAM, C: drive.

---

## 📊 Results from a Real Cleanup

| Metric | Before | After |
|--------|--------|-------|
| **C: free space** | **0.7 GB** 🔴 | **54.3 GB** 🟢 |
| **Total reclaimed** | | **~53.6 GB** |

### What Was Cleaned

| Category | Path | Freed |
|----------|------|-------|
| 📦 Cache | `.cache` (pip, HuggingFace) | 13.05 GB |
| 🗑️ Temp | `AppData\Local\Temp` | 9.7 GB |
| 🎮 Driver | `NVIDIA` driver cache | 6.78 GB |
| ⛏️ Game | `.minecraft` (user-approved) | 5.27 GB |
| 📦 Package | `npm` cache | ~3.2 GB |
| 🌐 Browser | `Google` Chrome cache | 2.86 GB |
| 🐍 Python | `uv` caches (×2) | 3.11 GB |
| 🌐 Browser | `BraveSoftware` | 1.94 GB |
| 📦 Windows | `Microsoft` cache | 1.4 GB |
| 🔧 Dev tools | GitHubDesktop, Cypress, Playwright, OpenAI, Cline, Packages | ~3.4 GB |

### What Was Deliberately Left Alone

| File | Size | Why |
|------|------|-----|
| `pagefile.sys` | 10.46 GB | Your RAM safety net — resizable to 4GB if you ever want 6.5GB more |
| `hiberfil.sys` | — | Already disabled |
| System Restore | — | Not configured |
| `AppData\Roaming\kimi-desktop` | 1.2 GB | Your call, not mine |

---

## 🚀 What It Can Free (Typical)

On a machine that hasn't been cleaned in 6+ months:

| Tier | Safe to Delete | Typical Savings |
|------|---------------|-----------------|
| **Tier 1: Regenerable** | Package caches, temp files, driver leftovers | **40–55 GB** |
| **Tier 2: User Data** | Game saves, old downloads (your call) | **5–15 GB** |
| **Tier 3: Structural** | `pagefile.sys` resize | **5–7 GB** |
| **Total potential** | | **50–75 GB** |

---

## 🛡️ Safety First

This skill **never deletes without approval**. Every cleanup follows a strict protocol:

1. **Scan** — rank directories by size, one level at a time
2. **Classify** — group findings into Regenerable / Judgment Call / Structural
3. **Present** — show the user exactly what's inside each path
4. **Wait** — no deletion until explicit approval
5. **Execute** — skip locked files, measure before/after
6. **Report** — real numbers, honest about what was skipped

---

## 🧠 Built-In Intelligence

- **Machine-specific findings** — knows the usual suspects on this box
- **npm cache workaround** — uses `npm cache clean --force` instead of walking millions of tiny files
- **Pagefile wisdom** — explains what breaks before touching system files
- **Backup verification** — checks git remotes before deleting project directories
- **Timeout survival** — scoped walks that don't die on large directories

---

## 📁 Skill Structure

```
windows-disk-cleanup/
├── SKILL.md                    # The brain
├── references/
│   └── scan-recipes.md         # PowerShell scanning recipes
└── scripts/
    └── cleanup-c-drive.ps1     # Reusable cleanup script
```

---

## 🏷️ Tags

`windows` `disk-cleanup` `storage` `space-reclamation` `maintenance` `cache-cleanup`

---

*One does so enjoy 53.6 GB of reclaimed disk space.*
