# Disk scan recipes (Windows, PowerShell via MSYS/bash terminal)

Every snippet below assumes `powershell.exe -NoProfile -Command "..."` run from
the Git Bash / MSYS shell. Escape `$` as `\$` inside the double-quoted string.

## Free space, all drives

```bash
powershell.exe -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | Where-Object{\$_.Used -ne \$null} | Select-Object Name,@{n='UsedGB';e={[math]::Round(\$_.Used/1GB,1)}},@{n='FreeGB';e={[math]::Round(\$_.Free/1GB,1)}} | Format-Table -AutoSize"
```

Always check every drive, not just the one being cleaned. A nearly-full secondary
drive is often the more urgent problem.

## Rank one directory level by size

Scope to a single root. This walks faster and cannot wander into unrelated trees.

```bash
powershell.exe -NoProfile -Command "\$p='C:\Users\<user>'; Get-ChildItem -Path \$p -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object { \$s=(Get-ChildItem \$_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; [PSCustomObject]@{Name=\$_.Name; GB=[math]::Round(\$s/1GB,2)} } | Sort-Object GB -Descending | Format-Table -AutoSize"
```

Repeat with `$p` set to each large child to drill down. Always include `LastWriteTime`
once you reach app/game/project directories - recency is what lets the user triage.

## Measured sizes of specific known-junk paths

Cheaper than a walk when the candidate list is already known.

```bash
powershell.exe -NoProfile -Command "\$paths='C:\Users\<user>\AppData\Local\Temp','C:\Users\<user>\.cache'; foreach(\$p in \$paths){ if(Test-Path \$p){ \$s=(Get-ChildItem \$p -Recurse -Force -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum; Write-Host ([math]::Round(\$s/1GB,2).ToString()+' GB  '+\$p) } }"
```

## Largest individual files above a threshold

```bash
powershell.exe -NoProfile -Command "Get-ChildItem 'C:\' -Recurse -Force -File -EA SilentlyContinue | Where-Object { \$_.Length -gt 500MB } | Sort-Object Length -Descending | Select-Object -First 25 @{n='GB';e={[math]::Round(\$_.Length/1GB,2)}}, LastWriteTime, FullName | Format-Table -AutoSize -Wrap"
```

This is how system files like `pagefile.sys` surface at all - it has no directory
entry but occupies real space on disk.

## Installed apps by size and last use

```bash
powershell.exe -NoProfile -Command "Get-ChildItem 'C:\Users\<user>\AppData\Local\Programs' -Force -Directory -EA SilentlyContinue | ForEach-Object { \$s=(Get-ChildItem \$_.FullName -Recurse -Force -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum; [PSCustomObject]@{N=\$_.Name;GB=[math]::Round(\$s/1GB,2);Last=(Get-ChildItem \$_.FullName -Recurse -Force -File -EA SilentlyContinue|Sort-Object LastWriteTime -Desc|Select-Object -First 1).LastWriteTime} } | Sort-Object GB -Descending | Format-Table -AutoSize"
```

## Stale updater payload folders

```bash
powershell.exe -NoProfile -Command "Get-ChildItem 'C:\Users\<user>\AppData\Local' -Force -Directory -EA SilentlyContinue | Where-Object{\$_.Name -match 'updater$'} | ForEach-Object { \$s=(Get-ChildItem \$_.FullName -Recurse -Force -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum; [PSCustomObject]@{N=\$_.Name;GB=[math]::Round(\$s/1GB,2)} } | Sort-Object GB -Descending | Format-Table -AutoSize"
```

## Batch project backup verification

Run from the project root before deleting anything inside it.

```bash
cd "C:/Users/<user>/Desktop/<project>"
git remote -v                                              # blank = no remote
git rev-list --all --count                                 # 0 = no commits at all
git log --oneline -3
git ls-files | wc -l
git ls-files | grep -c "^\.venv/"                          # must be 0 for artifacts
gh repo list --limit 300 --json name | grep -io '"name":"[^"]*"' | grep -i "<project>"
```

Blank remote, count 0, and no matching GitHub repo means the working tree is the
only copy. Say so before any deletion.

## Secret scan before recommending a push

```bash
grep -rIl --exclude-dir=.venv --exclude-dir=.git -iE "(sk-|gho_|ghp_|api[_-]?key\s*=|password\s*=|BEGIN.*PRIVATE KEY)" .
```

Expect false positives from prose - a hyphenated word can match `sk-`. Inspect
each hit rather than reporting the count.
