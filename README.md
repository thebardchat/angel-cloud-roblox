# 🎮 angel-cloud-roblox

> Therapeutic Roblox game built on Luau, Rojo, and the Knit framework. Wing progression. Halo currency. Healing mechanics.

This project operates under the [ShaneTheBrain Constitution](https://github.com/thebardchat/constitution/blob/main/CONSTITUTION.md).

---

## What It Is

A Roblox game built as part of the Angel Cloud mental wellness platform. Players progress from "New Born" to "Angel" through therapeutic mechanics, earning Halo currency and unlocking wing progressions. Built to reach people — especially young people — where they already are.

## Stack

| Layer | Tech |
|-------|------|
| Language | Luau |
| Toolchain | Rojo |
| Framework | Knit |
| Data | ProfileService |
| Platform | Roblox |

## Design Pillars

- Crisis-first AI detection mechanics
- Halo trust metric system
- Wing progression as visual mental wellness journey
- ADHD-aware UI — clear next actions, no friction

## Built With

| Partner | Role |
|---------|------|
| **Claude by Anthropic** · [claude.ai](https://claude.ai) | Co-built every line |
| **Raspberry Pi 5** · [raspberrypi.com](https://www.raspberrypi.com) | Local dev node |
| **Pironman 5-MAX** · [pironman.com](https://www.pironman.com) | NVMe RAID 1 chassis |

> *Part of the [ShaneBrain Ecosystem](https://github.com/thebardchat/constitution) · Hazel Green, Alabama*

> _"Fun is the vehicle. Wellness is the destination."_

[![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF?style=flat&logo=roblox&logoColor=white)](https://www.roblox.com)
[![Luau](https://img.shields.io/badge/Language-Luau-00A2FF?style=flat)](https://luau-lang.org)
[![Rojo](https://img.shields.io/badge/Sync-Rojo%207.4-E13835?style=flat)](https://rojo.space)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](#license)

---

## What Is Angel Cloud ROBLOX?

Angel Cloud ROBLOX is a cloud-themed world where players earn **Angel Wings**, collect **Halos** (the only currency), build personal **Cloud Bases**, discover **Easter eggs**, and participate in community-building activities — all while absorbing mental health coping strategies through gameplay, never lectures.

A 7-year-old should find it fun. A 16-year-old should find it meaningful. A parent should find it trustworthy.

### Part of the Angel Cloud Ecosystem

Angel Cloud ROBLOX is the public-facing gateway into the **Angel Cloud** mental wellness AI platform, built on top of **ShaneBrain Core** — a local-first AI infrastructure system designed to put powerful, private AI into the hands of everyday families.

| Project | Purpose |
|---------|---------|
| [ShaneBrain Core](https://github.com/thebardchat/shanebrain-core) | Local AI infrastructure (Raspberry Pi 5 + Ollama + Weaviate) |
| **Angel Cloud ROBLOX** | Gamified mental wellness for kids & teens (you are here) |
| Pulsar AI | Blockchain-powered security layer (coming soon) |

---

## Game Features

### 🪽 Angel Wings Progression
Every player starts with basic wings that evolve through gameplay milestones. Wing tiers reflect emotional growth — Courage, Kindness, Resilience, Wisdom — culminating in **Guardian Angel** status. Wings are earned through character growth, not spending.

### 💰 Halo Economy
**Halos** are earned through gameplay: completing quests, helping other players, daily check-ins, mindfulness activities, and community events. There is no Robux pay-to-win. The economy rewards positive behavior and consistency.

### 🏗️ Cloud Base Building
Your personal sky island that you customize and expand. Invite friends, host mini-events, display collectibles, and receive positive messages from visitors.

### 🌬️ Wellness Woven Into Play
Breathing exercises become wind-power mechanics. Journaling becomes quest logs. Gratitude becomes Angel Mail. Conflict resolution becomes cooperative boss battles. **The game IS the wellness tool.**

### 🥚 Easter Eggs & Secrets
Hidden collectibles, secret areas, and lore scattered throughout every zone. Exploration is always rewarded.

### 🛡️ Safety First
COPPA/CARU compliant. Moderated communication. Age-appropriate design. Zero dark patterns. Zero predatory monetization.

---

## World Zones

| Zone | Theme | What You'll Do |
|------|-------|---------------|
| ☁️ Cloud Landing | Tutorial | Learn the basics, get your first wings |
| 🌾 Halo Fields | Exploration | Collect Halos, meet NPCs, socialize |
| 🌬️ Wind Temple | Breathing/Resilience | Rhythm breathing mechanic, earn Wind Crystals |
| ⛰️ Storm Peaks | Courage/Challenge | Obstacle courses, cooperative battles |
| 💙 Kindness Cove | Empathy/Connection | Angel Mail hub, gifting, community events |
| 📚 Wisdom Library | Problem-Solving | Puzzle rooms, thought challenges |
| ✨ Guardian Sanctum | Mastery/Endgame | Mentor others, exclusive content |
| 🌊 Forgotten Falls | Secrets | Hidden lore, rare cosmetics, Easter eggs |

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Engine | Roblox Studio |
| Language | Luau |
| GitHub ↔ Studio Sync | [Rojo 7.4](https://rojo.space) |
| Framework | [Knit](https://github.com/Sleitnick/Knit) |
| Data Persistence | [ProfileService](https://github.com/MadStudioRoblox/ProfileService) |
| Async | [roblox-lua-promise](https://github.com/evaera/roblox-lua-promise) |
| Package Manager | [Wally](https://wally.run) |
| Tool Manager | [Foreman](https://github.com/Roblox/foreman) |

---

## Getting Started

### Prerequisites

- [Roblox Studio](https://create.roblox.com) (free)
- [Git](https://git-scm.com)
- [Foreman](https://github.com/Roblox/foreman) (Rust toolchain manager for Roblox)
- [Rojo Plugin](https://create.roblox.com/store/asset/13916111004) installed in Roblox Studio

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/thebardchat/angel-cloud-roblox.git
cd angel-cloud-roblox

# 2. Install tools (Rojo + Wally)
foreman install

# 3. Install packages
wally install

# 4. Start live sync
rojo serve
```

Then in Roblox Studio, click the **Rojo** plugin button and hit **Connect**. All file changes sync live.

### Building

```bash
# Generate a .rbxlx file (for sharing/testing without live sync)
rojo build -o AngelCloudRoblox.rbxlx
```

---

## Project Structure

```
angel-cloud-roblox/
├── CLAUDE.md                  ← AI development instructions
├── README.md                  ← You are here
├── default.project.json       ← Rojo Studio mapping
├── foreman.toml               ← Tool versions
├── wally.toml                 ← Package dependencies
│
├── src/
│   ├── server/                ← Server-side game logic
│   │   ├── Services/          ← Knit Services (Halo, Wings, Data, Wellness, etc.)
│   │   └── init.server.lua    ← Server bootstrap
│   ├── client/                ← Client-side controllers
│   │   ├── Controllers/       ← Knit Controllers (UI, Input, Breathing, etc.)
│   │   └── init.client.lua    ← Client bootstrap
│   ├── shared/                ← Shared configs, types, utilities
│   │   ├── Config/            ← Game constants and balance numbers
│   │   ├── Modules/           ← Shared utility modules
│   │   └── Packages/          ← Wally-managed dependencies
│   └── starterGui/            ← UI components
│       ├── HUD/               ← In-game overlay (Halos, quests, minimap)
│       └── Menus/             ← Full-screen menus (Cloud Base, Collection Log, etc.)
│
├── assets/                    ← Design documents (not game assets)
│   ├── gdd_master.md          ← Game Design Document
│   ├── halo_economy.md        ← Economy balance spreadsheet
│   ├── wing_progression.md    ← Wing tier system
│   ├── wellness_mechanics.md  ← Therapeutic mechanics mapping
│   ├── easter_eggs_tracker.md ← Hidden content catalog
│   ├── safety_compliance.md   ← COPPA/CARU checklist
│   └── launch_roadmap.md      ← Development timeline
│
└── tests/                     ← Test scripts
```

---

## Development Workflow

This project uses **Rojo** to bridge GitHub and Roblox Studio. All code lives in `.lua` files in this repo — never in Studio's proprietary format.

```
You edit .lua files → Rojo syncs to Studio → You playtest in Studio → Commit to GitHub
```

### With Claude Code

This repo includes a `CLAUDE.md` file that instructs [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code) to act as the lead game developer. Claude Code can:

- Scaffold new services and controllers
- Write Luau code following project standards
- Generate config files with balanced economy numbers
- Create design documents
- Commit and push changes to this repo

```bash
# Open Claude Code in the repo and it reads CLAUDE.md automatically
cd angel-cloud-roblox
claude
```

### Branch Strategy

```bash
feature/halo-service      # New features
fix/data-save-bug          # Bug fixes
docs/update-gdd            # Documentation
```

Always branch from `main`. Never commit directly to `main`.

---

## Design Philosophy

### What Makes This Different

Most "wellness" Roblox experiences are glorified obbies with motivational posters. Angel Cloud ROBLOX is a **real game** with persistent progression, social systems, and replayable content that happens to make kids more emotionally resilient.

**Bad example:** "Players enter the Mindfulness Zone and watch a breathing tutorial."

**Our approach:** "Players discover the Wind Temple where ancient cloud spirits are fading. To restore them, players channel wind energy by matching a breathing rhythm (inhale = charge, exhale = release). Each successful cycle powers a Wind Crystal. Collect 5 crystals to unlock the Storm Guardian boss fight."

The breathing IS the mechanic. The wellness IS the game.

### Design Tests

Every feature must pass these checks:

1. **Fun Test:** Would a kid choose this over Adopt Me?
2. **Stealth Test:** Would a player realize they're learning a coping skill?
3. **Mobile Test:** Does this work with thumbs on a 4" screen?
4. **Safety Test:** Could this harm, exploit, or mislead a child?
5. **Economy Test:** Does this maintain healthy Halo earn/spend balance?

---

## Market Context

- **85.3M** daily active Roblox users, largest segment under 13
- **72%** of Roblox users ages 13-17 say mental health matters to them (Roblox 2024)
- "Love, Your Mind World" (Ad Council/Roblox, 2025) proved teen mental health experiences work on platform
- "Super U Story" demonstrated clinical effectiveness of Roblox-based wellness games (JMIR, 2025)
- Angel Cloud ROBLOX goes further: wellness isn't a feature — it's the game

---

## Contributing

This is currently a family project led by Shane ([thebardchat](https://github.com/thebardchat)). If you're interested in contributing, open an issue to start a conversation.

### Code Standards

- Luau with full type annotations
- Knit Service/Controller pattern
- Server-authoritative architecture (never trust the client)
- ProfileService for all persistent data
- Mobile-first UI design
- 30+ FPS target on low-end mobile

See `CLAUDE.md` for complete coding standards and conventions.

---

## Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 1 | MVP — Scaffold, data, economy, tutorial zones | 🔨 In Progress |
| Phase 2 | Core Loop — Wings, quests, Wind Temple, Cloud Bases | ⏳ Planned |
| Phase 3 | Content — All zones, Easter eggs, pets, events | ⏳ Planned |
| Phase 4 | Polish & Launch — Optimization, sound, beta, release | ⏳ Planned |

---

## The Mission

Angel Cloud ROBLOX is part of a bigger mission: **800 million Windows users** are about to lose security updates in October 2025. The Angel Cloud ecosystem — starting with ShaneBrain Core and extending through this game — is building the infrastructure to keep families safe, connected, and resilient in a digital world that doesn't always have their best interests in mind.

This game is how we reach the kids. The AI protects their data. The blockchain secures their future. It all starts with a cloud, a halo, and a pair of wings.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

**Built with ❤️ by Shane & the Angel Cloud team in Hazel Green, Alabama.**



---

## Support This Work

If what I'm building matters to you — local AI for real people, tools for the left-behind — here's how to help:

- **[Sponsor me on GitHub](https://github.com/sponsors/thebardchat)**
- **[Buy the book](https://www.amazon.com/Probably-Think-This-Book-About/dp/B0GT25R5FD)** — *You Probably Think This Book Is About You*
- **Star the repos** — visibility matters for projects like this

> This project operates under the [ShaneTheBrain Constitution](https://github.com/thebardchat/constitution/blob/main/CONSTITUTION.md).

Built by **Shane Brazelton** · Co-built with **Claude** (Anthropic) · Hazel Green, Alabama
