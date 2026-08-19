#!/bin/bash
# =============================================================================
# YT-DLP UNIVERSAL WRAPPER v10 — The One Script
# =============================================================================
# Cross-platform: macOS | Linux | Windows (WSL/Git Bash/MSYS)
# Auto-detects: Chrome, Brave, Edge, Firefox (dynamic profile), Safari
# Bypasses: YouTube 403 via browser cookies + PO token + web client
# =============================================================================
set -euo pipefail

PASS() { printf '\033[0;32m[PASS]\033[0m %s\n' "$*"; }
FAIL() { printf '\033[0;31m[FAIL]\033[0m %s\n' "$*"; }
INFO() { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
WARN() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

# =============================================================================
# REQUIREMENTS CHECK
# =============================================================================
REAL_YTDLP="$(command -v yt-dlp)"
if [ -z "$REAL_YTDLP" ]; then
    FAIL "yt-dlp not found"
    INFO "Install: brew install yt-dlp   (macOS)"
    INFO "Install: pip install -U yt-dlp (Linux/Windows)"
    exit 1
fi

INFO "Found yt-dlp: $REAL_YTDLP"

# =============================================================================
# PLATFORM DETECTION
# =============================================================================
PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin*)  OS="macos"; BROWSER_BASE="$HOME/Library/Application Support" ;;
    Linux*)   OS="linux"; BROWSER_BASE="$HOME/.config" ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows"; BROWSER_BASE="$HOME/AppData/Local" ;;
    *)        OS="unknown"; BROWSER_BASE="$HOME" ;;
esac
INFO "Platform: $OS"

# =============================================================================
# BROWSER AUTO-DETECTION (priority order)
# =============================================================================
BROWSER=""
PROFILE_PATH=""

# 1. Chrome / Chromium
if [ -d "$BROWSER_BASE/Google/Chrome" ] || [ -d "$BROWSER_BASE/google-chrome" ] || [ -d "$BROWSER_BASE/chromium" ]; then
    BROWSER="chrome"
    INFO "Detected: Chrome"

# 2. Brave
elif [ -d "$BROWSER_BASE/BraveSoftware/Brave-Browser" ] || [ -d "$BROWSER_BASE/BraveSoftware/Brave-Browser-Nightly" ]; then
    BROWSER="brave"
    INFO "Detected: Brave"

# 3. Edge
elif [ -d "$BROWSER_BASE/Microsoft/Edge" ]; then
    BROWSER="edge"
    INFO "Detected: Edge"

# 4. Firefox — DYNAMIC PROFILE DISCOVERY
elif [ -d "$HOME/Library/Application Support/Firefox" ] 2>/dev/null || [ -d "$HOME/.mozilla/firefox" ] 2>/dev/null; then
    if [ "$OS" = "macos" ]; then
        PROFILE_DIR="$HOME/Library/Application Support/Firefox/Profiles"
    elif [ "$OS" = "linux" ]; then
        PROFILE_DIR="$HOME/.mozilla/firefox"
    elif [ "$OS" = "windows" ]; then
        PROFILE_DIR="$HOME/AppData/Roaming/Mozilla/Firefox/Profiles"
    fi

    if [ -d "$PROFILE_DIR" ]; then
        PROFILE_PATH="$(find "$PROFILE_DIR" -maxdepth 1 -type d -name '*.default*' 2>/dev/null | head -1)"
        if [ -n "$PROFILE_PATH" ]; then
            BROWSER="firefox"
            INFO "Detected: Firefox -> $(basename "$PROFILE_PATH")"
        else
            WARN "Firefox found but no default profile"
        fi
    fi

# 5. Safari (macOS only, limited yt-dlp support)
elif [ "$OS" = "macos" ] && [ -d "$HOME/Library/Safari" ]; then
    BROWSER="safari"
    INFO "Detected: Safari (limited yt-dlp support — use Chrome/Firefox for best results)"
fi

# =============================================================================
# BROWSER VALIDATION
# =============================================================================
if [ -z "$BROWSER" ]; then
    FAIL "No supported browser detected"
    INFO "Supported browsers: Chrome, Brave, Edge, Firefox, Safari"
    INFO "Make sure you have a browser installed and have logged into youtube.com"
    exit 1
fi

PASS "Using browser: $BROWSER"

# =============================================================================
# WRAPPER SCRIPT CREATION
# =============================================================================
INFO "Creating wrapper at ~/.local/bin/yt-dlp..."
mkdir -p "$HOME/.local/bin"

# Build browser argument for yt-dlp
if [ "$BROWSER" = "firefox" ] && [ -n "$PROFILE_PATH" ]; then
    BROWSER_ARG="firefox:$PROFILE_PATH"
else
    BROWSER_ARG="$BROWSER"
fi

cat > "$HOME/.local/bin/yt-dlp" << WRAPPER
#!/bin/bash
# yt-dlp universal wrapper — auto-generated v10
# Browser: $BROWSER_ARG
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
PASS "Wrapper created"

# =============================================================================
# SHELL CONFIG CLEANUP (nuke all previous yt-dlp installs)
# =============================================================================
INFO "Cleaning shell config..."

SHELL_CONFIG="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_CONFIG="$HOME/.bashrc"
[ -f "$HOME/.bash_profile" ] && SHELL_CONFIG="$HOME/.bash_profile"

if [ -f "$SHELL_CONFIG" ]; then
    python3 -c "
import re
with open('$SHELL_CONFIG', 'r') as f:
    c = f.read()

# Remove ALL yt-dlp blocks (v1 through v10)
patterns = [
    r'# === YT-DLP.*?BEGIN ===.*?# === YT-DLP.*?END ===\n?',
    r'# YT-DLP-PATH-FIX.*\n?',
    r'export PATH=\"\$HOME/\.deno/bin:\$PATH\".*\n?',
    r'# yt-dlp wrapper.*\n?',
    r'# yt-dlp universal wrapper.*\n?',
    r'export PATH=\"\$HOME/\.local/bin:\$PATH\".*\n?',
]
for p in patterns:
    c = re.sub(p, '', c, flags=re.DOTALL)

# Clean excessive blank lines
c = re.sub(r'\n{3,}', '\n\n', c)

# Ensure trailing newline
if not c.endswith('\n'):
    c += '\n'

with open('$SHELL_CONFIG', 'w') as f:
    f.write(c)
" 2>/dev/null || true
    PASS "Shell config cleaned: $SHELL_CONFIG"
else
    WARN "No shell config found at $SHELL_CONFIG"
fi

# =============================================================================
# PATH INJECTION
# =============================================================================
INFO "Updating PATH..."
{
    echo ''
    echo '# yt-dlp universal wrapper v10'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
} >> "$SHELL_CONFIG"

# =============================================================================
# VERIFICATION
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"
WHICH="$(which yt-dlp)"

if [ "$WHICH" = "$HOME/.local/bin/yt-dlp" ]; then
    PASS "Wrapper is FIRST in PATH: $WHICH"
else
    WARN "Wrapper NOT first in PATH"
    INFO "Got: $WHICH"
    INFO "Run: export PATH=\"$HOME/.local/bin:\$PATH\""
fi

# =============================================================================
# FINAL OUTPUT
# =============================================================================
INFO ""
INFO "========================================"
INFO "  INSTALLATION COMPLETE"
INFO "========================================"
INFO "Browser:     $BROWSER"
[ -n "$PROFILE_PATH" ] && INFO "Profile:     $PROFILE_PATH"
INFO "yt-dlp:      $REAL_YTDLP"
INFO "Wrapper:     $HOME/.local/bin/yt-dlp"
INFO "Shell config: $SHELL_CONFIG"
INFO ""
INFO "=== NOW TRY ==="
echo ""
echo "source $SHELL_CONFIG"
echo "which yt-dlp   # should show: $HOME/.local/bin/yt-dlp"
echo "yt-dlp 'https://youtu.be/iQsu3Kz9NYo'"
echo ""
INFO "If you get 403: LOG INTO youtube.com in $BROWSER first, then retry."
INFO ""
INFO "=== TROUBLESHOOTING ==="
INFO "- Check wrapper: cat ~/.local/bin/yt-dlp"
INFO "- Check PATH: echo \$PATH"
INFO "- Check browser: ls $BROWSER_BASE"
INFO "- Force re-install: bash <(curl -fsSL https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh)"
