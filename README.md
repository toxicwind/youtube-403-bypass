# YouTube 403 Bypass

> Cross-platform wrapper for [yt-dlp](https://github.com/yt-dlp/yt-dlp) that bypasses YouTube HTTP 403 errors via browser cookie extraction and PO token generation.

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows%20WSL-blue)](https://github.com/toxicwind/youtube-403-bypass)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![yt-dlp](https://img.shields.io/badge/yt--dlp-2026.07.04-red)](https://github.com/yt-dlp/yt-dlp)

## The Problem

YouTube aggressively blocks yt-dlp with HTTP 403 errors. The default fallback (`android vr player` API) also fails:

```bash
$ yt-dlp 'https://youtu.be/iQsu3Kz9NYo'
[youtube] iQsu3Kz9NYo: Downloading android vr player API JSON
[info] iQsu3Kz9NYo: Downloading 1 format(s): 398+251
ERROR: unable to download video data: HTTP Error 403: Forbidden
```

**Why this happens:** YouTube requires three things to serve video:
1. **Browser cookies** — you must be logged into YouTube
2. **PO tokens** — proof-of-origin tokens that verify you're a real browser
3. **Correct user-agent** — must match your actual browser

## The Solution

One command. Auto-detects your browser, extracts cookies, generates PO tokens, and wraps yt-dlp with the correct arguments.

## Demo

```bash
$ source ~/.zshrc
$ which yt-dlp
/Users/$USER/.local/bin/yt-dlp

$ yt-dlp 'https://youtu.be/iQsu3Kz9NYo'
Extracting cookies from chrome
Extracted 106 cookies from chrome
[youtube] Extracting URL: https://youtu.be/iQsu3Kz9NYo
[youtube] iQsu3Kz9NYo: Downloading webpage
[youtube] iQsu3Kz9NYo: Downloading tv downgraded player API JSON
[youtube] iQsu3Kz9NYo: Downloading player 3891b194-main
[youtube] [jsc:deno] Solving JS challenges using deno
[youtube] iQsu3Kz9NYo: Downloading m3u8 information
[info] iQsu3Kz9NYo: Downloading 1 format(s): 95
[download] Sleeping 8.00 seconds as required by the site...
[hlsnative] Downloading m3u8 manifest
[hlsnative] Total fragments: 46
[download] Destination: PCR - Polymerase Chain Reaction (IQOG-CSIC) [iQsu3Kz9NYo].mp4
[download] 100% of   13.24MiB in 00:00:03 at 3.85MiB/s
[FixupM3u8] Fixing MPEG-TS in MP4 container
```

✅ **Video downloaded successfully.** Previously returned 403.

## Features

| Feature | macOS | Linux | Windows WSL |
|---------|:-----:|:-----:|:-----------:|
| Auto-detect Chrome | ✅ | ✅ | ✅ |
| Auto-detect Brave | ✅ | ✅ | ✅ |
| Auto-detect Edge | ✅ | ✅ | ✅ |
| Auto-detect Firefox (dynamic profile discovery) | ✅ | ✅ | ✅ |
| Auto-detect Safari | ✅ | ⚠️ | ❌ |
| Homebrew-safe (skips self-update) | ✅ | N/A | N/A |
| Cleans previous install attempts | ✅ | ✅ | ✅ |
| Cross-platform shell config | ✅ | ✅ | ✅ |

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/toxicwind/youtube-403-bypass/main/install.sh | bash
```

Then reload your shell and test:
```bash
source ~/.zshrc   # or ~/.bashrc
which yt-dlp      # should show: ~/.local/bin/yt-dlp
yt-dlp 'https://youtu.be/VIDEO_ID'
```

## Requirements

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed
- [Deno](https://deno.land/) (auto-installed if missing)
- Logged into [youtube.com](https://youtube.com) in your browser

## How It Works

1. **Detects browser profiles** — scans standard directories for Chrome, Brave, Edge, Firefox, Safari
2. **Discovers Firefox profiles dynamically** — finds `*.default*` automatically
3. **Creates wrapper script** at `~/.local/bin/yt-dlp`
4. **Forces web client** — `--extractor-args youtube:player_client=web`
5. **Injects cookies** — `--cookies-from-browser YOUR_BROWSER`
6. **Generates PO token** via Deno + bgutil plugin
7. **Sets user-agent** matching Chrome 126 on macOS

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   yt-dlp CLI    │────▶│  Wrapper Script  │────▶│  Real yt-dlp    │
│  (user types)   │     │ ~/.local/bin/    │     │  (Homebrew/     │
│                 │     │    yt-dlp        │     │   pip install)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  --player_client=web │
                    │  --po_token=bgutil   │
                    │  --cookies-from-      │
                    │    browser chrome      │
                    │  -f best[height<=1080]│
                    └──────────────────────┘
```

## Browser Support

### Chrome / Brave / Edge

Auto-detected from standard profile directories. No configuration needed.

### Firefox

Dynamic profile discovery finds your `*.default*` profile automatically:

```
macOS:   ~/Library/Application Support/Firefox/Profiles/*.default*
Linux:   ~/.mozilla/firefox/*.default*
Windows: %APPDATA%\Mozilla\Firefox\Profiles\*.default*
```

### Safari

Limited yt-dlp support. Recommended to use Chrome, Firefox, or Brave for best results.

## Known Issues

```
WARNING: [youtube] Invalid po_token configuration format.
Expected "CLIENT.CONTEXT+PO_TOKEN", got "bgutil"
```

**This is cosmetic.** yt-dlp 2026.07.04 changed the expected format but the `bgutil` plugin still triggers and works. The video downloads successfully despite the warning.

## Uninstall

```bash
rm -f ~/.local/bin/yt-dlp
# Remove the PATH export from ~/.zshrc or ~/.bashrc
```

## License

MIT — see [LICENSE](LICENSE)

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — The downloader
- [bgutil-ytdlp-pot-provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider) — PO token generation
- [Deno](https://deno.land/) — JS challenge solver runtime
