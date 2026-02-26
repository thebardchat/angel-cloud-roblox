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
