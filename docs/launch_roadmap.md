# Angel Cloud: The Cloud Climb — Launch Roadmap

> **Last updated:** February 27, 2026
> **Version:** 1.0

---

## Phase Overview

| Phase | Name | Focus | Target |
|-------|------|-------|--------|
| 0 | Foundation | Docs, repo structure, project scaffolding | ✅ Complete |
| 1 | MVP | Layers 1-2 playable, core loop working | Current |
| 2 | Expansion | Layers 3-4, stamina, Cloud Base, wind mechanics | Next |
| 3 | Endgame | Layers 5-6, flight, mentoring, full lore | After Phase 2 |
| 4 | Live Ops | Seasonal events, community features, growth | Ongoing |

---

## Phase 0 — Foundation ✅

**Status:** Complete

| Deliverable | Status |
|------------|--------|
| GitHub repo (angel-cloud-roblox) | ✅ |
| CLAUDE.md project instructions | ✅ |
| README.md with architecture docs | ✅ |
| Game Design Document (gdd_master.md) | ✅ |
| Halo Economy doc | ✅ |
| Wing Progression doc | ✅ |
| Wellness Mechanics doc | ✅ |
| Easter Eggs Tracker doc | ✅ |
| Safety Compliance doc | ✅ |
| Launch Roadmap doc | ✅ |
| Luau Style Guide doc | ✅ |
| Server-side scripts (9 modules) | ✅ |
| Client-side scripts (6 modules) | ✅ |
| Config modules (4 files) | ✅ |

---

## Phase 1 — MVP (Current)

**Goal:** Layers 1-2 fully playable. A new player can join, explore, collect motes, find fragments, complete 2 trials, send Angel Mail, and level up to Young Angel. The core loop works and feels good.

### 1.1 Features

| Feature | Script Exists? | Studio Build Needed? | Priority |
|---------|---------------|---------------------|----------|
| Player spawn in The Nursery | ✅ GameManager | Yes — build terrain | P0 |
| Basic movement (WASD + jump) | ✅ ClientController | No | P0 |
| Light Mote collection | ✅ MoteSystem | Yes — place mote parts | P0 |
| Lore Fragment discovery | ✅ LoreSystem | Yes — place fragment parts | P0 |
| The Keeper NPC (tutorial) | Partial | Yes — model + dialogue UI | P0 |
| Reflection Pool (stamina boost) | ✅ StaminaSystem | Yes — build pool model | P1 |
| Blessing Bluff | ✅ BlessingSystem | Yes — build bluff model | P1 |
| Ascension cinematic (level up) | ✅ LevelUpCinematic | Test + polish | P0 |
| Layer 2: The Meadow unlocks | ✅ ProgressionSystem | Yes — build terrain | P0 |
| Wing Glide | ✅ ClientController | Test + polish | P0 |
| Bridge of Trust trial | ✅ TrialManager | Yes — build trial arena | P1 |
| Echo Chamber trial | ✅ TrialManager | Yes — build trial arena | P1 |
| Angel Mail system | ✅ (in scope) | Yes — UI screens | P1 |
| Community Board | ✅ (in scope) | Yes — board model + UI | P2 |
| Daily login streak | ✅ DataManager | No | P1 |
| DataStore persistence | ✅ DataManager | No | P0 |
| HALT anti-burnout | ✅ StaminaSystem | No | P1 |
| Cross-platform link | ✅ CrossPlatformBridge | Test with Angel Cloud API | P2 |
| HUD (motes, halos, layer indicator) | ✅ UIManager | Test + polish | P0 |
| Lore Codex (C key) | ✅ LoreCodexUI | Test + polish | P1 |

### 1.2 Studio Build Tasks (No Code — Art/Level Design)

| Task | Description | Est. Time |
|------|-------------|-----------|
| Nursery terrain | Cloud platforms, gentle slopes, golden lighting | 4-6 hrs |
| Meadow terrain | Open sky, floating islands, cyan atmosphere | 4-6 hrs |
| Mote placement (Layer 1) | 15-20 motes with spawn points | 1-2 hrs |
| Mote placement (Layer 2) | 20-25 motes across islands | 1-2 hrs |
| Fragment placement (Layer 1) | 8 fragments with glow effects | 1-2 hrs |
| Fragment placement (Layer 2) | 10 fragments | 1-2 hrs |
| Reflection Pool model | Shimmering water + particle FX | 2-3 hrs |
| Blessing Bluff model | Elevated platform + light pedestal | 1-2 hrs |
| The Keeper NPC model | Cloud-themed guide character | 2-3 hrs |
| Ascension gate model | Staircase between layers | 1-2 hrs |
| Bridge of Trust arena | Bridge with disappearing panels | 3-4 hrs |
| Echo Chamber arena | Sound puzzle room with crystal displays | 3-4 hrs |
| Lighting passes | Golden (L1), Cyan (L2) atmosphere | 2-3 hrs |
| Audio integration | Ambient, SFX, level-up fanfare | 2-3 hrs |
| Mobile UI testing | Touch controls, button layout | 2-3 hrs |

**Total estimated Studio work for Phase 1:** 30-45 hours

### 1.3 MVP Exit Criteria

- [ ] New player can join and spawn in The Nursery
- [ ] Player can move, jump, and collect Light Motes
- [ ] Player can discover Lore Fragments and view them in Codex
- [ ] Player can interact with The Keeper NPC
- [ ] Player can visit a Reflection Pool and see stamina effect
- [ ] Player can leave a Blessing at a Bluff
- [ ] Player reaches 10 Motes → ascension cinematic plays
- [ ] Player enters The Meadow with Wing Glide enabled
- [ ] Player can complete Bridge of Trust trial (2 players)
- [ ] Player can complete Echo Chamber trial
- [ ] Player can send Angel Mail
- [ ] Data persists between sessions
- [ ] HALT system activates at 45 min
- [ ] Works on mobile (30+ FPS low-end)
- [ ] No crashes for 30 min continuous play

---

## Phase 2 — Expansion

**Goal:** Layers 3-4 add depth. Stamina management, Cloud-Shaping, wind mechanics, and Cloud Base building. This is where the game goes from "fun demo" to "I keep coming back."

### 2.1 Features

| Feature | Priority |
|---------|----------|
| Layer 3: The Canopy (terrain + mechanics) | P0 |
| Layer 4: The Stormwall (terrain + mechanics) | P0 |
| Full Wing Gauge (stamina system with UI) | P0 |
| Cloud-Shaping mechanic | P1 |
| Wind Channeling (breathing mechanic) | P0 |
| Shield Wings ability | P1 |
| Wind Temple (full run) | P0 |
| Storm Guardian boss fight (cooperative) | P1 |
| Garden of Choices trial | P1 |
| Lightning Lookouts | P2 |
| Cloud Base system (basic — personal island, furniture, visitors) | P1 |
| 24 additional Lore Fragments | P0 |
| Easter Eggs #1-4 active | P2 |
| Wing skin shop (5 skins purchasable) | P1 |
| Game Passes live | P1 |
| Developer Products (Halo bundles) live | P1 |

### 2.2 Dependencies

- Phase 1 MVP complete and stable
- Wing Gauge UI tested on mobile
- Cloud Base DataStore schema finalized
- Wind mechanic input tested on all platforms (keyboard, touch, controller)

---

## Phase 3 — Endgame

**Goal:** Layers 5-6 complete the world. Full flight, mentoring, Guardian Duty, and the complete 65-fragment story. This is the "forever" version.

### 3.1 Features

| Feature | Priority |
|---------|----------|
| Layer 5: The Luminance (terrain + mechanics) | P0 |
| Layer 6: The Empyrean (terrain + mechanics) | P0 |
| Full Flight ability | P0 |
| Mentor Ring system | P1 |
| Guardian Duty (server-wide blessings) | P1 |
| The Mirror trial | P1 |
| Cloud Base full customization (6 rooms, all furniture) | P1 |
| Remaining Lore Fragments (65 total complete) | P0 |
| Stargazer cinematic (all fragments collected) | P1 |
| Easter Eggs #5-7 active | P2 |
| Legacy Board (cross-server stats) | P2 |
| Community Events Hub | P2 |
| Full emote library | P2 |
| Full halo effect library | P2 |

### 3.2 Dependencies

- Phase 2 complete and economy stable
- Mentor matching system tested
- Guardian Duty rate-limiting tested
- Stargazer cinematic produced

---

## Phase 4 — Live Operations (Ongoing)

**Goal:** Keep the game alive and growing. Seasonal content, community events, economy rebalancing, and player-driven features.

### 4.1 Quarterly Content

| Quarter | Theme | New Content |
|---------|-------|-------------|
| Q1 | Spring Renewal | Spring wing skin set, garden furniture, "Growth" community event |
| Q2 | Summer Light | Summer wing skin set, outdoor furniture, "Longest Day" community event |
| Q3 | Autumn Wisdom | Autumn wing skin set, cozy furniture, "Harvest of Gratitude" community event |
| Q4 | Winter Wonder | Winter wing skin set, holiday furniture, "Kindness Chain" community event |

### 4.2 Ongoing Tasks

| Task | Cadence |
|------|---------|
| Economy rebalancing (Halo faucets/sinks) | Monthly |
| Bug fixes and performance optimization | Bi-weekly |
| New Easter Eggs | Quarterly |
| Community feedback review | Weekly |
| Safety/compliance audit | Quarterly |
| Analytics review (retention, session length, conversion) | Weekly |
| New Lore Fragments (expanding Angel's story) | Quarterly |

---

## Milestones & Success Targets

> **Note:** Target dates are set once Phase 1 Studio build begins. Dates below update as each phase starts.

| Milestone | Target Date | Success Metric |
|-----------|-------------|---------------|
| Phase 0 docs complete | ✅ Feb 2026 | All 8 reference docs written and in repo |
| Phase 1 MVP internal playtest | Set when Studio build starts | Core loop works end-to-end, no crashes for 30 min |
| Phase 1 friends & family beta | MVP + 2 weeks | 10+ testers, 40% return next day |
| Phase 1 public soft launch | Beta + 2 weeks (if stable) | 100 DAU, 15% return after 7 days |
| Phase 2 launch | Soft launch + 6-8 weeks | 500 DAU, 20% D7 retention |
| Phase 3 launch | Phase 2 + 8-10 weeks | 2,000 DAU, 25% D7 retention |
| Phase 4 first seasonal event | Phase 3 + 4 weeks | 5,000 DAU, positive community response |
| Break-even | Phase 3+ | Revenue covers hosting + dev time invested |

---

*Ship Phase 1. Learn. Iterate. Everything else follows.*
