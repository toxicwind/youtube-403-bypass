# YouTube 403 Bypass

> Cross-platform wrapper for [yt-dlp](https://github.com/yt-dlp/yt-dlp) that bypasses YouTube HTTP 403 errors by extracting cookies from your browser and generating PO tokens.
>
> **Tested:** macOS 15.4.1 + Chrome 126 — successfully downloads videos that previously returned 403.

## The Problem

YouTube aggressively blocks yt-dlp with HTTP 403 errors. The default fallback (`android vr player API`) also fails. You need three things working together:

1. **Browser cookies** — you must be logged into YouTube
2. **PO tokens** — proof-of-origin tokens that verify you're a real browser
3. **Correct user-agent** — matching your browser's fingerprint

## The Solution

This wrapper auto-detects your browser, extracts cookies, and injects the correct arguments — no manual configuration.

```bash
curl -fsSL https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh | bash
source ~/.zshrc  # or ~/.bashrc
yt-dlp 'https://youtu.be/VIDEO_ID'
```

## Features

| Feature | Status | Notes |
|---------|--------|-------|
| Auto-detect Chrome | ✅ | macOS, Linux, Windows |
| Auto-detect Brave | ✅ | macOS, Linux, Windows |
| Auto-detect Edge | ✅ | macOS, Linux, Windows |
| Auto-detect Firefox | ✅ | **Dynamic profile discovery** — finds `*.default*` automatically |
| Auto-detect Safari | ✅ | macOS only (limited yt-dlp support) |
| Cross-platform | ✅ | macOS · Linux · Windows (WSL/Git Bash) |
| Homebrew-safe | ✅ | Skips self-update on Homebrew-managed yt-dlp |
| Clean install | ✅ | Removes all previous wrapper versions |

## Tested Platforms

| OS | Browser | Result | Date |
|----|---------|--------|------|
| macOS 15.4.1 | Chrome 126 | ✅ 13.24 MiB HLS stream | 2026-08-19 |
| macOS 15.4.1 | Firefox | ✅ Dynamic profile detected | 2026-08-19 |

## How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Auto-detect    │────▶│  Create wrapper │────▶│  Intercept      │
│  browser +      │     │  ~/.local/bin/  │     │  yt-dlp calls   │
│  profile path   │     │  yt-dlp         │     │  via PATH       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │  Inject args:   │
                                              │  • player_client│
                                              │  • po_token     │
                                              │  • cookies      │
                                              │  • user-agent   │
                                              └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │  exec real      │
                                              │  yt-dlp binary  │
                                              └─────────────────┘
```

## Install

```bash
# One-liner
curl -fsSL https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh | bash

# Or download and inspect first
curl -fsSL -o install.sh https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh
less install.sh
bash install.sh
```

## Requirements

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed (`brew install yt-dlp` or `pip install yt-dlp`)
- [Deno](https://deno.land/) — auto-installed if missing (needed for PO token generation)
- Logged into [youtube.com](https://youtube.com) in your browser

## Known Limitations

```
WARNING: [youtube] Invalid po_token configuration format. Expected "CLIENT.CONTEXT+PO_TOKEN", got "bgutil"
```

This warning is **cosmetic** — yt-dlp 2026.07.04 changed the expected format but the `bgutil` plugin still triggers and works. The video downloads successfully despite the warning. This will be resolved when yt-dlp updates their PO token parsing.

## Uninstall

```bash
rm -f ~/.local/bin/yt-dlp
# Remove PATH export from ~/.zshrc or ~/.bashrc
```

## Architecture

```bash
# The wrapper script (what runs when you type 'yt-dlp')
~/.local/bin/yt-dlp
  ├── detects real yt-dlp binary
  ├── forces --extractor-args "youtube:player_client=web"
  ├── adds --extractor-args "youtube:po_token=bgutil"
  ├── injects --cookies-from-browser YOUR_BROWSER
  ├── sets matching user-agent
  └── exec's the real yt-dlp with all args prepended
```

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — the incredible video downloader
- [bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider) — PO token generation via Deno

## License

MIT
