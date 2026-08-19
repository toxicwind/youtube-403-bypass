#!/bin/bash
# =============================================================================
# YT-DLP UNIVERSAL WRAPPER v9b — Cross-Platform YouTube 403 Bypass
# =============================================================================
# Auto-detects browser profiles, extracts cookies, generates PO tokens
# Platforms: macOS | Linux | Windows (WSL/Git Bash)
# =============================================================================
set -euo pipefail

PASS() { printf '\033[0;32m[PASS]\033[0m %s\n' "$*"; }
FAIL() { printf '\033[0;31m[FAIL]\033[0m %s\n' "$*"; }
INFO() { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
WARN() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

REAL_YTDLP="$(command -v yt-dlp)"
if [ -z "$REAL_YTDLP" ]; then
    echo "[FAIL] yt-dlp not found. Install: https://github.com/yt-dlp/yt-dlp#installation"
    exit 1
fi

# Platform detection
PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin*)  OS="macos"; BROWSER_BASE="$HOME/Library/Application Support" ;;
    Linux*)   OS="linux"; BROWSER_BASE="$HOME/.config" ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows"; BROWSER_BASE="$HOME/AppData/Local" ;;
    *)        OS="unknown"; BROWSER_BASE="$HOME" ;;
esac
INFO "Platform: $OS"

# Browser detection
BROWSER=""
PROFILE_PATH=""

if [ -d "$BROWSER_BASE/Google/Chrome" ] || [ -d "$BROWSER_BASE/google-chrome" ]; then
    BROWSER="chrome"; INFO "Found: Chrome"
elif [ -d "$BROWSER_BASE/BraveSoftware/Brave-Browser" ]; then
    BROWSER="brave"; INFO "Found: Brave"
elif [ -d "$BROWSER_BASE/Microsoft/Edge" ]; then
    BROWSER="edge"; INFO "Found: Edge"
elif [ -d "$HOME/Library/Application Support/Firefox" ] 2>/dev/null || [ -d "$HOME/.mozilla/firefox" ] 2>/dev/null; then
    if [ "$OS" = "macos" ]; then
        PROFILE_DIR="$HOME/Library/Application Support/Firefox/Profiles"
    else
        PROFILE_DIR="$HOME/.mozilla/firefox"
    fi
    if [ -d "$PROFILE_DIR" ]; then
        PROFILE_PATH="$(find "$PROFILE_DIR" -maxdepth 1 -type d -name '*.default*' 2>/dev/null | head -1)"
        if [ -n "$PROFILE_PATH" ]; then
            BROWSER="firefox"; INFO "Found: Firefox -> $(basename "$PROFILE_PATH")"
        fi
    fi
elif [ "$OS" = "macos" ] && [ -d "$HOME/Library/Safari" ]; then
    BROWSER="safari"; INFO "Found: Safari (limited support)"
fi

if [ -z "$BROWSER" ]; then
    FAIL "No supported browser detected"
    exit 1
fi

# Create wrapper
mkdir -p "$HOME/.local/bin"
if [ "$BROWSER" = "firefox" ] && [ -n "$PROFILE_PATH" ]; then
    BROWSER_ARG="firefox:$PROFILE_PATH"
else
    BROWSER_ARG="$BROWSER"
fi

cat > "$HOME/.local/bin/yt-dlp" << WRAPPER
#!/bin/bash
REAL=$REAL_YTDLP
ARGS=(
    --extractor-args "youtube:player_client=web"
    --extractor-args "youtube:po_token=bgutil"
    --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    --cookies-from-browser "$BROWSER_ARG"
    -f "best[height<=1080]/best"
)
exec "\$REAL" "\${ARGS[@]}" "\$@"
WRAPPER

chmod +x "$HOME/.local/bin/yt-dlp"

# Update PATH
SHELL_CONFIG="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_CONFIG="$HOME/.bashrc"

python3 -c "
import re
with open('$SHELL_CONFIG', 'r') as f:
    c = f.read()
for p in [r'# === YT-DLP.*?BEGIN ===.*?# === YT-DLP.*?END ===\n?', r'# YT-DLP-PATH-FIX.*\n?', r'export PATH=\"\$HOME/\.deno/bin:\$PATH\".*\n?', r'# yt-dlp wrapper.*\n?']:
    c = re.sub(p, '', c, flags=re.DOTALL)
c = re.sub(r'\n{3,}', '\n\n', c)
if not c.endswith('\n'): c += '\n'
with open('$SHELL_CONFIG', 'w') as f:
    f.write(c)
" 2>/dev/null || true

{
    echo ''
    echo '# yt-dlp universal wrapper'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
} >> "$SHELL_CONFIG"

export PATH="$HOME/.local/bin:$PATH"
WHICH="$(which yt-dlp)"

if [ "$WHICH" = "$HOME/.local/bin/yt-dlp" ]; then
    PASS "Wrapper ACTIVE: $WHICH"
else
    WARN "Wrapper NOT first in PATH. Got: $WHICH"
fi

INFO ""
INFO "=== NOW TRY ==="
echo ""
echo "source $SHELL_CONFIG"
echo "which yt-dlp   # should show: $HOME/.local/bin/yt-dlp"
echo "yt-dlp 'https://youtu.be/iQsu3Kz9NYo'"
echo ""
INFO "If still 403: LOG INTO youtube.com in $BROWSER first, then retry."
