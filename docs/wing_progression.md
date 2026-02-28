# Angel Cloud: The Cloud Climb — Wing Progression System

> **Last updated:** February 27, 2026
> **Version:** 1.0

---

## 1. Core Wing System

Wings are the primary visible progression indicator. They evolve automatically when players reach new Angel Levels. Wings are NOT purchasable — they are EARNED.

### 1.1 Base Wing Tiers

| Angel Level | Wing Set Name | Motes Required | Visual Description | Particle Effect |
|-------------|--------------|---------------|-------------------|-----------------|
| 1 - Newborn | Spark Wings | 0 | Tiny translucent nubs, faint white glow | Soft sparkle on jump |
| 2 - Young Angel | Fledgling Wings | 10 | Small feathered wings, soft white, gentle movement | Light trail when gliding |
| 3 - Growing Angel | Courage Wings | 25 | Medium wings, gold trim, visible feather detail | Gold dust on flap |
| 4 - Helping Angel | Kindness Wings | 50 | Large wings, cyan energy veins, flowing motion | Cyan energy trails |
| 5 - Guardian Angel | Resilience Wings | 100 | Full wingspan, purple lightning crackling along edges | Lightning spark on takeoff |
| 6 - Angel | Radiant Wings | 250 | Massive prismatic wings, shifting colors, aurora trails | Full aurora particle stream |

### 1.2 Wing Abilities by Tier

| Wing Tier | Glide | Flight | Shield | Wind Channel | Mentor Glow |
|-----------|-------|--------|--------|-------------|-------------|
| Spark | No | No | No | No | No |
| Fledgling | Yes | No | No | No | No |
| Courage | Yes | No | No | No | No |
| Kindness | Yes | No | Yes | No | No |
| Resilience | Yes | Yes | Yes | Yes | No |
| Radiant | Yes | Yes | Yes | Yes | Yes |

---

## 2. Cosmetic Wing Skins

Cosmetic skins change wing APPEARANCE only. They do not change abilities or indicate level. Purchased with Halos.

### 2.1 Earnable Skins (Free — No Halos Required)

These skins are earned through gameplay milestones. They cannot be purchased. They represent ACHIEVEMENT.

| Skin Name | Unlock Condition | Estimated Time to Earn | Visual |
|-----------|-----------------|----------------------|--------|
| Cloud Wisp | Collect 10 Lore Fragments | ~3-4 hours | Wispy, cloud-like translucent wings |
| Stardust | Complete 3 different Guardian Trials | ~5-6 hours | Glittering star-speckled wings |
| Moonbeam | Send 50 Angel Mails (lifetime total) | ~8-10 days (5/day) | Soft silver-blue luminescent wings |

### 2.2 Purchasable Skins (Halos)

| Skin Name | Rarity | Price | Visual |
|-----------|--------|-------|--------|
| Solar Flare | Rare | 500 | Warm orange-red with ember particles |
| Nebula | Rare | 500 | Deep purple with swirling gas cloud effect |
| Aurora Borealis | Epic | 1,200 | Shifting green-blue northern lights effect |
| Crystalline | Epic | 1,200 | Ice-crystal structured wings, refractive sparkle |
| Celestial | Legendary | 2,500 | Deep space black with constellation patterns that slowly rotate |

### 2.3 Exclusive Skins (Special Unlock)

| Skin Name | How to Unlock | Visual |
|-----------|-------------|--------|
| Dreamer | Easter Egg: The Founder's Loft | Soft pastel watercolor wings |
| Windwalker | Easter Egg: The First Breath | Transparent with visible wind currents |
| Stargazer | Collect all 65 Lore Fragments | Prismatic constellation map wings |
| Supporter | Cloud Supporter Game Pass | Gold-trimmed with "Supporter" badge glow |

---

## 3. Wing Gauge (Stamina System)

Introduced in Layer 3 (The Canopy). Governs flight/glide duration.

### 3.1 Gauge Specs

| Stat | Value |
|------|-------|
| Max Gauge | 100 units |
| Glide drain rate | 5 units/second |
| Flight drain rate | 10 units/second |
| Shield activation cost | 15 units (instant) |
| Wind Channel cost | 8 units per cycle |
| Passive regen (grounded) | 3 units/second |
| Reflection Pool regen | 10 units/second |
| Empty → full (grounded) | 33 seconds |
| Empty → full (Reflection Pool) | 10 seconds |

### 3.2 Gauge UI

Color-coded bar displayed below health/name:

| Gauge Level | Color | Feedback |
|-------------|-------|----------|
| 100–60% | Green | Normal |
| 59–30% | Yellow | Subtle pulse animation |
| 29–10% | Red | Fast pulse + warning sound |
| 9–0% | Flashing Red | Forced landing if flying, no glide |

### 3.3 HALT Integration

| Session Time | Gauge Modifier |
|-------------|---------------|
| 0–45 min | Normal drain rates |
| 45–90 min | 1.2x drain (20% faster) |
| 90–120 min | 1.4x drain (40% faster) |
| 120+ min | 1.4x drain + gentle UI banner |

---

## 4. Ascension Cinematic

Triggered when a player accumulates enough Motes to reach the next Angel Level.

### 4.1 Sequence (10 seconds)

| Time | Event |
|------|-------|
| 0.0s | Screen flash white. Player frozen in place. |
| 0.5s | Beam of light descends onto player from above. |
| 1.5s | Old wings dissolve into particles. |
| 2.5s | New wings materialize — feather by feather, with glow buildup. |
| 4.0s | Player lifts slightly off ground. Camera pulls back to show full wingspan. |
| 5.5s | Cloud staircase materializes pointing toward next layer. |
| 7.0s | UI celebration: "You are now a [Level Title]!" with new wing name. |
| 8.5s | Nearby players see a beacon of light (social proof). |
| 10.0s | Player regains control. Staircase remains for 30 seconds. |

### 4.2 Audio

- 0.0s: Chime hit
- 0.5s: Rising orchestral swell
- 2.5s: Wing materialization SFX (crystalline growth)
- 7.0s: Fanfare + celebration jingle
- Nearby players hear a distant chime when someone ascends

---

## 5. Wing Animation Specs

### 5.1 Idle

| Tier | Animation |
|------|-----------|
| Spark | Slight glow pulse (1.5s cycle) |
| Fledgling | Gentle fold/unfold (3s cycle) |
| Courage | Slow flap (4s cycle) + gold dust |
| Kindness | Flowing motion like underwater (5s cycle) |
| Resilience | Crackling energy + occasional lightning arc |
| Radiant | Continuous aurora flow + color shift |

### 5.2 Glide

All tiers: Wings spread wide, slight tilt with movement direction. Trail particles based on tier.

### 5.3 Flight (Tier 5+)

Strong flap animation (0.8s cycle). Particle burst on each downstroke. Speed lines at edges of screen.

### 5.4 Landing

Wings fold inward with a satisfying "whoosh" particle burst. Heavier tiers = bigger burst.

---

*Wings are the soul of Angel Cloud. Make every tier feel like a reward. Make Radiant Wings feel like a crown.*
