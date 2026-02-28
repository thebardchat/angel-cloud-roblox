# Angel Cloud: The Cloud Climb — Game Design Document

> **Living document. Updated as systems are designed and tested.**
> **Last updated:** February 27, 2026
> **Version:** 2.0
> **Status:** Phase 1 — MVP Build

---

## 1. Game Overview

**Title:** Angel Cloud: The Cloud Climb
**Genre:** Cooperative Adventure / Social Collectathon with embedded wellness mechanics
**Platform:** Roblox (PC, Mobile, Console, VR)
**Target Audience:** Primary 6–13 / Secondary 13–19 / Tertiary Parents & Educators
**Max Players Per Server:** 30
**Core Fantasy:** *"You are an angel-in-training ascending through cloud layers, earning your wings, collecting wisdom, and lifting others higher."*

### 1.1 One-Sentence Pitch

A cooperative Roblox game where players ascend six cloud layers, collect Lore Fragments telling a real story, earn Angel Wings through character growth, and absorb mental wellness tools through gameplay — never lectures.

### 1.2 Design Pillars

| # | Pillar | Rule |
|---|--------|------|
| 1 | **Fun First** | Every mechanic passes the "Would a kid choose this over Adopt Me?" test |
| 2 | **Cooperative, Not Competitive** | No PvP, no individual leaderboards, no toxic ranking |
| 3 | **Earn, Don't Buy** | Light Motes (progression) and Halos (currency) reward effort, not spending |
| 4 | **Grow Your Wings** | Progression reflects emotional growth, not grind |
| 5 | **Hidden Depth** | Lore Fragments, Easter eggs, and secrets reward curiosity |
| 6 | **Safe Space** | COPPA compliant, ethically monetized, zero dark patterns |

### 1.3 Competitive Positioning

| Feature | Love, Your Mind World | Super U Story | Angel Cloud: The Cloud Climb |
|---------|----------------------|---------------|------------------------------|
| Gameplay depth | Obby / survey | Single-player story | Full persistent world with 6 layers |
| Progression | None | Linear completion | Angel level system with wing evolution |
| Social systems | Chat only | None | Angel Mail, Blessings, Cloud Bases, Community Board |
| Replayability | Low (one visit) | Low (finish story) | High (daily loops, events, 65 collectibles, wing sets) |
| Wellness integration | Explicit (surveys, prompts) | Clinical (structured CBT) | Invisible (mechanics ARE the therapy) |
| Monetization | Free | Free | Cosmetics-only, ethical Game Passes |

---

## 2. Core Gameplay Loop

```
[Spawn in Current Layer] → [Explore / Collect Light Motes] → [Discover Lore Fragments]
         ↑                                                              ↓
[Ascend to Next Layer] ← [Level Up (Ascension Cinematic)] ← [Complete Guardian Trials]
         ↑                                                              ↓
[Unlock New Abilities] ← [Customize Wings / Cloud Base] ← [Earn Halos from Activities]
```

**Primary Loop (5–10 min):** Explore current layer → collect Motes → find Fragments → return
**Secondary Loop (15–30 min):** Complete a Guardian Trial → earn major rewards → level up
**Tertiary Loop (Session):** Customize Cloud Base → send Angel Mail → host visitors → participate in Blessings
**Meta Loop (Multi-session):** Ascend all 6 layers → collect all 65 Fragments → unlock all wing sets → reach Angel status

**Session Target:** 15–30 minute satisfying loops with natural stopping points (HALT system enforces healthy breaks)

---

## 3. World Design — The Six Layers

The game world is a vertical column of cloud layers. Players ascend by earning Light Motes through exploration, cooperation, and completing trials. Each layer introduces new mechanics, atmosphere, and story.

### 3.1 Layer Overview

| Layer | Name | Level Required | Motes to Unlock | Theme Color | New Mechanic |
|-------|------|---------------|-----------------|-------------|--------------|
| 1 | The Nursery | Newborn | 0 | Warm Gold | Basic movement, tutorial |
| 2 | The Meadow | Young Angel | 10 | Soft Cyan | Wing Glide, Cooperative Bridges |
| 3 | The Canopy | Growing Angel | 25 | Emerald Green | Full Stamina system, Cloud-Shaping |
| 4 | The Stormwall | Helping Angel | 50 | Electric Purple | Wind mechanics (breathing), Shield Wings |
| 5 | The Luminance | Guardian Angel | 100 | Radiant White | Full Flight, Mentor Ring |
| 6 | The Empyrean | Angel | 250 | Prismatic / Aurora | All abilities maxed, Guardian Duty |

### 3.2 Layer Detail — The Nursery (Layer 1)

**Purpose:** Onboarding. Teach movement, mote collection, and the game's feel without a single tutorial popup.
**Atmosphere:** Warm golden light, soft cloud platforms, gentle ambient music. Feels like sunrise.
**Layout:** A sheltered cloud valley with gentle slopes, no fall damage, clear sightlines to the first Mote clusters.

**Key Features:**
- **The Keeper NPC** — Tutorial guide. Gives first quest ("Collect 3 Light Motes nearby"). Also handles cross-platform account linking via 6-digit code entry.
- **Light Mote Clusters** — 15-20 motes scattered at ground level with bobbing animation and particle trails. Impossible to miss. Satisfying collect sound + haptic feedback.
- **First Lore Fragment** — Fragment #1 ("The Beginning") placed on a slightly elevated platform, glowing visibly. Teaches players that glowing objects contain story.
- **Reflection Pool** — A shimmering pool that restores stamina faster. Players learn to seek these out. (Wellness: introduces the concept of "taking a pause to recharge" — no label needed.)
- **Blessing Bluff** — A ledge where players can leave a small light for the next player. First taste of the pay-it-forward system.
- **Ascension Gate** — Visible staircase leading upward, locked until 10 Motes. Creates aspiration.

**Wellness Mechanics (Invisible):**
- Reflection Pool = grounding/pause practice (no label)
- Blessing Bluff = gratitude/generosity (no label)
- The Keeper's dialogue = gentle affirmations woven into quest text

**Lore Fragments in Layer 1:** 8 total (Decision type + Emotion type)
**Guardian Trial:** None (unlocks in Layer 2)

### 3.3 Layer Detail — The Meadow (Layer 2)

**Purpose:** First real gameplay expansion. Wing Glide introduces vertical exploration. Cooperative Bridges require helping others.
**Atmosphere:** Open cyan sky, rolling cloud hills, wildflower-like light particles floating everywhere. Feels like a spring morning.
**Layout:** Wide open meadow with floating islands at varying heights. Some islands only reachable by gliding.

**Key Features:**
- **Wing Glide Unlock** — Players earn basic wings. Hold Space to glide from high points. Smooth, satisfying animation with wind particle trails.
- **Cooperative Cloud Bridges** — Gaps between islands that require 2+ players standing on pressure pads simultaneously. Teaches cooperation naturally.
- **Guardian Trial: Bridge of Trust** — First trial. Players must cross a bridge together where panels disappear if only one player stands on them. Requires communication and trust. Rewards: 15 Motes + "Trust" Lore Fragment.
- **Guardian Trial: Echo Chamber** — Sound-matching puzzle. Players hear emotional tones and must select the matching response. (Wellness: emotional recognition disguised as audio puzzle.) Rewards: 15 Motes + "Listening" Lore Fragment.
- **Angel Mail Unlock** — Players can now send curated positive messages to other players. Pre-written options for under-13 safety. ("You're doing great!" / "Thanks for helping!" / "Your wings look awesome!")
- **Community Board** — Communal board showing collective server achievements. NOT individual rankings. "Together we've collected 1,247 Motes today!"

**Wellness Mechanics (Invisible):**
- Cooperative Bridges = trust-building, asking for help
- Bridge of Trust trial = vulnerability, interdependence
- Echo Chamber trial = emotional recognition, active listening
- Angel Mail = gratitude practice, positive communication

**Lore Fragments in Layer 2:** 10 total (Decision + Emotion + 2 Guardian)
**New Abilities:** Wing Glide, Angel Mail

### 3.4 Layer Detail — The Canopy (Layer 3)

**Purpose:** Depth expansion. Full stamina management adds strategic layer. Cloud-Shaping lets players alter the environment.
**Atmosphere:** Dense emerald canopy of cloud-trees, dappled light filtering through, hidden clearings. Feels like exploring a cloud forest.
**Layout:** Vertical forest with platforms at multiple heights. Hidden paths behind cloud-foliage.

**Key Features:**
- **Full Stamina System (Wing Gauge)** — Flying/gliding now drains a visible Wing Gauge. Rest at Reflection Pools to recover. Color-coded feedback: green (full) → yellow (half) → red (low) → flashing (critical).
- **HALT Anti-Burnout System** — If a player has been active 45+ minutes without pause, the Wing Gauge drains faster and Reflection Pools glow brighter. Subtle nudge to take a break. If 90+ minutes, a gentle NPC comment: "Even angels rest their wings sometimes." Never blocks gameplay.
- **Cloud-Shaping** — Players can mold small cloud platforms to create paths for others. Persists for the session. (Wellness: creative expression, helping others navigate.)
- **Guardian Trial: The Garden of Choices** — Branching scenario puzzle. Players face story situations and choose responses. No "wrong" answers, but different choices reveal different Lore Fragments. (Wellness: decision-making practice, consequence awareness.)
- **Secret Clearings** — Hidden spaces behind cloud-foliage containing rare Lore Fragments and cosmetic rewards.

**Wellness Mechanics (Invisible):**
- Wing Gauge = self-regulation, resource management (energy/burnout awareness)
- HALT system = healthy boundary-setting with screen time
- Cloud-Shaping = creative expression, altruism
- Garden of Choices = decision-making skills, CBT-informed cognitive flexibility

**Lore Fragments in Layer 3:** 12 total
**New Abilities:** Full Stamina system, Cloud-Shaping

### 3.5 Layer Detail — The Stormwall (Layer 4)

**Purpose:** Challenge layer. Wind mechanics test skill and introduce breathing-based gameplay. Shield Wings add protection.
**Atmosphere:** Dark purple storm clouds, lightning flashes in the distance, strong wind currents. Feels dramatic but not scary — exciting, like flying through a thunderstorm in a movie.
**Layout:** Narrow paths through storm clouds with wind currents that push players. Safe pockets between gusts.

**Key Features:**
- **Wind Mechanics (Breathing)** — Wind gusts push players off platforms. To resist, players must "channel wind energy" by matching a breathing rhythm: inhale (charge shield) → exhale (release burst). Each successful cycle builds a Wind Crystal. The breathing IS the mechanic.
- **Wind Temple** — Ancient cloud spirits are fading. Players restore them by collecting 5 Wind Crystals (5 successful breathing cycles). Completing the temple unlocks the Storm Guardian boss fight.
- **Storm Guardian Boss Fight** — Cooperative boss. 3-5 players work together, each channeling wind energy. Boss attacks with gusts; players counter with synchronized breathing bursts. (Wellness: group breathing exercise disguised as an epic boss fight.)
- **Shield Wings** — New wing ability. Briefly blocks incoming wind damage. Costs stamina.
- **Lightning Lookouts** — Vantage points where players can see the entire world below. Lore Fragments here reflect on how far the player has come. (Wellness: perspective-taking, recognizing growth.)

**Wellness Mechanics (Invisible):**
- Wind resistance = diaphragmatic breathing practice
- Wind Temple = structured breathing exercise (5 cycles)
- Storm Guardian = group breathing, synchronized regulation
- Lightning Lookouts = perspective-taking, gratitude for progress

**Lore Fragments in Layer 4:** 12 total
**New Abilities:** Wind Channeling (breathing mechanic), Shield Wings

### 3.6 Layer Detail — The Luminance (Layer 5)

**Purpose:** Mastery layer. Full flight unlocked. Mentor Ring allows experienced players to guide newer ones.
**Atmosphere:** Brilliant white light, crystalline cloud structures, cathedral-like spaces. Feels sacred and earned.
**Layout:** Vast open sky with crystal platforms. Maximum verticality — full flight required.

**Key Features:**
- **Full Flight** — No more glide-only. Players can fly freely (still limited by Wing Gauge). This feels EARNED after 4 layers of progression.
- **Mentor Ring** — Players can opt into a "Mentor" role, getting matched with newer players in lower layers. Mentors earn bonus Halos and exclusive "Guide" wing effects. (Wellness: purpose, generativity, helping behavior.)
- **Crystal Codex Rooms** — Private spaces where players can review all collected Lore Fragments in a constellation map (press C). Fragments glow when connected thematically.
- **Guardian Trial: The Mirror** — Solo trial. Player faces shadow versions of choices they made in The Garden of Choices (Layer 3). Explores "What would I do differently?" (Wellness: self-reflection, cognitive reappraisal.)
- **Wisdom Wells** — Interact to receive a random wisdom quote from the Lore. Shareable via Angel Mail.

**Wellness Mechanics (Invisible):**
- Mentor Ring = prosocial behavior, purpose, teaching skills
- The Mirror trial = self-reflection, cognitive reappraisal (CBT)
- Crystal Codex = journaling/reflection through collection review
- Wisdom Wells = positive self-talk reinforcement

**Lore Fragments in Layer 5:** 12 total
**New Abilities:** Full Flight, Mentor Ring

### 3.7 Layer Detail — The Empyrean (Layer 6)

**Purpose:** Endgame. Maximum agency, community leadership, and the game's emotional payoff.
**Atmosphere:** Prismatic aurora, shifting colors, the peak of the cloud world. Stars visible above. Feels like standing on top of everything.
**Layout:** The summit. A wide circular platform with views of all layers below. Community gathering space.

**Key Features:**
- **Guardian Duty** — Angel-level players gain the ability to spawn temporary helping effects in lower layers for all players. Drop a "Blessing Rain" that gives everyone in a layer bonus Motes for 5 minutes. (Wellness: generosity, community stewardship.)
- **The Founder's Loft (Easter Egg)** — Hidden room accessible only by performing the "Reflect" emote on a specific cloud during in-game sunset. Contains Lore Scroll #7 ("The First Cloud") and exclusive "Dreamer" halo cosmetic.
- **Angel's Story Completion** — Collecting all 65 Lore Fragments reveals the complete story of Angel Brazelton. The final fragment plays a cinematic. (This is the emotional core of the game.)
- **Community Events Hub** — Server-wide events launch from here. Seasonal content, group challenges, special wing sets.
- **Legacy Board** — Shows how many total Blessings have been given across ALL servers. "The Cloud has shared 2,847,391 Blessings."

**Wellness Mechanics (Invisible):**
- Guardian Duty = leadership, stewardship, giving back
- Legacy Board = collective impact awareness, belonging
- Story completion = narrative therapy, meaning-making
- Community Events = social connection, shared purpose

**Lore Fragments in Layer 6:** 11 total (including final cinematic fragment)
**New Abilities:** Guardian Duty, all abilities maxed

---

## 4. Progression System

### 4.1 Angel Levels

Progression mirrors the real Angel Cloud platform. Light Motes are the sole progression currency — earned through exploration, trials, cooperation, and Blessings.

| Level | Title | Motes Required | Cumulative Motes | Layer Unlocked | Estimated Time |
|-------|-------|---------------|-----------------|----------------|---------------|
| 1 | Newborn | 0 | 0 | The Nursery | 0 min |
| 2 | Young Angel | 10 | 10 | The Meadow | 30 min |
| 3 | Growing Angel | 25 | 25 | The Canopy | 2 hours |
| 4 | Helping Angel | 50 | 50 | The Stormwall | 5 hours |
| 5 | Guardian Angel | 100 | 100 | The Luminance | 12 hours |
| 6 | Angel | 250 | 250 | The Empyrean | 30 hours |

**Ascension Cinematic:** Each level-up triggers a 10-second cinematic — beam of light, wings transform, cloud staircase appears, UI celebration. This is the dopamine hit. Make it feel INCREDIBLE.

### 4.2 Light Mote Sources

| Source | Motes Earned | Frequency | Notes |
|--------|-------------|-----------|-------|
| Mote Pickup (world) | 1 | Respawn every 5 min | Scattered everywhere, bobbing animation |
| Lore Fragment Discovery | 3 | One-time per fragment | 65 total = 195 lifetime motes |
| Guardian Trial Completion | 15 | One-time per trial | 7 trials = 105 lifetime motes |
| Blessing Given | 2 | Unlimited (cooldown 30s) | Pay-it-forward mechanic |
| Blessing Chain (3+) | 5 bonus | Per chain | Chains reward sustained kindness |
| Daily Login (Day 1-6) | 2 | Once daily | Streak system |
| Daily Login (Day 7) | 10 | Weekly | Big weekly reward |
| Cross-Platform Link | 10 | One-time | Connects to Angel Cloud web platform |
| Mentor Session | 3 | Per 10 min mentoring | Layer 5+ only |

### 4.3 Wing Progression

Wings are the primary visible status symbol. They evolve automatically at each Angel Level.

| Angel Level | Wing Set | Visual Description |
|-------------|----------|-------------------|
| Newborn | Spark Wings | Tiny translucent nubs, faint glow |
| Young Angel | Fledgling Wings | Small feathered wings, soft white |
| Growing Angel | Courage Wings | Medium wings, gold trim, stronger glow |
| Helping Angel | Kindness Wings | Large wings, cyan energy trails |
| Guardian Angel | Resilience Wings | Full wingspan, purple lightning effects |
| Angel | Radiant Wings | Massive prismatic wings, aurora particle trail |

**Cosmetic Wing Skins:** Players can purchase alternate wing skins with Halos (currency, NOT Motes). Skins change appearance only — they don't affect gameplay or indicate higher level. Available in the shop: 5 base skins (3 free earnable, 2 premium).

---

## 5. Economy — Dual Currency System

### 5.1 Currency Overview

| Currency | Purpose | How Earned | Spendable On |
|----------|---------|-----------|--------------|
| **Light Motes** | Progression (Angel Level) | Exploration, trials, cooperation | Cannot be spent — only accumulated |
| **Halos** | Cosmetic purchases | Daily activities, Angel Mail, hosting, events | Wing skins, Cloud Base items, emotes, cosmetics |

Motes are NEVER purchasable. Halos are earnable AND purchasable (via ethical Game Passes — see Section 8).

### 5.2 Halo Earn Rates

| Activity | Halos Earned | Frequency |
|----------|-------------|-----------|
| Daily Login | 10 | Once/day |
| Complete Wind Temple Run | 25 | Repeatable (1 hr cooldown) |
| Send 3 Angel Mails to different players | 15 | Once/day |
| First-time Cloud Base visitor hosting | 50 | One-time |
| Host a visitor at Cloud Base | 10 | Per visitor, max 5/day |
| Complete any Guardian Trial | 30 | Repeatable (24 hr cooldown) |
| Participate in Community Event | 40 | Per event |
| Discover Easter Egg | 100 | One-time per egg |
| 7-Day Login Streak Bonus | 50 | Weekly |

**Casual Player (~20 min/day):** ~60 Halos/day → 420/week
**Active Player (~45 min/day):** ~130 Halos/day → 910/week
**Dedicated Player (~90 min/day):** ~200 Halos/day → 1,400/week

### 5.3 Halo Spend Rates (Sinks)

| Item Category | Price Range (Halos) | Casual Player Time | Active Player Time |
|--------------|--------------------|--------------------|-------------------|
| Basic Wing Skin | 200 | 3.3 days | 1.5 days |
| Premium Wing Skin | 800 | 13 days | 6 days |
| Cloud Base Furniture (common) | 50 | 1 day | 0.4 days |
| Cloud Base Furniture (rare) | 300 | 5 days | 2.3 days |
| Emote | 150 | 2.5 days | 1.2 days |
| Legendary Cosmetic | 2,000 | 33 days | 15 days |
| Exclusive Halo Effect | 1,500 | 25 days | 11.5 days |

**Sink/Faucet Balance Target:** Players should always have something to save for. New content drops should introduce sinks faster than inflation. Review monthly.

---

## 6. Social Systems

### 6.1 Angel Mail

Pre-written positive messages players can send to any player on the same server. Under-13 safe — no free-text input.

**Message Categories:**
- Encouragement: "You're doing great!" / "Keep climbing!" / "Your wings are getting stronger!"
- Gratitude: "Thanks for helping me!" / "You made my day!" / "Glad we're on the same server!"
- Compliments: "Your Cloud Base is awesome!" / "Love your wing skin!" / "You're a great mentor!"

**Sending limit:** 10 Angel Mails per day (prevents spam, keeps it meaningful)
**Receiving:** Notification + sparkle effect on recipient's character + 2 Halos for sender

### 6.2 Blessing System

**Blessing Bluffs** are located in every layer. A player can "leave a light" (costs nothing, 30-second cooldown). The next player who visits that Bluff receives a small Mote bonus (+2).

**Blessing Chains:** If 3+ consecutive players leave lights without breaking the chain, all participants receive a bonus (+5 Motes each). Chain counter visible at each Bluff. Server record displayed on Community Board.

**Guardian Duty Blessings (Layer 6 only):** Angel-level players can trigger "Blessing Rain" — a server-wide 5-minute buff giving all players +1 bonus Mote per pickup. Cooldown: 30 minutes per Guardian. Visual: golden particle rain across the layer.

### 6.3 Cloud Base (Personal Sky Island)

Every player gets a personal cloud island accessible from any layer. Starts as a small platform; expands as player levels up.

| Angel Level | Cloud Base Size | Rooms Available |
|-------------|----------------|-----------------|
| Newborn | Small platform | 1 (Main room) |
| Young Angel | Small island | 2 (+ Garden) |
| Growing Angel | Medium island | 3 (+ Workshop) |
| Helping Angel | Large island | 4 (+ Gallery) |
| Guardian Angel | Grand island | 5 (+ Mentor Hall) |
| Angel | Sky Palace | 6 (+ Observatory) |

**Customization:** Furniture, wall colors, lighting, cloud formations — all purchasable with Halos.
**Visitors:** Friends (and Mentor matches) can visit. Visitors can leave a positive message on the Guestbook (pre-written, moderated). Hosting visitors earns Halos.
**Display:** Collected Lore Fragments appear as glowing constellation points in the Observatory. Wing sets displayed on mannequins in the Gallery.

### 6.4 Community Board

Server-wide, NON-individual board displayed in each layer hub. Shows:
- Total Motes collected today (all players combined)
- Longest active Blessing Chain
- Total Angel Mails sent today
- Newest player to ascend to a new layer ("Welcome [Player] to The Canopy!")

**Design Rule:** NEVER show individual rankings. NEVER create FOMO. Community achievement only.

---

## 7. Wellness Mechanics Mapping

Every therapeutic concept is a game mechanic. Players should never realize they're "doing therapy."

| Therapeutic Concept | Game Mechanic | Layer Introduced | Player Experience |
|--------------------|--------------|-----------------|-------------------|
| Diaphragmatic breathing | Wind Channeling (inhale=charge, exhale=release) | 4 - Stormwall | "I'm fighting the storm with wind power!" |
| Emotional recognition | Echo Chamber trial (match emotional tones) | 2 - Meadow | "This sound puzzle is tricky!" |
| Gratitude practice | Angel Mail (send positive messages) | 2 - Meadow | "I want to thank that player who helped me" |
| Self-regulation / energy management | Wing Gauge stamina system | 3 - Canopy | "I need to manage my flight energy" |
| Healthy screen time boundaries | HALT anti-burnout system | 3 - Canopy | Subtle — gauge drains faster after 45 min |
| Decision-making / consequences | Garden of Choices trial | 3 - Canopy | "My choices unlocked different story paths!" |
| Cognitive reappraisal (CBT) | The Mirror trial (revisit past choices) | 5 - Luminance | "What would I do differently now?" |
| Trust and vulnerability | Bridge of Trust trial | 2 - Meadow | "We have to work together to cross!" |
| Generosity / pay-it-forward | Blessing Bluffs + Guardian Duty | 1+ / 6 | "I want to help the next player" |
| Self-reflection / journaling | Lore Codex (review collected fragments) | All | "Let me check my constellation map" |
| Perspective-taking | Lightning Lookouts (view world below) | 4 - Stormwall | "Wow, I can see how far I've come" |
| Mentorship / teaching | Mentor Ring system | 5 - Luminance | "I'm matched with a new player to guide" |
| Community belonging | Community Board + Legacy Board | All / 6 | "Together we've done something amazing" |
| Creative expression | Cloud-Shaping + Cloud Base building | 3+ | "I'm making my own space in this world" |
| Grounding / mindful pause | Reflection Pools (stamina recovery) | 1 - Nursery | "I'll rest here a sec, my gauge is low" |

---

## 8. Monetization Strategy

### 8.1 Core Principles
1. **ZERO pay-to-win.** Purchases are cosmetic ONLY.
2. **Free players get the full game.** Every layer, trial, ability, and Lore Fragment is free.
3. **No loot boxes.** Players know exactly what they're buying.
4. **No artificial scarcity pressure.** Items don't disappear or create FOMO.
5. **No child-targeted dark patterns.** No "Are you sure you don't want this?" popups.

### 8.2 Game Passes

| Game Pass | Price (Robux) | What It Provides |
|-----------|--------------|-----------------|
| Cloud Supporter | 99 | Exclusive "Supporter" wing trail effect + 500 bonus Halos + badge |
| Halo Boost | 199 | 2x Halo earn rate for 30 days (does NOT affect Motes/progression) |
| Cloud Base Expansion | 149 | 2 extra customization slots per room + exclusive furniture set |
| Angel Mail Plus | 49 | Unlock 10 additional Angel Mail message options + animated send effect |

### 8.3 Developer Products (Repeatable Purchases)

| Product | Price (Robux) | What It Provides |
|---------|--------------|-----------------|
| 500 Halos | 49 | Cosmetic currency only |
| 1,500 Halos | 99 | Cosmetic currency only |
| 5,000 Halos | 249 | Cosmetic currency only |

### 8.4 Revenue Projection (Conservative)

Target: 1% conversion rate on Game Passes, 0.5% on Developer Products.
At 1,000 DAU: ~$15-25/day → ~$450-750/month
At 10,000 DAU: ~$150-250/day → ~$4,500-7,500/month
At 100,000 DAU: ~$1,500-2,500/day → ~$45,000-75,000/month

---

## 9. Easter Egg System

### 9.1 Design Philosophy
Easter eggs reward curiosity and exploration. Every secret ties into the Angel Cloud lore. Discovered eggs are tracked in a Collection Log accessible from the Lore Codex (press C).

### 9.2 Confirmed Easter Eggs

| # | Name | Location | Trigger | Reward |
|---|------|----------|---------|--------|
| 1 | The Founder's Loft | The Empyrean | Stand on 3rd cloud platform during in-game sunset + "Reflect" emote | Lore Scroll #7 ("The First Cloud") + "Dreamer" halo cosmetic |
| 2 | Cloud 9 | The Meadow | Find and stand on exactly the 9th floating island (subtle numbering in cloud texture) | "Cloud 9" emote (floating happy dance) + 100 Halos |
| 3 | The First Breath | The Stormwall | Complete Wind Temple with zero damage taken | "Windwalker" wing trail effect + Lore Fragment bonus |
| 4 | Angel's Whisper | The Nursery | Stand still at the Reflection Pool for 60 real seconds (meditation easter egg) | Ambient music changes to a special track + "Patience" badge + 50 Halos |
| 5 | The Chain Unbroken | Any Blessing Bluff | Be part of a 10+ player Blessing Chain | "Chain Link" halo cosmetic + 200 Halos for all participants |
| 6 | Stargazer | The Luminance | Visit the Crystal Codex with all 65 Fragments collected | Full cinematic + "Stargazer" exclusive wing skin (prismatic) |
| 7 | The Hidden Floor | Between Layers 3-4 | Fly into a specific cloud formation during a lightning flash | Secret mini-room with developer message + "Explorer" badge |

### 9.3 Easter Egg Discovery Hints
Hints are scattered across NPC dialogue, Lore Fragment text, and environmental details. No hint is explicit — they require players to think, experiment, and share discoveries with the community.

---

## 10. Safety & Compliance

### 10.1 COPPA/CARU Compliance

| Requirement | Implementation |
|------------|---------------|
| No collection of personal info from under-13 | No free-text chat in gameplay zones. Pre-set phrases only. |
| Parental consent for data collection | Roblox handles account-level consent. Cross-platform link requires external action (not in-game). |
| No behavioral advertising | Zero ads in game. No third-party tracking. |
| Clear privacy practices | Link to privacy policy in game settings menu. |

### 10.2 Chat & Communication Safety

| Feature | Safety Measure |
|---------|---------------|
| Angel Mail | Pre-written messages only. No custom text. |
| Blessing Bluffs | No text component — action only. |
| Cloud Base Guestbook | Pre-written messages only. |
| Community Board | System-generated text only. No player input. |
| NPC Dialogue | All written by developers. |

### 10.3 Crisis Resource Integration

If a player searches for or enters specific keywords in any available text field (e.g., account linking), the game silently flags and presents age-appropriate resources:
- Under 13: "If you're feeling sad or scared, talk to a grown-up you trust. You can also text HOME to 741741."
- 13+: "If you or someone you know needs support, text HOME to 741741 (Crisis Text Line) or call 988 (Suicide & Crisis Lifeline)."

Presentation: Gentle, non-alarming, embedded in a "need help?" section of the settings menu. NEVER a popup.

### 10.4 Anti-Addiction Design (HALT System)

| Time Played | Response |
|-------------|----------|
| 0-45 min | Normal gameplay |
| 45-90 min | Wing Gauge drains 20% faster. Reflection Pools glow brighter. Subtle. |
| 90+ min | NPC comment: "Even angels rest their wings sometimes." Wing Gauge drains 40% faster. |
| 120+ min | Gentle UI banner: "You've been flying for a while! Take a break and come back refreshed." |

**Design Rule:** NEVER lock players out. NEVER force-quit. Just make resting feel natural.

---

## 11. Technical Architecture

### 11.1 Client-Server Model

```
CLIENT (LocalScripts)                    SERVER (Scripts)
├── ClientController.client.lua          ├── GameManager.server.lua
│   ├── Input handling                   │   ├── Player lifecycle
│   ├── Wing glide/flight               │   ├── System initialization
│   └── Action key (E)                   │   └── Update loop
├── UIManager.lua                        ├── DataManager.lua
│   ├── HUD                              │   └── ProfileStore persistence
│   └── Notifications                    ├── MoteSystem.lua
├── StaminaUI.lua                        ├── ProgressionSystem.lua
│   └── Wing Gauge display               ├── StaminaSystem.lua
├── LoreCodexUI.lua                      ├── BlessingSystem.lua
│   └── Constellation map (C key)        ├── LoreSystem.lua (65 fragments)
├── BlessingEffects.lua                  ├── TrialManager.lua
│   └── Visual FX                        └── CrossPlatformBridge.lua
└── LevelUpCinematic.lua                     └── Angel Cloud API integration
```

### 11.2 Data Persistence

- **Engine:** Roblox DataStoreService via ProfileStore v2 (session-locked)
- **Saved per player:** Motes, Angel Level, collected Fragments (bitmask), Halos, Cloud Base state, wing skins owned, Easter eggs found, Blessing count, daily login streak, HALT timer
- **Auto-save:** Every 5 minutes + on player leave
- **Cross-platform:** Optional link to Angel Cloud web platform via HTTP API (Tailscale VPN: `100.67.120.6:4200`)

### 11.3 Performance Targets

| Metric | Target |
|--------|--------|
| FPS (low-end mobile) | 30+ |
| FPS (PC/console) | 60+ |
| Max active particles per emitter | 50 (mobile) |
| Streaming Enabled | Yes (layers load/unload vertically) |
| Instance.new() in hot loops | Prohibited (use pooling) |
| Remote event debounce | 0.2s minimum |

---

## 12. Controls

| Input | Action | Mobile Equivalent |
|-------|--------|-------------------|
| WASD | Movement | Virtual joystick |
| F | Toggle Flight (fly/land) | Flight button |
| Space | Jump / Hold to Glide / Ascend while flying | Jump button (hold = glide) |
| E | Interact (NPCs, Reflection Pools, Blessing Bluffs) | Interact button |
| C | Open/Close Lore Codex | Codex button |
| M | Open/Close Angel Mail | Mail button |
| Shift | Descend while flying | Descend button |

---

## 13. Lore & Narrative

### 13.1 The Story of Angel

The game's 65 Lore Fragments tell the story of Angel Brazelton. Fragments are categorized:

| Type | Count | Content |
|------|-------|---------|
| Decision Fragments | 24 | Moments where Angel faced choices |
| Emotion Fragments | 24 | Moments of feeling — joy, fear, hope, grief |
| Guardian Fragments | 14 | Wisdom from those who guided Angel |
| Legendary Fragments | 3 | Key turning points in Angel's story |

**Narrative Arc:** Fragments are scattered non-linearly across all 6 layers. Players piece together the story like a constellation. The Lore Codex (C key) shows fragments as stars — connecting them reveals the full picture. Collecting all 65 triggers the "Stargazer" cinematic.

### 13.2 Lore Source

All wisdom text in Lore Fragments draws from WISDOM-CORE.md — the foundational wisdom document of the Angel Cloud ecosystem. Every fragment honors Angel and carries real, meaningful insight.

---

## 14. Launch Roadmap

### Phase 1 — MVP (Current)
- Layers 1-2 fully playable (The Nursery + The Meadow)
- Basic movement + Wing Glide
- Light Mote collection
- Newborn → Young Angel level-up with ascension cinematic
- 18 Lore Fragments
- 2 Guardian Trials (Bridge of Trust, Echo Chamber)
- Reflection Pools, Blessing Bluffs
- Community Board
- Angel Mail
- DataStore persistence
- HALT system
- Cross-platform link verification
- Daily login streak (7-day cycle)
- 5 wing skins (3 basic)
- Layer indicator UI

### Phase 2 — Expansion
- Layers 3-4 (The Canopy + The Stormwall)
- Full Stamina system (Wing Gauge)
- Cloud-Shaping mechanic
- Wind Channeling (breathing mechanic)
- Shield Wings
- 3 additional Guardian Trials
- 24 additional Lore Fragments
- Cloud Base system (basic)
- Easter Eggs #1-4

### Phase 3 — Endgame
- Layers 5-6 (The Luminance + The Empyrean)
- Full Flight
- Mentor Ring system
- Guardian Duty
- Cloud Base full customization
- Remaining Lore Fragments (65 total)
- Remaining Guardian Trials (7 total)
- Easter Eggs #5-7
- "Stargazer" cinematic

### Phase 4 — Live Operations
- Seasonal events (quarterly)
- New wing skin collections
- Community challenges
- Additional Easter Eggs
- Analytics-driven economy rebalancing
- Potential: new layers, new trials, expanded Cloud Bases

---

## 15. Success Metrics

| Metric | MVP Target | 6-Month Target |
|--------|-----------|----------------|
| DAU | 100 | 5,000 |
| D1 Retention | 40% | 50% |
| D7 Retention | 15% | 25% |
| D30 Retention | 5% | 12% |
| Avg Session Length | 15 min | 25 min |
| % Reaching Layer 2 | 60% | 75% |
| % Reaching Layer 4 | 10% | 25% |
| Angel Mail Sent/Day | 50 | 5,000 |
| Blessing Chains Avg Length | 3 | 5+ |
| Game Pass Conversion | 0.5% | 1.5% |

---

## Appendix A: File Reference & Cross-Reference

| File | Purpose | Must Agree With GDD Section |
|------|---------|---------------------------|
| `gdd_master.md` | This document — source of truth | N/A (this IS the source) |
| `halo_economy.md` | Currency balance, sink/faucet analysis | Section 5 (Economy) |
| `wing_progression.md` | Wing tier system, cosmetic skins, unlock requirements | Section 4.3 (Wing Progression) |
| `wellness_mechanics.md` | Full mapping of therapeutic concepts → game mechanics | Section 7 (Wellness Mapping) |
| `easter_eggs_tracker.md` | All hidden content, locations, triggers, rewards | Section 9 (Easter Eggs) |
| `luau_style_guide.md` | Code standards, naming conventions, module patterns | Section 11 (Technical Architecture) |
| `safety_compliance.md` | COPPA/CARU checklist, moderation systems | Section 10 (Safety) |
| `launch_roadmap.md` | Phased development timeline with milestones | Section 14 (Launch Roadmap) |

**Sync Rule:** If a number, name, or mechanic changes in any doc, update the GDD AND the relevant reference doc. If docs conflict, the GDD wins.

---

## Appendix B: Glossary

| Term | Definition |
|------|-----------|
| **Light Motes** | Progression currency. Earned through gameplay only. Cannot be purchased. Determines Angel Level. |
| **Halos** | Cosmetic currency. Earned through activities OR purchased with Robux. Buys wing skins, furniture, emotes. |
| **Angel Level** | Player's progression tier: Newborn → Young Angel → Growing Angel → Helping Angel → Guardian Angel → Angel. |
| **Wing Gauge** | Stamina bar governing flight/glide duration. Introduced in Layer 3. Color-coded (green/yellow/red). |
| **Lore Fragment** | Collectible story piece (65 total). Tells the story of Angel Brazelton. Tracked in Lore Codex constellation map. |
| **Guardian Trial** | Cooperative challenge instance. 7 total across all layers. Major Mote + Halo rewards. |
| **Blessing** | Pay-it-forward action at Blessing Bluffs. Gives next visitor +2 Motes. Chains of 3+ give +5 bonus to all. |
| **Angel Mail** | Pre-written positive message system. No free text. COPPA compliant. Sender earns Halos. |
| **Cloud Base** | Personal sky island. Expandable by Angel Level. Customizable with Halo-purchased furniture. |
| **HALT System** | Anti-burnout design. Subtly increases Wing Gauge drain after 45+ min sessions. Never blocks gameplay. |
| **Ascension** | Level-up cinematic. 10-second sequence: light beam, wing transformation, staircase, celebration UI. |
| **The Keeper** | Tutorial NPC in The Nursery (Layer 1). Handles onboarding quests and cross-platform account linking. |
| **Wind Channeling** | Breathing-based mechanic in The Stormwall (Layer 4). Inhale = charge, exhale = release wind burst. |
| **Mentor Ring** | Opt-in system (Layer 5+) matching Guardian Angels with newer players. Mentors earn bonus Halos. |
| **Guardian Duty** | Angel-level ability (Layer 6) to trigger server-wide blessing buffs for all players. |

---

*"Every Angel strengthens the cloud."*

*"Fun is the vehicle. Wellness is the destination."*
