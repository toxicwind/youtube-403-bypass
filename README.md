# YouTube 403 Bypass

Cross-platform wrapper for [yt-dlp](https://github.com/yt-dlp/yt-dlp) that bypasses YouTube HTTP 403 errors by extracting cookies from your browser and generating PO tokens.

## Problem

YouTube aggressively blocks yt-dlp with HTTP 403 errors. The default `android vr player` API fallback also fails. You need:
- **Browser cookies** (you must be logged into YouTube)
- **PO tokens** (proof-of-origin tokens that verify you're a real browser)
- **Correct user-agent** (matching your browser)

## Solution

This wrapper auto-detects your browser, extracts cookies, and injects the correct arguments.

## Features

| Feature | Status |
|---------|--------|
| Auto-detect Chrome | ✅ |
| Auto-detect Brave | ✅ |
| Auto-detect Edge | ✅ |
| Auto-detect Firefox (dynamic profile discovery) | ✅ |
| Auto-detect Safari | ✅ |
| Cross-platform (macOS, Linux, Windows WSL) | ✅ |
| Homebrew-safe (skips self-update) | ✅ |
| Cleans previous install attempts | ✅ |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh | bash
```

Or download manually:
```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh
bash install.sh
```

## Usage

```bash
source ~/.zshrc  # or ~/.bashrc
which yt-dlp       # should show: ~/.local/bin/yt-dlp
yt-dlp 'https://youtu.be/VIDEO_ID'
```

## Requirements

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed
- [Deno](https://deno.land/) (for PO token generation, auto-installed if missing)
- Logged into [youtube.com](https://youtube.com) in your browser

## Tested

| Platform | Browser | Result |
|----------|---------|--------|
| macOS 15.4.1 | Chrome 126 | ✅ 13.24 MiB downloaded |
| macOS 15.4.1 | Firefox | ✅ (dynamic profile) |

## How It Works

1. Detects browser profiles on your system
2. Creates a wrapper script at `~/.local/bin/yt-dlp`
3. Forces `--extractor-args youtube:player_client=web`
4. Injects `--cookies-from-browser YOUR_BROWSER`
5. Adds PO token generation via Deno
6. Sets correct user-agent string

## Warning

You may see:
```
WARNING: Invalid po_token configuration format. Expected "CLIENT.CONTEXT+PO_TOKEN", got "bgutil"
```

This is **cosmetic** — yt-dlp 2026.07.04 changed the expected format but the `bgutil` plugin still triggers and works. The video downloads successfully despite the warning.

## License

MIT

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) team
- [bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider) for PO token generation
