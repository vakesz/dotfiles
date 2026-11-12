# WSL only: open links in Windows, share its clipboard, and keep Windows PATH
# entries behind ours. Detection is a variable and a file test: no forks.

[[ "$OSTYPE" == linux* ]] || return 0
[[ -n "${WSL_DISTRO_NAME:-}" || -e /proc/sys/fs/binfmt_misc/WSLInterop ]] || return 0

# wslview (from wslu) hands URLs to the Windows default browser.
(( $+commands[wslview] )) && export BROWSER="${BROWSER:-wslview}"

# WSL appends the Windows PATH (/mnt/c/...). Anything prepended later still
# goes in front, but move those entries last in case something re-added them.
path=(${path:#/mnt/[a-z]/*} ${(M)path:#/mnt/[a-z]/*})

# clip.exe reads its input in the OEM codepage unless it gets UTF-16 with a BOM.
if (( ! $+commands[pbcopy] && $+commands[clip.exe] )); then
  pbcopy() {
    { printf '\xff\xfe'; iconv -f UTF-8 -t UTF-16LE } | clip.exe
  }
fi

# PowerShell writes pipes in the OEM codepage too, and ends lines with CRLF.
if (( ! $+commands[pbpaste] && $+commands[powershell.exe] )); then
  pbpaste() {
    local text
    text="$(powershell.exe -NoProfile -NonInteractive -Command \
      '[Console]::OutputEncoding = [Text.Encoding]::UTF8; Get-Clipboard -Raw')" || return
    print -rn -- "${text//$'\r'/}"
  }
fi
