# Angel Cloud: The Cloud Climb — Luau Style Guide

> **Last updated:** February 27, 2026
> **Version:** 1.0
> **Tools:** Selene (linting), StyLua (formatting), Rojo 7.x (sync)

---

## 1. File Naming (Rojo Convention)

| Suffix | Script Type | Runs On |
|--------|------------|---------|
| `*.server.lua` | Script | Server |
| `*.client.lua` | LocalScript | Client |
| `*.lua` | ModuleScript | Both (imported via require) |

**Examples:**
- `GameManager.server.lua` → Script in ServerScriptService
- `ClientController.client.lua` → LocalScript in StarterPlayerScripts
- `DataManager.lua` → ModuleScript in ServerScriptService

---

## 2. Naming Conventions

```lua
-- Modules: PascalCase
local DataManager = {}

-- Functions: PascalCase
function DataManager.LoadPlayer(player: Player): PlayerData? end

-- Local variables: camelCase
local playerData = {}
local currentLayer = 1

-- Constants: UPPER_SNAKE_CASE
local MAX_STAMINA = 100
local FLIGHT_SPEED = 80
local MOTE_RESPAWN_TIME = 300

-- Private functions: prefixed with underscore
local function _validateInput(data: any): boolean end
local function _calculateDrain(tier: number): number end

-- RemoteEvents: PascalCase verb phrases
-- "PlayerReady", "MoteCollected", "BlessingGiven", "AngelMailSent"

-- Type aliases: PascalCase
type PlayerData = {
    motes: number,
    halos: number,
    angelLevel: string,
    fragments: { [number]: boolean },
}

-- Boolean variables: prefix with is/has/can/should
local isFlying = false
local hasWings = true
local canGlide = false
```

---

## 3. Module Pattern

Every module follows this structure:

```lua
--!strict
-- ModuleName.lua
-- Brief description of what this module does
-- Location: ServerScriptService/ModuleName

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local Config = require(ReplicatedStorage.Config.Layers)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Types
type PlayerData = {
    motes: number,
    halos: number,
    angelLevel: string,
}

-- Constants
local MAX_RETRIES = 3
local SAVE_INTERVAL = 300

-- Module table
local ModuleName = {}

-- Private state
local _playerCache: { [number]: PlayerData } = {}

-- Private functions
local function _validatePlayer(player: Player): boolean
    return player and player.Parent ~= nil
end

-- Public functions
function ModuleName.Initialize(): ()
    -- Setup code
end

function ModuleName.GetPlayerData(player: Player): PlayerData?
    if not _validatePlayer(player) then
        return nil
    end
    return _playerCache[player.UserId]
end

-- Cleanup
function ModuleName.Destroy(): ()
    table.clear(_playerCache)
end

return ModuleName
```

---

## 4. Banned Patterns

### 4.1 Deprecated APIs — NEVER USE

```lua
-- ❌ BANNED
wait(1)
spawn(function() end)
delay(1, function() end)

-- ✅ CORRECT
task.wait(1)
task.spawn(function() end)
task.delay(1, function() end)
```

### 4.2 Unsafe Patterns

```lua
-- ❌ BANNED: Trusting client values
RemoteEvent.OnServerEvent:Connect(function(player, amount)
    playerData.halos += amount  -- Client could send any number!
end)

-- ✅ CORRECT: Server calculates everything
RemoteEvent.OnServerEvent:Connect(function(player, actionId)
    if typeof(actionId) ~= "string" then return end
    local reward = _calculateReward(actionId)
    if reward then
        playerData.halos += reward
    end
end)
```

### 4.3 Performance Anti-Patterns

```lua
-- ❌ BANNED: Creating instances in hot loops
RunService.Heartbeat:Connect(function()
    local part = Instance.new("Part")  -- 60 new parts/second!
end)

-- ✅ CORRECT: Pool and reuse
local partPool: { Part } = {}
local function _getFromPool(): Part
    if #partPool > 0 then
        return table.remove(partPool) :: Part
    end
    return Instance.new("Part")
end

-- ❌ BANNED: FindFirstChild chains
local val = workspace:FindFirstChild("Folder")
    and workspace.Folder:FindFirstChild("SubFolder")
    and workspace.Folder.SubFolder:FindFirstChild("Part")

-- ✅ CORRECT: CollectionService tags
local CollectionService = game:GetService("CollectionService")
local motes = CollectionService:GetTagged("LightMote")
```

---

## 5. Client-Server Security Rules

### 5.1 Core Principle

**ALL game state lives on the server. The client is a display layer.**

| Data | Where It Lives | Client Can... |
|------|---------------|---------------|
| Mote count | Server (DataManager) | Read (via RemoteFunction) |
| Halo balance | Server (DataManager) | Read |
| Angel Level | Server (ProgressionSystem) | Read |
| Wing Gauge | Server (StaminaSystem) | Read current value |
| Lore Fragments | Server (LoreSystem) | Read collected list |
| Cloud Base layout | Server (DataManager) | Send layout changes (validated server-side) |

### 5.2 Remote Event Validation

Every server handler MUST:

```lua
RemoteEvent.OnServerEvent:Connect(function(player: Player, ...)
    -- 1. Type check ALL arguments
    local args = { ... }
    if typeof(args[1]) ~= "string" then
        warn("[System] Invalid argument type from", player.Name)
        return
    end

    -- 2. Rate limit (debounce)
    if not _checkRateLimit(player, "ActionName", 0.2) then
        return
    end

    -- 3. Range/bounds check
    if args[1]:len() > 100 then
        return
    end

    -- 4. Ownership check (is this player allowed to do this?)
    if not _canPlayerPerformAction(player, args[1]) then
        return
    end

    -- 5. Execute on server
    _performAction(player, args[1])
end)
```

### 5.3 Rate Limiting Template

```lua
local _lastAction: { [number]: { [string]: number } } = {}

local function _checkRateLimit(player: Player, action: string, cooldown: number): boolean
    local userId = player.UserId
    if not _lastAction[userId] then
        _lastAction[userId] = {}
    end

    local now = tick()
    local last = _lastAction[userId][action] or 0

    if now - last < cooldown then
        return false
    end

    _lastAction[userId][action] = now
    return true
end
```

---

## 6. Error Handling

### 6.1 External Calls (DataStore, HTTP)

```lua
local ok, result = pcall(function()
    return DataStoreService:GetAsync(key)
end)

if not ok then
    warn("[DataManager] GetAsync failed:", tostring(result))
    return fallbackValue
end
```

### 6.2 Retry Pattern

```lua
local function _retryAsync<T>(fn: () -> T, maxRetries: number, delay: number): (boolean, T?)
    for attempt = 1, maxRetries do
        local ok, result = pcall(fn)
        if ok then
            return true, result
        end
        warn(string.format("[Retry] Attempt %d/%d failed: %s", attempt, maxRetries, tostring(result)))
        if attempt < maxRetries then
            task.wait(delay * attempt)  -- Exponential-ish backoff
        end
    end
    return false, nil
end
```

### 6.3 Never Silently Fail

```lua
-- ❌ BAD: Silent failure
pcall(function() DataStore:SetAsync(key, data) end)

-- ✅ GOOD: Log and handle
local ok, err = pcall(function()
    DataStore:SetAsync(key, data)
end)
if not ok then
    warn("[DataManager] Save failed for", key, ":", err)
    -- Queue for retry
    table.insert(_saveRetryQueue, { key = key, data = data, attempts = 0 })
end
```

---

## 7. Performance Guidelines

| Rule | Target |
|------|--------|
| FPS floor (low-end mobile) | 30+ |
| FPS target (PC/console) | 60+ |
| Max active particle emitters on screen | 10 |
| Max particles per emitter (mobile) | 50 |
| Remote event debounce minimum | 0.2 seconds |
| DataStore save interval | 5 minutes (auto) + on leave |
| Streaming Enabled | Always on |
| Instance.new() in RenderStepped/Heartbeat | Prohibited |

### 7.1 Profiling

- Use MicroProfiler (Ctrl+F6 in Studio) before optimizing
- Measure, don't guess
- Profile on lowest-target device (old iPad, budget Android)
- Check memory usage with Stats panel

### 7.2 Mobile-First Design

- Touch targets minimum 44x44 pixels
- UI scales with ViewportSize
- No hover states (no mouseover tooltips without tap alternative)
- Virtual joystick for movement
- Action buttons (E, C, M, F) as screen buttons
- Test with one hand (portrait) and two hands (landscape)

---

## 8. Code Organization (Explorer Hierarchy)

```
game
├── ServerScriptService
│   ├── GameManager          (Script — entry point)
│   ├── DataManager          (ModuleScript)
│   ├── MoteSystem           (ModuleScript)
│   ├── ProgressionSystem    (ModuleScript)
│   ├── StaminaSystem        (ModuleScript)
│   ├── BlessingSystem       (ModuleScript)
│   ├── LoreSystem           (ModuleScript)
│   ├── TrialManager         (ModuleScript)
│   └── CrossPlatformBridge  (ModuleScript)
├── StarterPlayer
│   └── StarterPlayerScripts
│       ├── ClientController     (LocalScript — entry point)
│       ├── UIManager            (ModuleScript)
│       ├── StaminaUI            (ModuleScript)
│       ├── LoreCodexUI          (ModuleScript)
│       ├── BlessingEffects      (ModuleScript)
│       └── LevelUpCinematic     (ModuleScript)
├── ReplicatedStorage
│   ├── Config
│   │   ├── Layers       (ModuleScript)
│   │   ├── Fragments    (ModuleScript)
│   │   ├── Trials       (ModuleScript)
│   │   └── Cosmetics    (ModuleScript)
│   ├── Packages
│   │   ├── Signal       (ModuleScript)
│   │   ├── Promise      (ModuleScript)
│   │   └── ProfileStore (ModuleScript)
│   └── Types            (ModuleScript — shared type definitions)
└── StarterGui
    └── (UI ScreenGuis created by UIManager at runtime)
```

---

## 9. Git Workflow

### 9.1 Branch Naming

| Type | Format | Example |
|------|--------|---------|
| Feature | `feature/short-description` | `feature/wind-mechanic` |
| Bug fix | `fix/short-description` | `fix/mote-respawn-timing` |
| Docs | `docs/short-description` | `docs/update-gdd` |

### 9.2 Commit Messages

```
type: short description

feat: add Wind Channeling mechanic to Stormwall
fix: mote collection not persisting on rejoin
docs: update halo economy sink rates
refactor: extract rate limiter to shared module
test: add StaminaSystem unit tests
```

### 9.3 PR Checklist

- [ ] Code passes `selene` linting
- [ ] Code formatted with `stylua`
- [ ] No deprecated APIs (wait, spawn, delay)
- [ ] All RemoteEvent handlers validate input
- [ ] No client-side game state mutations
- [ ] Tested on mobile (if UI changes)
- [ ] Updated relevant doc (GDD, economy, etc.)

---

*Clean code is kind code. The next person reading this might be you at 2 AM.*
