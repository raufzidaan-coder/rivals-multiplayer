# Rivals — test.rbxlx

Auto-running test suite that exercises `RivalsCore`, `MapSystem`, `Settings`,
and surrounding Roblox service APIs (TEST_PLAN.md sections R.\* and S.\*).

## Build

```powershell
.\tools\rojo.exe build test.project.json -o test.rbxlx
```

## Run

1. Open `test.rbxlx` in Roblox Studio.
2. Press **F5** (Play) — server boot triggers `tests/Runner.server.luau`.
3. Watch the **Output** window (View → Output, or Ctrl+9):

```
############################################################
# Rivals test.rbxlx — auto-run on server start
############################################################
============================================================
[Rivals Tests] Running 11 suites
============================================================

--- CONFIG + WEAPONS ---
  [PASS] CONFIG.Movement values match docs
  [PASS] CONFIG.Combat values match docs
  ...

--- Roblox services (S.*) ---
  [PASS] S.1: TweenService:Create works with TweenInfo
  ...

============================================================
[Rivals Tests] N/N passed, 0 failed, 0 skipped
============================================================
```

## Suite coverage

| Spec | TEST_PLAN section | What it verifies |
|---|---|---|
| `ConfigSpec` | R.1-3, R.10 | All `CONFIG.*` constants match the documented values; WEAPONS table shape; Bow `HasDoubleJump`; Sniper one-shot headshot math |
| `ExportsSpec` | R.* | All 8 system classes export with expected methods; `AbilitySystem` correctly absent |
| `MovementSpec` | R.1 | `MovementSystem.new`, `:Sprint`, `:Slide`, `:StopSlide`, `:SetWeaponDoubleJump` against a synthetic character |
| `CombatSpec` | R.2 | `TakeDamage`, headshot multiplier via `HitPart.Name == "Head"`, burst accumulation, `Heal`, `AddArmor` cap, `GetHealthPercent`, `ApplyKnockback` |
| `WeaponSpec` | R.3 | Per-weapon `:new`, `:CanFire`, `:Reload`, `:SetADS`, `:IsMelee`, `:HasDoubleJump`, `:GetSpread` for AssaultRifle and Bow |
| `PlayerDataSpec` | R.7 | `:GetRank` maps ELO to Bronze/Silver/.../top tier |
| `LobbySpec` | R.5 | `LobbySystem.new`, `:LeaveQueue` safe on non-queued player |
| `GameModeSpec` | R.6 | `:GetSpawnCFrame` returns CFrame for both teams; `:GetAliveCount`; `:OnEvent`/`:FireEvent` dispatch |
| `MapSystemSpec` | R.8 | `:CreateArena`/`:CreateWarehouse` create real folders; `:LoadMap` validates first (bug fix #9) |
| `SettingsSpec` | R.10 | `Settings` module loads and exports a table |
| `ServicesSpec` | S.1-S.8 | Every Roblox engine API the game relies on (Tween, Camera enums, BloomEffect/ColorCorrectionEffect/DepthOfFieldEffect/Atmosphere, Sound, WeldConstraint/AssemblyMass/PhysicalProperties, ScreenGui/Frame/UICorner/UIListLayout, DataStoreService, HttpService JSON round-trip) |

## Runtime characteristics & limits

Measured against the boshyxd `robloxstudio` MCP plugin in Studio:

- **MCP round-trip latency** — ~2-3s per `execute_luau` call (plugin uses a single-threaded HTTP polling loop, not WebSocket). Batch work into one large script per call where possible. The plugin's stated 20-40ms WebSocket overhead does not apply here.
- **Output buffer ceiling** — `print()` bursts past ~500 lines per `execute_luau` call overwhelm the plugin's HTTP loop and force a Studio reopen to recover. Keep print loops under 200 lines per call.
- **Mass-create benchmark** — 500 anchored Parts created via `Instance.new` in ~25ms; mass property set across them in ~5ms. The plugin itself is the bottleneck, not Studio.
- **Place build determinism** — `rojo build test.project.json` produces a 124,418-byte `.rbxlx` reproducibly. Any size drift indicates a source change; rebuild + diff before flagging the test runner.

If Studio's MCP panel shows "Server unavailable" or HTTP/MCP X after the runner finishes, the print-burst ceiling was probably exceeded. Close test.rbxlx (don't save) and reopen.

## What this does NOT cover

These TEST_PLAN.md items require a real player session, real Studio MCP, or
real network operations and are intentionally left as operator checklists:

- **A-Q sections** — filesystem/Rojo/MCP/Express plumbing (run from CLI, not in Studio)
- **R.4 AbilitySystem** — confirmed absent (`ExportsSpec` asserts `RivalsCore.AbilitySystem == nil`)
- **R.9 LobbyPads pad-touched flow** — needs a real player character to step on a pad
- **R.11 RemoteEvent live wiring** — needs a connected client to send remote payloads

For those, run the checklist in `TEST_PLAN.md` with a connected client + MCP.

## Adding a new spec

1. Drop a `tests/specs/<Name>Spec.luau` ModuleScript that returns
   `TestRunner.describe("Label", function(it) it("...", function(expect) ... end) end)`.
2. Rebuild: `.\tools\rojo.exe build test.project.json -o test.rbxlx`.
3. The runner auto-discovers any `ModuleScript` under `specs/`.

`TestRunner.luau` exposes: `expect.equal`, `expect.notEqual`, `expect.truthy`,
`expect.falsy`, `expect.near`, `expect.ge`, `expect.le`, `expect.errors`,
`expect.ok`, `expect.is_a`.
