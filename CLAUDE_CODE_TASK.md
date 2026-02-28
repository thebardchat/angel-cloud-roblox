# Claude Code — Angel Cloud ROBLOX Migration Task

## SITUATION

The repo has two conflicting architectures:

### OLD (currently exists in repo root):
```
ServerScriptService/
  GameManager.server.lua   (monolithic orchestrator)
  DataManager.lua
  MoteSystem.lua
  ProgressionSystem.lua
  StaminaSystem.lua
  BlessingSystem.lua
  LoreSystem.lua
  TrialManager.lua
  CrossPlatformBridge.lua
  + many more modules
StarterPlayerScripts/
  ClientController.client.lua
  UIManager.lua
  StaminaUI.lua
  LoreCodexUI.lua
  BlessingEffects.lua
  LevelUpCinematic.lua
ReplicatedStorage/
  Config/
    Layers.lua
    Fragments.lua
    Trials.lua
    Cosmetics.lua
```

### NEW (specified in CLAUDE.md, not yet built):
```
src/
  server/
    init.server.lua          (Knit bootstrap)
    Services/
      DataService.lua
      HaloService.lua
      WingService.lua
      WellnessService.lua
      CloudBaseService.lua
      MoteService.lua
      ProgressionService.lua
      BlessingService.lua
      LoreService.lua
      TrialService.lua
      AngelMailService.lua
      EasterEggService.lua
      HALTService.lua
  client/
    init.client.lua          (Knit bootstrap)
    Controllers/
      InputController.lua
      UIController.lua
      FlightController.lua
      BreathingController.lua
      LoreCodexController.lua
      CinematicController.lua
  shared/
    Config/
      Layers.lua
      Economy.lua
      Wings.lua
      Fragments.lua
      Trials.lua
      Cosmetics.lua
    Modules/
      Types.lua
      RateLimiter.lua
    Packages/               (Wally-managed)
  starterGui/
    HUD/
    Menus/
```

## YOUR TASK (IN ORDER)

### Step 1: Create the `src/` structure
Create every folder and file listed in the NEW structure above. Use the CLAUDE.md Knit patterns for all Services and Controllers.

### Step 2: Migrate logic from old files
- Read each old module in `ServerScriptService/` and `StarterPlayerScripts/`
- Port the LOGIC into the new Knit Service/Controller pattern
- GameManager.server.lua logic → split across relevant Services
- DataManager → DataService (use ProfileService)
- MoteSystem → MoteService
- ProgressionSystem → ProgressionService
- StaminaSystem → HALTService + WingService (stamina is wing gauge)
- BlessingSystem → BlessingService
- LoreSystem → LoreService
- TrialManager → TrialService
- CrossPlatformBridge → keep as standalone module in shared/Modules/
- ClientController → split into InputController + FlightController
- UIManager → UIController
- StaminaUI → merge into UIController
- LoreCodexUI → LoreCodexController
- BlessingEffects → merge into UIController (VFX section)
- LevelUpCinematic → CinematicController

### Step 3: Move Config files
- Copy `ReplicatedStorage/Config/*.lua` → `src/shared/Config/`
- Add `Economy.lua` config (pull numbers from `docs/halo_economy.md`)
- Add `Wings.lua` config (pull numbers from `docs/wing_progression.md`)

### Step 4: Update `default.project.json`
Make sure Rojo maps to `src/` structure, not old root folders:
```json
{
  "name": "AngelCloudRoblox",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/server"
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$path": "src/client"
      }
    },
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "$path": "src/shared"
    },
    "StarterGui": {
      "$className": "StarterGui",
      "$path": "src/starterGui"
    }
  }
}
```

### Step 5: Delete old folders
Once migration is verified, remove:
- `ServerScriptService/`
- `StarterPlayerScripts/`
- `ReplicatedStorage/`

### Step 6: Verify
- Run `rojo build -o test.rbxlx` to confirm Rojo can build
- Run `selene src/` if available
- Commit with message: `refactor: migrate to src/ Knit architecture`

## RULES
- Read `CLAUDE.md` FIRST for all coding standards
- Read `docs/gdd_master.md` for game design context
- Read `docs/halo_economy.md` for all currency numbers
- Read `docs/wing_progression.md` for wing tier specs
- Use Knit framework pattern for ALL services and controllers
- Type annotations on EVERY function signature
- Never trust client — validate everything server-side
- ProfileService for data persistence, NOT raw DataStoreService
- Branch: `feature/knit-migration`

## REFERENCE DOCS IN REPO
```
docs/gdd_master.md          ← Full game design
docs/halo_economy.md         ← Currency balance numbers
docs/wing_progression.md     ← Wing tier system
docs/wellness_mechanics.md   ← Therapy → mechanic mapping
docs/easter_eggs_tracker.md  ← Hidden content specs
docs/safety_compliance.md    ← COPPA requirements
docs/launch_roadmap.md       ← Phase plan
docs/luau_style_guide.md     ← Code standards
```
