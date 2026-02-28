# Angel Cloud ROBLOX — Canonical Terminology Lock
**Decision Date**: 2026-02-27  
**Status**: LOCKED — Do not deviate

---

## Currency: HALOS (locked)

The one and only currency in Angel Cloud ROBLOX is **Halos**.  
No Robux pay-to-win. No secondary currency. No gems, coins, motes, or tokens.

### In-Game Display
- UI label: `🌟 250 Halos` (halo ring icon, gold color `#FFD700`)
- Earn notification: `+25 Halos`
- Shop prices listed as: `200 Halos`

---

## Full Terminology Map

| Deprecated Term | Canonical Term | Context |
|---|---|---|
| Coins | **Halos** | Primary currency |
| Motes | **Halos** | Currency (same thing, old name) |
| Light Motes | **Light Shards** | Collectible resource → converted to Halos at shrines |
| Mote Shrine | **Halo Shrine** | Conversion point in world |
| Brainrot collectibles | **Shadow Fragments** | Negative-energy collectibles (review for tone) |
| Angel Level | **Wing Tier** | Progression rank |
| Newborn → Empyrean | Keep as-is | Layer/tier names stay |

---

## File-by-File Rename Checklist

### ReplicatedStorage/Config/Types.lua
- [ ] `motes: number` → `halos: number`
- [ ] `collectedFragments` → keep (fragments are Light Shards, not currency)
- [ ] All references to `motes` in PlayerData type → `halos`

### ServerScriptService/GameManager.server.lua
- [ ] `data.motes` → `data.halos`
- [ ] Any `mote_collect` SFX key → `halo_collect`
- [ ] `AngelMotes` DataStore key → `AngelHalos` (CAREFUL: migration needed for existing saves)

### ServerScriptService/SoundManager.lua
- [ ] `mote_collect` → `halo_collect`

### ReplicatedStorage/Config/Fragments.lua
- [ ] "Light Motes" in lore text → "Light Shards" (lore-safe rewrite, not just find/replace)

### StarterPlayerScripts/ShopUI.lua
- [ ] Currency display label → "Halos"
- [ ] Price render: `item.price .. " Halos"`

### ServerScriptService/AngelMailSystem.lua
- [ ] Any reward references using motes → halos

---

## Halo Economy Snapshot (locked values)

| Activity | Halos Earned |
|---|---|
| Daily login | 10 |
| Light Shard shrine conversion (5 shards) | 25 |
| Complete a Trial | 50 |
| Send 3 Angel Mails | 15 |
| Blessing Chain (10 players) | 100 bonus |
| First Cloud Base visitor hosted | 50 |
| Weekly community event | 200 |

| Item | Halo Cost |
|---|---|
| Basic Wing Skin | 200 |
| Emote | 150 |
| Cloud Base room unlock | 300 |
| Pet Companion | 500 |
| Legendary Cosmetic | 2,000 |
| Guardian Angel title frame | 5,000 |

**Target progression**: Casual player earns ~75 Halos/day. First meaningful purchase in ~3 days. Legendary item in ~27 days of daily play.

---

## Wing Tier Names (locked from visual spec)

Based on concept art (IMG_7456):

| Tier | Name | Visual | Unlock |
|---|---|---|---|
| 1 | Tiny Spark | No wings, small glow | Start |
| 2 | Fledgling | Small white feathered | 100 Halos earned total |
| 3 | Courage | Large gold feathered | Complete Courage Trial |
| 4 | Kindness | Teal/cyan glowing | 10 Angel Mails sent |
| 5 | Resilience | Purple lightning | Survive Stormwall event |
| 6 | Radiant | Rainbow prismatic | All other tiers complete |

---

## DataStore Migration Warning

If any live player data exists with key `motes`, a migration script must run on first load:
```lua
-- In DataManager, on player load:
if data.motes and not data.halos then
    data.halos = data.motes
    data.motes = nil
end
```
Run this check for minimum 30 days post-rename before removing.
