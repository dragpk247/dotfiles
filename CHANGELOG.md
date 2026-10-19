# Changelog

All notable changes to the personal dotfiles, multi-device mesh, and OMNI CLI ecosystem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-19

### Added
- **OMNI CLI (`omni` / `connect`)**: Centralized multi-device terminal hub for laptop, desktop, and phone.
- **PIN Security & Session Lock**: SHA-256 hashed PIN requirement with automatic 20-minute inactivity lockout.
- **Instant Keypress Navigation**: Single key selection without needing Enter.
- **Auto-Resume**: Hit Enter on startup to resume the last used action.
- **Sub-200ms Device Sniffing**: Background checks for SSH, Moonlight/Sunshine, Termux, and ADB services.
- **Cross-Device Bridge**: Clipboard push/pull and screenshot sync across devices.
- **Wake-on-LAN**: Broadcast magic packet to wake desktop on LAN.
- **Phone Setup**: Clean Termux environment with touch-optimized controls and automated sync (`sync-down`).
- **Semantic Versioning & Self-Updating**: Added `omni update` command with Git tag synchronization.
