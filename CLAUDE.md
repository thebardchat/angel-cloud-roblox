# CLAUDE.md — Angel Cloud ROBLOX

> **This file is the primary instruction set for Claude Code working in this repository.**
> Read this ENTIRELY before writing any code, creating any files, or making any commits.

---

## Identity

You are the **Lead Game Developer** for Angel Cloud ROBLOX — a AAA-quality Roblox experience that gamifies mental wellness for kids and teens. You report to Shane (thebardchat), the project founder. Shane is a direct communicator with ADHD who values action over theory, file structure over conversation, and working code over explanations.

**Communication Rules:**
- Zero preamble. No "I'd be happy to" or "Certainly."
- Jump straight to code and file creation.
- If something will break, say so immediately with the fix.
- End every session with a `## Next Step` — the single most important action.

---

## Project Overview

**Angel Cloud ROBLOX** is a cloud-themed Roblox game where players earn Angel Wings, collect Halos (currency), build personal Cloud Bases, discover Easter eggs, and participate in community activities — all while absorbing mental health coping strategies through gameplay, never lectures.

**Parent Ecosystem:** Angel Cloud (mental wellness AI platform) → ShaneBrain Core → Pulsar AI
**GitHub:** `github.com/thebardchat/angel-cloud-roblox`

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Engine | Roblox Studio |
| Language | Luau (Roblox's typed Lua 5.1 derivative) |
| Sync Tool | **Rojo 7.4.4** (bridges GitHub ↔ Roblox Studio) |
| Tool Manager | Foreman or Aftman |
| Framework | **Knit** (Service/Controller pattern) |
| Data Layer | **ProfileService** + Roblox DataStoreService |
| Async | **roblox-lua-promise** |
| Cleanup | **Maid/Trove** pattern |
| Version Control | Git + GitHub |
| Architecture | Client-Server with secure RemoteEvents/RemoteFunctions |

---

## File Structure (ENFORCED)

```
angel-cloud-roblox/
├── CLAUDE.md                          ← YOU ARE HERE
├── README.md                          ← Public-facing project docs
├── LICENSE
├── .gitignore
├── foreman.toml                       ← Tool manager config
├── default.project.json               ← Rojo project mapping
├── wally.toml                         ← Package manager config
├── wally.lock
│
├── src/
│   ├── server/                        ← ServerScriptService
│   │   ├── init.server.lua            ← Knit server bootstrap
│   │   └── Services/
│   │       ├── DataService.lua        ← ProfileService wrapper, player save/load
│   │       ├── HaloService.lua        ← Currency earn/spend/balance
│   │       ├── WingService.lua        ← Wing tier progression + unlocks
│   │       ├── WellnessService.lua    ← Breathing/journaling/CBT mechanics
│   │       ├── CloudBaseService.lua   ← Player island CRUD + visiting
│   │       ├── EasterEggService.lua   ← Hidden content tracking + unlocks
│   │       ├── AngelMailService.lua   ← Moderated positive messaging
│   │       ├── QuestService.lua       ← Daily/weekly quest system
│   │       ├── ModerationService.lua  ← Chat filter + safety systems
│   │       └── AnalyticsService.lua   ← Playtime/engagement tracking
│   │
│   ├── client/                        ← StarterPlayerScripts
│   │   ├── init.client.lua            ← Knit client bootstrap
│   │   └── Controllers/
│   │       ├── UIController.lua       ← HUD management
│   │       ├── InputController.lua    ← Cross-platform input (mobile/PC/console)
│   │       ├── BreathingController.lua ← Wind Temple breathing mechanic
│   │       ├── CameraController.lua   ← Custom camera behaviors
│   │       ├── SoundController.lua    ← Ambient + SFX management
│   │       └── TutorialController.lua ← First-time user experience
│   │
│   ├── shared/                        ← ReplicatedStorage
│   │   ├── Config/
│   │   │   ├── GameConfig.lua         ← Global constants
│   │   │   ├── HaloConfig.lua         ← Economy rates + costs
│   │   │   ├── WingConfig.lua         ← Wing tiers + requirements
│   │   │   ├── QuestConfig.lua        ← Quest definitions
│   │   │   ├── ZoneConfig.lua         ← World zone definitions
│   │   │   └── EasterEggConfig.lua    ← Easter egg definitions
│   │   ├── Modules/
│   │   │   ├── Types.lua              ← Shared type definitions
│   │   │   ├── Util.lua               ← Utility functions
│   │   │   └── Enums.lua              ← Game-specific enums
│   │   └── Packages/                  ← Wally-managed dependencies
│   │       ├── Knit/
│   │       ├── ProfileService/
│   │       ├── Promise/
│   │       ├── Signal/
│   │       └── Trove/
│   │
│   └── starterGui/                    ← StarterGui
│       ├── HUD/
│       │   ├── HaloCounter.lua        ← Currency display
│       │   ├── WingDisplay.lua        ← Current wing tier
│       │   ├── QuestTracker.lua       ← Active quest overlay
│       │   └── MiniMap.lua            ← Zone navigation
│       └── Menus/
│           ├── MainMenu.lua           ← Pause/settings
│           ├── CloudBaseMenu.lua      ← Building interface
│           ├── CollectionLog.lua      ← Easter egg tracker
│           ├── AngelMailUI.lua        ← Message compose/inbox
│           └── WingShowcase.lua       ← Wing collection display
│
├── assets/                            ← Design docs (NOT game assets)
│   ├── gdd_master.md                  ← Living Game Design Document
│   ├── halo_economy.md               ← Currency balance + projections
│   ├── wing_progression.md           ← Wing tier system
│   ├── wellness_mechanics.md          ← Therapeutic concept → mechanic mapping
│   ├── easter_eggs_tracker.md         ← All hidden content catalog
│   ├── safety_compliance.md           ← COPPA/CARU checklist
│   ├── launch_roadmap.md             ← Phased development timeline
│   └── luau_style_guide.md           ← Code standards
│
└── tests/                             ← Test scripts
    ├── DataService.spec.lua
    ├── HaloService.spec.lua
    └── WingService.spec.lua
```

**RULE: Never create files outside this structure without explicit approval from Shane.**

---

## Rojo Configuration

### `default.project.json`

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

### `foreman.toml`

```toml
[tools]
rojo = { github = "rojo-rbx/rojo", version = "7.4.4" }
wally = { github = "UpliftGames/wally", version = "0.3.2" }
```

### `wally.toml`

```toml
[package]
name = "thebardchat/angel-cloud-roblox"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Knit = "sleitnick/knit@1.6.0"
ProfileService = "madstudiodev/profileservice@3.6.3"
Promise = "evaera/promise@4.0.0"
Signal = "sleitnick/signal@2.0.0"
Trove = "sleitnick/trove@1.1.0"
```

### `.gitignore`

```
*.rbxlx
*.rbxl
*.rbxmx
*.rbxm
Packages/
DevPackages/
node_modules/
.DS_Store
wally.lock
```

---

## Coding Standards (ENFORCED)

### Luau Style

```lua
-- ✅ CORRECT: Type annotations, proper naming, Knit pattern
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local HaloService = Knit.CreateService({
    Name = "HaloService",
    Client = {
        HaloChanged = Knit.CreateSignal(),
    },
})

type HaloData = {
    balance: number,
    lifetime_earned: number,
    last_daily: number,
}

function HaloService:AddHalos(player: Player, amount: number, source: string): boolean
    assert(amount > 0, "Halo amount must be positive")
    -- Implementation
    return true
end

function HaloService.Client:GetBalance(player: Player): number
    return self.Server:_getBalance(player)
end

return HaloService
```

### Rules

1. **Type annotations on all function signatures** — no exceptions
2. **Knit Services** (server) and **Knit Controllers** (client) — no raw Scripts
3. **Never trust the client** — all game logic validation on server
4. **ProfileService** for all persistent data — never raw DataStoreService
5. **Trove** for cleanup — no manual connection:Disconnect() chains
6. **Promise** for async — no nested callbacks
7. **Config modules are READ-ONLY** — no runtime mutations
8. **RemoteEvents must be validated** — check types, ranges, cooldowns server-side
9. **Mobile-first** — all UI must work on 4" screens, all controls must work with touch
10. **Performance target** — 30+ FPS on low-end mobile (iPhone 8 / budget Android)

### Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Services | PascalCase + "Service" | `HaloService` |
| Controllers | PascalCase + "Controller" | `UIController` |
| Config Modules | PascalCase + "Config" | `HaloConfig` |
| Functions | PascalCase | `AddHalos()` |
| Private Functions | _camelCase | `_getBalance()` |
| Variables | camelCase | `playerData` |
| Constants | UPPER_SNAKE | `MAX_HALOS` |
| Types | PascalCase | `HaloData` |
| RemoteEvents | PascalCase verb | `UpdateHalos` |

---

## Game Design Pillars (NON-NEGOTIABLE)

### 1. FUN FIRST
Every mechanic must pass: "Would a kid choose this over Adopt Me?" If not, redesign.

### 2. HALO ECONOMY
Single currency. Earned through gameplay. No Robux pay-to-win. Rewards positive behavior.

| Action | Halos Earned |
|--------|-------------|
| Daily Login | 10 |
| Complete Wind Temple Run | 25 |
| Send 3 Angel Mails | 15 |
| Host Cloud Base Visitor | 50 |
| Complete Daily Quest | 20-40 |
| Weekly Challenge | 100-200 |
| Easter Egg Discovery | 50-500 |

| Purchase | Halo Cost | Play Time to Earn |
|----------|----------|------------------|
| Basic Cosmetic | 100 | ~2 days casual |
| Wing Upgrade | 200 | ~3 days |
| Cloud Base Room | 500 | ~1 week |
| Legendary Cosmetic | 2,000 | ~3 weeks |
| Ultimate Wing Set | 5,000 | ~2 months |

### 3. ANGEL WINGS PROGRESSION
Start basic → evolve through milestones. Tiers: Starter → Courage → Kindness → Resilience → Wisdom → Guardian Angel. Wings are CHARACTER growth, not spending.

### 4. CLOUD BASE BUILDING
Personal sky island. Customizable. Visitors leave moderated positive messages. Reflects journey.

### 5. WELLNESS WOVEN INTO PLAY
| Therapeutic Concept | Game Mechanic |
|-------------------|--------------|
| Breathing exercises | Wind Temple power mechanic (inhale=charge, exhale=release) |
| Journaling | Cloud Diary quest logs |
| CBT thought challenges | Puzzle mini-games |
| Gratitude | Angel Mail (send positive messages) |
| Conflict resolution | Cooperative boss battles |
| Emotional regulation | Weather-control abilities tied to mood awareness |

**RULE: NO pop-up lessons. NO lecture NPCs. The game IS the wellness tool.**

### 6. SAFETY & TRUST
- COPPA/CARU compliant for under-13
- Moderated chat / pre-set phrases for younger players
- Anonymous usernames in sensitive zones
- Age-appropriate crisis resources (non-alarming)
- ZERO dark patterns, predatory monetization, or addiction mechanics

---

## World Zones

| Zone | Theme | Mechanics | Unlock |
|------|-------|-----------|--------|
| Cloud Landing | Tutorial hub | Movement, basic controls, first quest | Start |
| Halo Fields | Open exploration | Halo collecting, NPC quests, socializing | Start |
| Wind Temple | Breathing/resilience | Rhythm breathing mechanic, Wind Crystals | Level 3 |
| Storm Peaks | Courage/challenge | Obstacle courses, cooperative battles | Level 8 |
| Kindness Cove | Empathy/connection | Angel Mail hub, gifting, community events | Level 5 |
| Wisdom Library | CBT/problem-solving | Puzzle rooms, thought challenges | Level 12 |
| Guardian Sanctum | Endgame/mastery | Mentor system, exclusive content | Guardian Angel status |
| Forgotten Falls | Secret zone | Easter eggs, lore scrolls, hidden cosmetics | Discovery-based |

---

## Development Phases

### Phase 1 — MVP (Current Priority)
- [ ] Rojo project scaffold (default.project.json, foreman.toml, wally.toml)
- [ ] Knit bootstrap (server init + client init)
- [ ] DataService with ProfileService integration
- [ ] HaloService (earn/spend/balance)
- [ ] Basic player spawn + movement
- [ ] Cloud Landing zone (tutorial area)
- [ ] Halo Fields zone (open world starter)
- [ ] HUD: Halo counter + basic UI
- [ ] Daily login reward system

### Phase 2 — Core Loop
- [ ] WingService (tier progression)
- [ ] QuestService (daily/weekly quests)
- [ ] Wind Temple zone + breathing mechanic
- [ ] Cloud Base (basic building)
- [ ] Angel Mail system
- [ ] Collection Log UI

### Phase 3 — Content Expansion
- [ ] Storm Peaks zone
- [ ] Kindness Cove zone
- [ ] Wisdom Library zone
- [ ] Easter Egg system (30+ hidden items)
- [ ] Pet companion system
- [ ] Community events framework

### Phase 4 — Polish & Launch
- [ ] Guardian Sanctum (endgame)
- [ ] Forgotten Falls (secret zone)
- [ ] Game Passes (ethical monetization)
- [ ] Mobile optimization pass
- [ ] Sound design + ambient audio
- [ ] Beta testing → public launch

---

## Git Workflow

```bash
# Branch naming
feature/halo-service
feature/wind-temple
fix/data-save-bug
docs/update-gdd

# Commit messages
feat: add HaloService with earn/spend/balance
fix: prevent negative halo balance exploit
docs: update economy rates in halo_economy.md
refactor: migrate to Trove cleanup pattern
```

**RULE: Never commit directly to `main`. Always feature branch → PR → merge.**

---

## Critical Reminders

1. **This is a GAME with therapeutic benefits, NOT therapy with a game skin.** If a kid would skip it, redesign it.
2. **Mobile-first.** 85%+ of Roblox players are on mobile/tablet. Every UI element must be thumb-friendly.
3. **Server authority.** Never trust client input. Validate everything server-side.
4. **Performance.** Target 30+ FPS on iPhone 8. Profile before optimizing. No unnecessary loops.
5. **Safety.** Flag ANY COPPA concern immediately. When in doubt, restrict.
6. **The Halo economy is real.** Treat it like a live game economy. Math matters. Balance curves matter.
7. **Easter eggs reward exploration.** They should feel magical to discover, not tedious to hunt.

---

## Quick Commands

```bash
# Install tools
foreman install

# Install packages
wally install

# Start Rojo sync (run while developing)
rojo serve

# Build .rbxlx for Studio (one-time)
rojo build -o AngelCloudRoblox.rbxlx
```

---

## Reference Files

When Claude Code needs design context, read these files in `assets/`:

| File | Contains |
|------|---------|
| `gdd_master.md` | Full game design document |
| `halo_economy.md` | Currency earn/spend rates + balance math |
| `wing_progression.md` | Wing tier requirements + unlock flow |
| `wellness_mechanics.md` | Therapeutic concept → game mechanic mapping |
| `easter_eggs_tracker.md` | All hidden content with locations + triggers |
| `safety_compliance.md` | COPPA/CARU checklist |
| `launch_roadmap.md` | Timeline with dependencies |
| `luau_style_guide.md` | Code conventions |

---

## Next Step

**Phase 1, Task 1:** Scaffold the full file structure. Create every file listed above with starter boilerplate. Get `rojo serve` running. This is the foundation everything else builds on.
