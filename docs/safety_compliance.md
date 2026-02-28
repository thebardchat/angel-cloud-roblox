# Angel Cloud: The Cloud Climb — Safety & Compliance

> **Last updated:** February 27, 2026
> **Version:** 1.0
> **Regulatory frameworks:** COPPA, CARU Self-Regulatory Guidelines, Roblox Community Standards

---

## 1. COPPA Compliance Checklist

The Children's Online Privacy Protection Act applies to all users under 13.

| Requirement | Implementation | Status |
|------------|---------------|--------|
| No collection of personal information from under-13 without verifiable parental consent | No free-text input in game. Pre-set messages only. No name collection beyond Roblox username. | ✅ Compliant |
| Clear and comprehensive privacy policy | Privacy policy linked in Settings menu. Written in plain language. | ⬜ Draft needed — write before public launch. Template: Roblox Privacy Policy Generator + Angel Cloud-specific data practices. |
| Parental consent mechanism | Roblox platform handles account-level consent. Cross-platform linking requires action outside the game (web portal). | ✅ Delegated to Roblox |
| No behavioral advertising or third-party tracking | Zero ads. Zero third-party SDKs. Zero tracking pixels. | ✅ Compliant |
| No conditioning participation on data collection | All game content accessible without providing personal info. Cross-platform link is optional. | ✅ Compliant |
| Data minimization | Only gameplay data stored (Motes, Halos, progress). No PII beyond Roblox UserID. | ✅ Compliant |
| Reasonable data security | Roblox DataStoreService with session locking (ProfileStore v2). Server-side only. | ✅ Compliant |

---

## 2. CARU Self-Regulatory Guidelines

Children's Advertising Review Unit guidelines for child-directed content.

| Guideline | Implementation | Status |
|-----------|---------------|--------|
| Advertising must not mislead children | No advertising in game. Period. | ✅ N/A |
| No high-pressure sales tactics | No countdown timers, no "limited time" popups, no "Are you sure?" guilt screens | ✅ Compliant |
| Clear separation of content and commerce | Shop is a separate menu. Never interrupts gameplay. | ✅ Compliant |
| No exploitative monetization | Cosmetics only. No loot boxes. No pay-to-win. No gacha. | ✅ Compliant |
| Age-appropriate content | All content rated E. No violence, no horror, no sexual content, no substance references. | ✅ Compliant |

---

## 3. Roblox Community Standards Compliance

| Standard | Implementation | Status |
|----------|---------------|--------|
| No bypassing chat filters | All player communication uses pre-set messages. No free text. | ✅ Compliant |
| No exploitative monetization | See Halo Economy doc. No loot boxes, no pay-to-win. | ✅ Compliant |
| No discriminatory content | All content reviewed for inclusivity. Character customization is non-gendered. | ✅ Compliant |
| No misleading game descriptions | Store listing accurately describes gameplay. No bait-and-switch. | ⬜ Write at launch — draft listing text during Phase 1 beta. Include: genre, age range, no-PvP note, wellness mention without overpromising. |
| Age recommendation accuracy | Listed as "All Ages" with content appropriate for 6+ | ✅ Compliant |

---

## 4. Communication Safety

### 4.1 Chat Policy

| Zone | Chat Type | Free Text? |
|------|----------|-----------|
| General gameplay | Roblox default chat (filtered) | Yes (Roblox filter active) |
| Angel Mail | Pre-set messages only | No |
| Cloud Base Guestbook | Pre-set messages only | No |
| Community Board | System-generated only | No |
| Guardian Trials | Pre-set callouts only ("Help!", "Ready!", "Over here!") | No |
| Cross-platform link | 6-digit code entry only | No |

### 4.2 Pre-Set Message Library

All pre-set messages reviewed for:
- Positive tone (no sarcasm, no passive aggression)
- Inclusivity (no gendered language, no cultural assumptions)
- Simplicity (readable by 6-year-olds)
- Safety (no personal info requests, no location references)

### 4.3 Reporting System

Players can report other players via Roblox's built-in reporting system. Additional in-game "Flag" button on any received Angel Mail or Guestbook message (even though pre-set, for accountability).

---

## 5. Crisis Resource Integration

### 5.1 Access Point

Settings Menu → "Need Help?" section. Always accessible. Never a popup.

### 5.2 Age-Appropriate Resources

**For players under 13:**
- "If you're feeling sad or scared, talk to a grown-up you trust."
- "You can also text HOME to 741741 to talk to someone who cares."
- Simple, non-alarming language. No clinical terminology.

**For players 13+:**
- "If you or someone you know needs support:"
- "Text HOME to 741741 (Crisis Text Line)"
- "Call or text 988 (Suicide & Crisis Lifeline)"
- "You're not alone. It's okay to ask for help."

### 5.3 Trigger Detection

If any text input field (limited to cross-platform link code entry and Roblox default chat) detects crisis-related keywords, the "Need Help?" section glows subtly in the Settings menu. No popup. No disruption. Just availability.

**Keyword categories monitored (server-side):**
- Self-harm references
- Suicidal ideation language
- Abuse/violence references
- Extreme distress language

**Response:** Subtle UI indicator only. Never confrontational. Never blocks gameplay. The player controls whether they engage with resources.

---

## 6. Anti-Addiction Design (HALT System)

### 6.1 Time Thresholds

| Session Length | Response | Visibility |
|--------------|----------|-----------|
| 0–45 min | Normal gameplay | Invisible |
| 45–90 min | Wing Gauge drains 20% faster. Reflection Pools glow brighter. | Subtle (most players won't notice) |
| 90–120 min | NPC ambient comment: "Even angels rest their wings sometimes." Gauge drains 40% faster. | Noticeable but not disruptive |
| 120+ min | Gentle UI banner at top of screen: "You've been flying for a while! Take a break and come back refreshed." | Visible but dismissible |

### 6.2 Design Rules

- NEVER lock players out of gameplay
- NEVER force-quit or force-disconnect
- NEVER display countdown timers or "time remaining" warnings
- NEVER punish players for long sessions (no XP penalties, no currency loss)
- DO make resting feel natural and rewarding
- DO let Reflection Pools become more inviting as session extends

---

## 7. Monetization Ethics

### 7.1 Prohibited Practices

| Practice | Status | Reason |
|----------|--------|--------|
| Loot boxes / gacha | BANNED | Gambling mechanics targeting children |
| Pay-to-win | BANNED | Creates unfair advantage and pressure to spend |
| Artificial scarcity ("Only 2 hours left!") | BANNED | Creates FOMO and pressure in children |
| Confirmation shaming ("Are you SURE you don't want this?") | BANNED | Manipulative dark pattern |
| Hidden costs (items that require other purchases to use) | BANNED | Deceptive |
| Auto-renewing subscriptions | BANNED | Children can't meaningfully consent |
| Currency obfuscation (confusing exchange rates) | BANNED | Halos have clear, consistent value |
| Pop-up shop promotions during gameplay | BANNED | Interrupts play to sell |
| Showing other players' premium purchases to non-buyers | AVOIDED | Minimizes social pressure (cosmetics visible but never highlighted) |

### 7.2 Permitted Practices

| Practice | Status | Implementation |
|----------|--------|---------------|
| Cosmetic-only purchases | ALLOWED | Wing skins, furniture, emotes, halo effects |
| Game Passes (one-time) | ALLOWED | Clear descriptions, instant delivery |
| Developer Products (Halo bundles) | ALLOWED | Fixed amounts, no randomness |
| Earn-or-buy cosmetics | ALLOWED | Everything buyable with Halos is also earnable through play |

---

## 8. Data Handling

### 8.1 What We Store (Per Player)

| Data | Storage | Purpose | PII? |
|------|---------|---------|------|
| Roblox UserID | DataStore | Account identification | No (platform pseudonym) |
| Light Motes count | DataStore | Progression | No |
| Halos balance | DataStore | Currency | No |
| Collected Fragments (bitmask) | DataStore | Progress tracking | No |
| Wing skins owned | DataStore | Inventory | No |
| Cloud Base layout | DataStore | Customization | No |
| Easter Eggs found | DataStore | Achievement tracking | No |
| Blessing count | DataStore | Stats | No |
| Login streak | DataStore | Reward tracking | No |
| HALT session timer | Memory only | Anti-burnout | No (not persisted) |
| Cross-platform link code | Server memory | Account linking | Expires after 10 min |

### 8.2 What We Never Store

- Real names
- Email addresses
- Location data
- Device information beyond Roblox defaults
- Chat logs (handled by Roblox)
- Behavioral profiles
- Third-party identifiers

---

## 9. Content Review Process

Before any content goes live:

1. **Language review** — All NPC dialogue, Lore Fragments, and pre-set messages reviewed for age-appropriateness, inclusivity, and positive tone
2. **Mechanic review** — All new mechanics reviewed against wellness guidelines and dark pattern checklist
3. **Economy review** — All new items reviewed against monetization ethics guidelines
4. **Accessibility review** — Color-coded elements have secondary indicators (shape, text). Text meets minimum size for mobile.
5. **Safety review** — All interactive features reviewed for potential misuse

---

## 10. Incident Response

If a safety issue is discovered post-launch:

| Severity | Response Time | Action |
|----------|-------------|--------|
| Critical (exploitable for harm) | Immediate | Disable feature. Push hotfix. Notify Roblox. |
| High (unintended negative experience) | 24 hours | Patch or disable. Review root cause. |
| Medium (edge case misuse) | 1 week | Design fix. Test. Deploy. |
| Low (minor concern) | Next update | Add to backlog. Fix in next release. |

---

*Safety isn't a feature. It's the foundation. Every system is built on trust.*
