#!/usr/bin/env bash
# april_fools.sh — PowerShell Compatibility Layer for Unix
#
# Unix commands are DISABLED. Use PowerShell equivalents instead.
#
# Usage:  source april_fools.sh
# Undo:   source april_fools.sh --uninstall

# ── clear any pre-existing aliases that would block function definitions ───
for _ps_alias in gl sl h dir del measure ni ri gc sls gci gps iwr wget \
                 ls cat grep pwd mkdir rm cp mv echo ps kill \
                 whoami env find touch head tail curl history wc man date cd; do
    unalias "$_ps_alias" 2>/dev/null
done
unset _ps_alias

# ── colours ────────────────────────────────────────────────────────────────
_PS_RED='\033[31m'
_PS_BLUE='\033[34m'
_PS_CYAN='\033[36m'
_PS_YELLOW='\033[33m'
_PS_BOLD='\033[1m'
_PS_DIM='\033[2m'
_PS_RESET='\033[0m'

# ── uninstall ───────────────────────────────────────────────────────────────
if [[ "${1-}" == "--uninstall" ]]; then
    for cmd in ls cat grep pwd mkdir rm cp mv echo ps kill \
               whoami env find touch head tail curl history wc man date cd; do
        unset -f "$cmd" 2>/dev/null
    done
    for cmd in Get-ChildItem Get-Content Select-String Get-Location Set-Location \
               New-Item Remove-Item Copy-Item Move-Item Write-Output Write-Host \
               Get-Process Stop-Process Get-Help Get-Date Invoke-WebRequest \
               Measure-Object Get-History Get-Variable \
               gci dir gc sls gl sl ni ri del gps spps iwr wget measure h; do
        unset -f "$cmd" 2>/dev/null
    done
    printf "PowerShell compatibility layer unloaded. Welcome back to Unix.\n" >&2
    return 0 2>/dev/null || exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# Helper: print a PowerShell-style CommandNotFoundException
# ══════════════════════════════════════════════════════════════════════════════
_ps_not_found() {
    local term="$1"
    local suggestion="${2-}"
    printf "\n${_PS_RED}%s : The term '%s' is not recognized as the name of a cmdlet, function,\n" \
        "$term" "$term" >&2
    printf "script file, or operable program. Check the spelling of the name, or if a path\n" >&2
    printf "was included, verify that the path is correct and try again.${_PS_RESET}\n" >&2
    printf "At line:1 char:1\n" >&2
    printf "+ %s\n" "$term" >&2
    printf "+ %s\n" "$(printf '%0.s~' $(seq 1 ${#term}))" >&2
    printf "    + ${_PS_RED}CategoryInfo          : ObjectNotFound: (%s:String) [], CommandNotFoundException${_PS_RESET}\n" \
        "$term" >&2
    printf "    + ${_PS_RED}FullyQualifiedErrorId : CommandNotFoundException${_PS_RESET}\n" >&2
    if [[ -n "$suggestion" ]]; then
        printf "\n${_PS_YELLOW}Did you mean: %s${_PS_RESET}\n" "$suggestion" >&2
    fi
    printf "\n" >&2
    return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# DISABLED Unix commands
# ══════════════════════════════════════════════════════════════════════════════
ls()      { _ps_not_found "ls"      "Get-ChildItem (gci)"; }
cat()     { _ps_not_found "cat"     "Get-Content (gc)"; }
grep()    { _ps_not_found "grep"    "Select-String (sls)"; }
pwd()     { _ps_not_found "pwd"     "Get-Location (gl)"; }
mkdir()   { _ps_not_found "mkdir"   "New-Item -ItemType Directory"; }
rm()      { _ps_not_found "rm"      "Remove-Item (ri)"; }
cp()      { _ps_not_found "cp"      "Copy-Item"; }
mv()      { _ps_not_found "mv"      "Move-Item"; }
echo()    { _ps_not_found "echo"    "Write-Output / Write-Host"; }
ps()      { _ps_not_found "ps"      "Get-Process (gps)"; }
kill()    { _ps_not_found "kill"    "Stop-Process (spps)"; }
whoami()  { _ps_not_found "whoami"  'Get-Variable -Name env:USER'; }
env()     { _ps_not_found "env"     "Get-ChildItem Env:"; }
find()    { _ps_not_found "find"    "Get-ChildItem -Recurse"; }
touch()   { _ps_not_found "touch"   "New-Item -ItemType File"; }
head()    { _ps_not_found "head"    "Get-Content -Head <n>"; }
tail()    { _ps_not_found "tail"    "Get-Content -Tail <n>"; }
curl()    { _ps_not_found "curl"    "Invoke-WebRequest (iwr)"; }
history() { _ps_not_found "history" "Get-History (h)"; }
wc()      { _ps_not_found "wc"      "Measure-Object (measure)"; }
man()     { _ps_not_found "man"     "Get-Help"; }
date()    { _ps_not_found "date"    "Get-Date"; }
cd()      { _ps_not_found "cd"      "Set-Location (sl)"; }

# ══════════════════════════════════════════════════════════════════════════════
# PowerShell commands — ENABLED
# ══════════════════════════════════════════════════════════════════════════════

# ── shared: stat helpers ────────────────────────────────────────────────────
_ps_mtime() {
    if [[ "$(uname)" == "Darwin" ]]; then
        stat -f "%Sm" -t "%m/%d/%Y %H:%M" "$1" 2>/dev/null
    else
        stat -c "%y" "$1" 2>/dev/null | \
            awk '{printf "%s %s", $1, substr($2,1,5)}' | \
            awk -F'[-: ]' '{printf "%02d/%02d/%s %s:%s", $2,$3,$1,$4,$5}'
    fi
}
_ps_size() {
    if [[ "$(uname)" == "Darwin" ]]; then
        stat -f%z "$1" 2>/dev/null
    else
        stat -c%s "$1" 2>/dev/null
    fi
}

# ── Get-ChildItem ───────────────────────────────────────────────────────────
Get-ChildItem() {
    local target="." recurse=0 filter="" show_env=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Recurse|-recurse)        recurse=1 ;;
            -Filter|-filter)          shift; filter="$1" ;;
            -Path|-path)              shift; target="$1" ;;
            Env:|env:)                show_env=1 ;;
            -*)                       ;;
            *)                        target="$1" ;;
        esac
        shift
    done

    # Get-ChildItem Env: → environment variables
    if [[ "$show_env" == 1 ]]; then
        printf "\n${_PS_BOLD}%-35s %s${_PS_RESET}\n" "Name" "Value"
        printf "%-35s %s\n" "----" "-----"
        command env | sort | awk -F= '{
            val = substr($0, index($0,"=")+1)
            printf "%-35s %s\n", $1, val
        }'
        printf "\n"
        return
    fi

    [[ -d "$target" ]] || target="."
    local abs_path
    abs_path=$(builtin cd "$target" 2>/dev/null && command pwd)

    if [[ "$recurse" == 1 ]]; then
        if [[ -n "$filter" ]]; then
            command find "$abs_path" -name "$filter" | sort
        else
            command find "$abs_path" | sort
        fi
        return
    fi

    printf "\n    Directory: %s\n\n" "$abs_path"
    printf "${_PS_BOLD}%-7s %-20s %12s  %s${_PS_RESET}\n" \
        "Mode" "LastWriteTime" "Length" "Name"
    printf "%-7s %-20s %12s  %s\n" "----" "-------------" "------" "----"

    local entries=()
    while IFS= read -r name; do
        entries+=("$name")
    done < <(command ls -1 "$target" 2>/dev/null | sort)

    for name in "${entries[@]}"; do
        local full="$target/$name"
        [[ -d "$full" ]] || continue
        printf "${_PS_CYAN}%-7s %-20s %12s  %s${_PS_RESET}\n" \
            "d----" "$(_ps_mtime "$full")" "" "$name"
    done
    for name in "${entries[@]}"; do
        local full="$target/$name"
        [[ -f "$full" ]] || continue
        printf "%-7s %-20s %12s  %s\n" \
            "-a---" "$(_ps_mtime "$full")" "$(_ps_size "$full")" "$name"
    done
    printf "\n"
}
gci() { Get-ChildItem "$@"; }
dir() { Get-ChildItem "$@"; }

# ── Get-Content ─────────────────────────────────────────────────────────────
Get-Content() {
    local head_n="" tail_n="" files=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Head|-head) shift; head_n="$1" ;;
            -Tail|-tail) shift; tail_n="$1" ;;
            -Path|-path) shift; files+=("$1") ;;
            -*)          ;;
            *)           files+=("$1") ;;
        esac
        shift
    done
    if [[ -n "$head_n" ]]; then
        command head -n "$head_n" "${files[@]}"
    elif [[ -n "$tail_n" ]]; then
        command tail -n "$tail_n" "${files[@]}"
    else
        command cat "${files[@]}"
    fi
}
gc() { Get-Content "$@"; }

# ── Select-String ───────────────────────────────────────────────────────────
Select-String() {
    local pattern="" files=() flags=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Pattern|-pattern) shift; pattern="$1" ;;
            -CaseSensitive)    flags+=("-s") ;;  # grep default is case-sensitive
            -NotMatch)         flags+=("-v") ;;
            -Path|-path)       shift; files+=("$1") ;;
            -*)                ;;
            *)
                if [[ -z "$pattern" ]]; then
                    pattern="$1"
                else
                    files+=("$1")
                fi
                ;;
        esac
        shift
    done
    command grep --color=auto "${flags[@]}" "$pattern" "${files[@]}"
}
sls() { Select-String "$@"; }

# ── Get-Location ─────────────────────────────────────────────────────────────
Get-Location() {
    printf "\nPath\n----\n"
    command pwd
    printf "\n"
}
gl() { Get-Location "$@"; }

# ── Set-Location ─────────────────────────────────────────────────────────────
Set-Location() {
    local target="${1:-$HOME}"
    builtin cd "$target" || return 1
}
sl() { Set-Location "$@"; }

# ── New-Item ─────────────────────────────────────────────────────────────────
New-Item() {
    local item_type="File" path=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -ItemType|-itemtype) shift; item_type="$1" ;;
            -Path|-path)         shift; path="$1" ;;
            -*)                  ;;
            *)                   [[ -z "$path" ]] && path="$1" ;;
        esac
        shift
    done
    if [[ -z "$path" ]]; then
        printf "${_PS_RED}New-Item: -Path is required.${_PS_RESET}\n" >&2
        return 1
    fi
    case "$item_type" in
        Directory|directory) command mkdir -p "$path" ;;
        *)                   command touch "$path" ;;
    esac
}
ni() { New-Item "$@"; }

# ── Remove-Item ──────────────────────────────────────────────────────────────
Remove-Item() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Recurse|-recurse)    args+=("-r") ;;
            -Force|-force)        args+=("-f") ;;
            -Path|-path)          shift; args+=("$1") ;;
            -*)                   ;;
            *)                    args+=("$1") ;;
        esac
        shift
    done
    command rm "${args[@]}"
}
ri()  { Remove-Item "$@"; }
del() { Remove-Item "$@"; }

# ── Copy-Item ────────────────────────────────────────────────────────────────
Copy-Item() {
    local src="" dst="" recurse=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Path|-path)        shift; src="$1" ;;
            -Destination|-dest) shift; dst="$1" ;;
            -Recurse|-recurse)  recurse=1 ;;
            -*)                 ;;
            *)
                if [[ -z "$src" ]]; then src="$1"
                else dst="$1"; fi
                ;;
        esac
        shift
    done
    if [[ "$recurse" == 1 ]]; then
        command cp -r "$src" "$dst"
    else
        command cp "$src" "$dst"
    fi
}

# ── Move-Item ────────────────────────────────────────────────────────────────
Move-Item() {
    local src="" dst=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Path|-path)        shift; src="$1" ;;
            -Destination|-dest) shift; dst="$1" ;;
            -*)                 ;;
            *)
                if [[ -z "$src" ]]; then src="$1"
                else dst="$1"; fi
                ;;
        esac
        shift
    done
    command mv "$src" "$dst"
}

# ── Write-Output / Write-Host ────────────────────────────────────────────────
Write-Output() { command echo "$@"; }
Write-Host()   {
    # Support -ForegroundColor (ignored functionally, but accepted)
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -ForegroundColor|-foregroundcolor|-BackgroundColor|-backgroundcolor|-NoNewline)
                shift ;;
            *) args+=("$1") ;;
        esac
        shift
    done
    command echo "${args[@]}"
}

# ── Get-Process ──────────────────────────────────────────────────────────────
Get-Process() {
    local name_filter=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Name|-name) shift; name_filter="$1" ;;
            -*)          ;;
            *)           name_filter="$1" ;;
        esac
        shift
    done
    printf "\n${_PS_BOLD}%-8s %-6s %-8s %-8s %s${_PS_RESET}\n" \
        "Handles" "NPM(K)" "PM(K)" "WS(K)" "ProcessName"
    printf "%-8s %-6s %-8s %-8s %s\n" \
        "-------" "------" "-----" "-----" "-----------"
    command ps aux 2>/dev/null | tail -n +2 | awk -v filter="$name_filter" '{
        handles = int($5 / 100) % 9999
        npm     = int($4)
        pm      = int($5)
        ws      = int($6)
        name    = $11; sub(/.*\//, "", name)
        if (filter == "" || index(name, filter) > 0)
            printf "%-8d %-6d %-8d %-8d %s\n", handles, npm, pm, ws, name
    }' | sort -k5 | head -40
    printf "\n"
}
gps() { Get-Process "$@"; }

# ── Stop-Process ─────────────────────────────────────────────────────────────
Stop-Process() {
    local pid="" name=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Id|-id)     shift; pid="$1" ;;
            -Name|-name) shift; name="$1" ;;
            -Force)      ;;
            -*)          ;;
            *)           pid="$1" ;;
        esac
        shift
    done
    if [[ -n "$name" ]]; then
        command pkill "$name"
    elif [[ -n "$pid" ]]; then
        command kill "$pid"
    else
        printf "${_PS_RED}Stop-Process: Provide -Id <pid> or -Name <name>${_PS_RESET}\n" >&2
        return 1
    fi
}
spps() { Stop-Process "$@"; }

# ── Get-Help ─────────────────────────────────────────────────────────────────
Get-Help() { command man "$@"; }

# ── Get-Date ─────────────────────────────────────────────────────────────────
Get-Date() {
    local fmt=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Format|-format) shift; fmt="$1" ;;
            *) ;;
        esac
        shift
    done
    if [[ -n "$fmt" ]]; then
        command date +"$fmt"
    else
        command date
    fi
}

# ── Invoke-WebRequest ─────────────────────────────────────────────────────────
Invoke-WebRequest() {
    local uri="" out_file="" method="GET" headers=() body=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Uri|-uri)                     shift; uri="$1" ;;
            -OutFile|-outfile)             shift; out_file="$1" ;;
            -Method|-method)               shift; method="$1" ;;
            -Headers|-headers)             shift; ;;  # simplified
            -Body|-body)                   shift; body="$1" ;;
            -*)                            ;;
            *)                             [[ -z "$uri" ]] && uri="$1" ;;
        esac
        shift
    done
    local curl_args=(-s -L -X "$method")
    [[ -n "$out_file" ]] && curl_args+=(-o "$out_file")
    [[ -n "$body" ]]     && curl_args+=(-d "$body")
    command curl "${curl_args[@]}" "$uri"
}
iwr()  { Invoke-WebRequest "$@"; }
wget() { Invoke-WebRequest "$@"; }

# ── Measure-Object ────────────────────────────────────────────────────────────
Measure-Object() {
    local files=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Line|-Line|-Word|-Character|-line|-word|-character) ;;
            -Path|-path) shift; files+=("$1") ;;
            -*)          ;;
            *)           files+=("$1") ;;
        esac
        shift
    done
    local out
    out=$(command wc "${files[@]}")
    printf "\n${_PS_BOLD}%-12s %-12s %-12s %s${_PS_RESET}\n" \
        "Lines" "Words" "Characters" "FileName"
    printf "%-12s %-12s %-12s %s\n" "-----" "-----" "----------" "--------"
    printf "%s\n" "$out" | awk '{
        if (NF==4) printf "%-12d %-12d %-12d %s\n", $1, $2, $3, $4
        else       printf "%-12d %-12d %-12d %s\n", $1, $2, $3, "(total)"
    }'
    printf "\n"
}
measure() { Measure-Object "$@"; }

# ── Get-History ───────────────────────────────────────────────────────────────
Get-History() {
    printf "\n${_PS_BOLD}%5s  %s${_PS_RESET}\n" "Id" "CommandLine"
    printf "%5s  %s\n" "--" "-----------"
    builtin history | tail -20 | awk '{id=$1; $1=""; printf "%5d  %s\n", id, substr($0,2)}'
    printf "\n"
}
h() { Get-History "$@"; }

# ── Get-Variable (env vars) ───────────────────────────────────────────────────
Get-Variable() {
    local name=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -Name|-name) shift; name="$1" ;;
            -*)          ;;
            *)           name="$1" ;;
        esac
        shift
    done
    if [[ "$name" == "env:USER" || "$name" == "env:USERNAME" ]]; then
        printf "\nName  Value\n----  -----\nUSER  %s\n\n" "$USER"
    elif [[ -n "$name" ]]; then
        local val="${!name}"
        printf "\nName   Value\n----   -----\n%-6s %s\n\n" "$name" "$val"
    else
        printf "${_PS_RED}Get-Variable: provide a variable name.${_PS_RESET}\n" >&2
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# welcome banner
# ══════════════════════════════════════════════════════════════════════════════
printf "\n${_PS_BOLD}${_PS_CYAN}"
printf ' ____                             ____  _          _ _\n'
printf '|  _ \ _____      _____ _ __    / ___|| |__   ___| | |\n'
printf '| |_) / _ \ \ /\ / / _ \  _ \  \___ \| |_ \ / _ \ | |\n'
printf '|  __/ (_) \ V  V /  __/ |_) |  ___) | | | |  __/ | |\n'
printf '|_|   \___/ \_/\_/ \___|_.__/  |____/|_| |_|\___|_|_|\n'
printf '   Compatibility Layer v1.0.0-AprilFools\n'
printf "${_PS_RESET}\n"
printf "${_PS_YELLOW}WARNING:${_PS_RESET} Unix commands have been disabled.\n"
printf "         Use PowerShell equivalents or face a CommandNotFoundException.\n\n"
printf "${_PS_BOLD}Quick reference:${_PS_RESET}\n"
printf "  %-10s  →  %s\n" \
    "ls"      "Get-ChildItem  (gci, dir)" \
    "cat"     "Get-Content    (gc)" \
    "grep"    "Select-String  (sls)  -Pattern <pat> <file>" \
    "pwd"     "Get-Location   (gl)" \
    "cd"      "Set-Location   (sl)" \
    "mkdir"   "New-Item -ItemType Directory -Path <dir>" \
    "touch"   "New-Item -ItemType File -Path <file>" \
    "rm"      "Remove-Item    (ri, del)  [-Recurse] [-Force]" \
    "cp"      "Copy-Item      <src> <dst>" \
    "mv"      "Move-Item      <src> <dst>" \
    "ps"      "Get-Process    (gps)" \
    "kill"    "Stop-Process   (spps)  -Id <pid> | -Name <name>" \
    "curl"    "Invoke-WebRequest (iwr, wget)  -Uri <url>" \
    "wc"      "Measure-Object (measure)" \
    "history" "Get-History    (h)" \
    "man"     "Get-Help" \
    "date"    "Get-Date" \
    "env"     "Get-ChildItem Env:" \
    "whoami"  'Get-Variable -Name env:USER'
printf "\n${_PS_DIM}To restore sanity:${_PS_RESET} source april_fools.sh --uninstall\n\n"
