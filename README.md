# PowerShell Compatibility Layer for Unix 🪟

> **April Fools' Day edition** — Tired of Unix? Your terminal has been upgraded to PowerShell.

Unix commands are **disabled**. Use the PowerShell equivalents or face a `CommandNotFoundException`.

## Setup

```sh
source april_fools.sh
```

To restore sanity:

```sh
source april_fools.sh --uninstall
```

---

## Command Reference

| Unix | PowerShell cmdlet | Short alias |
|------|-------------------|-------------|
| `ls` | `Get-ChildItem` | `gci`, `dir` |
| `cat` | `Get-Content` | `gc` |
| `grep` | `Select-String` | `sls` |
| `pwd` | `Get-Location` | `gl` |
| `cd` | `Set-Location` | `sl` |
| `mkdir` | `New-Item -ItemType Directory -Path <dir>` | `ni` |
| `touch` | `New-Item -ItemType File -Path <file>` | `ni` |
| `rm` | `Remove-Item` | `ri`, `del` |
| `cp` | `Copy-Item` | — |
| `mv` | `Move-Item` | — |
| `echo` | `Write-Output` / `Write-Host` | — |
| `ps` | `Get-Process` | `gps` |
| `kill` | `Stop-Process` | `spps` |
| `env` | `Get-ChildItem Env:` | — |
| `whoami` | `Get-Variable -Name env:USER` | — |
| `find` | `Get-ChildItem -Recurse` | `gci -Recurse` |
| `head` | `Get-Content -Head <n>` | `gc -Head <n>` |
| `tail` | `Get-Content -Tail <n>` | `gc -Tail <n>` |
| `curl` | `Invoke-WebRequest` | `iwr`, `wget` |
| `wc` | `Measure-Object` | `measure` |
| `history` | `Get-History` | `h` |
| `man` | `Get-Help` | — |
| `date` | `Get-Date` | — |

---

## Examples

```powershell
# List files
Get-ChildItem
gci -Recurse -Filter "*.log"

# Read a file
Get-Content notes.txt
gc -Head 20 notes.txt
gc -Tail 5 notes.txt

# Search
Select-String -Pattern "error" app.log
sls "TODO" *.py

# Navigate
Set-Location /tmp
Get-Location

# Create & delete
New-Item -ItemType Directory -Path ./stuff
New-Item -ItemType File -Path ./stuff/hello.txt
Remove-Item -Recurse -Force ./stuff

# Copy & move
Copy-Item src.txt dst.txt
Move-Item old.txt new.txt

# Processes
Get-Process
Get-Process -Name node
Stop-Process -Id 1234

# Network
Invoke-WebRequest -Uri https://example.com
iwr -Uri https://example.com -OutFile page.html

# Measure
Measure-Object bigfile.txt
measure -Line -Word bigfile.txt

# Environment
Get-ChildItem Env:
Get-Variable -Name env:USER
```

---

## What happens when you use a Unix command

```
$ ls
ls : The term 'ls' is not recognized as the name of a cmdlet, function,
script file, or operable program. Check the spelling of the name, or if a
path was included, verify that the path is correct and try again.
At line:1 char:1
+ ls
+ ~~
    + CategoryInfo          : ObjectNotFound: (ls:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException

Did you mean: Get-ChildItem (gci)
```
