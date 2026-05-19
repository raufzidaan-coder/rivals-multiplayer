# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] - 2026-05-20

### Added
- Full Rojo + Claude Code + tests workflow: `test.rbxlx` runtime harness
  (77/77 passing), vendored toolchain in `tools/` (rojo, stylua, selene),
  and auto-activated `robloxstudio` MCP server via `.mcp.json` (`64c6bbe`).
- Pages status badge on `README.md` and this `CHANGELOG.md`.

### Changed
- GitHub Pages deploy migrated from the legacy branch-push flow to the
  `actions/deploy-pages` model in `.github/workflows/deploy.yml` (`7703f1d`).
- `README.md` MCP server inventory refreshed to reflect the current
  account-level + project-level server list (`61ba45b`).
- `README.md` bug-fix highlights synced to the authoritative count in
  `CLAUDE.md` (10 → 17), with new bullets for fixes 11-17.

### Fixed
- 17 pre-applied source bug fixes vs. the original Rivals scripts shipped
  alongside the test harness — see `CLAUDE.md` for the authoritative list.
  Notably: 14 invalid `Enum.InputState` / `KeyCode.MouseButton*` references
  in `RivalsCore.luau`, a dropped `SettingsUI` export from `Settings.luau`,
  and selene-surfaced fixes in `LobbyPads.luau` / `Client.client.luau` /
  `RivalsCore.luau` (`64c6bbe`).
