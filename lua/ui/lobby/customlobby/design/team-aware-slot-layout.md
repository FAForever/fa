# Team-aware slot layout (parked)

> **Status: parked (2026-06-22)** pending a decision on **where scenario
> information is stored** — see [Open question](#open-question). Resume once the
> scenario data model is settled.

A re-imagining of the CustomLobby players pane so the slot arrangement reflects the
team structure, instead of every player sharing one flat list with a per-row "team"
dropdown. Your team becomes *where you are* on screen, which removes a control and
makes balance readable at a glance.

This is part of the broader "tabs" lobby direction (player table on the left, a
single tabbed panel — Map / Options / Mods / Units — on the right, persistent chat).

## Layout is driven by `AutoTeams`

The layout reads the existing [`AutoTeams`](/lua/ui/lobby/lobbyOptions.lua) lobby
option (already host-authoritative and synced) — no new option needed:

| `AutoTeams` | Meaning | Layout | Column headers |
|---|---|---|---|
| `tvsb` | Top vs Bottom | **2 columns** | `TOP` / `BOTTOM` |
| `lvsr` | Left vs Right | **2 columns** | `LEFT` / `RIGHT` |
| `pvsi` | Odd vs Even | **2 columns** | `ODD` / `EVEN` |
| `manual` | host assigns on map | **flat list** | (team column shown) |
| `none` | no auto teams | **flat list** | (team column shown) |

The three binary auto-splits are inherently 2-team, so they map straight to two
columns. `none`/`manual` have no reliable 2-team structure, so they fall back to the
flat list. There is **no 4-team grid** — no stock `AutoTeams` mode produces four
fixed teams. (Open to letting `none` try columns when players happen to split 50/50,
but not assumed.)

## Layouts

### 2-column (headers follow the mode — shown here for `tvsb`)

```
+-------------------------------------------------+-----------------------------------------+
| PLAYERS                       Top vs Bottom     | [ Map ] Options  Mods  Units            |
| +----------------------+ +----------------------+ +-----------------------------------+   |
| | TOP          ~1842   | | BOTTOM       ~1790   | |          map preview              |   |
| | NL Jip *  UEF ###. x | | US Sprouto AEO ##.. x| |   . 2(top)      . 4(bot)          |   |
| | DE Tagada CYB ###. . | | AI Sorian  SER #### x| |   . 1(top)      . 3(bot)          |   |
| |  - open -            | |  - open -            | +-----------------------------------+   |
| |  - open -            | |  - open -            | CHAT                                    |
| +----------------------+ +----------------------+ [Jip] hf all                            |
| OBSERVERS:  Zock 1850             [+ obs]        | > _                                     |
+-------------------------------------------------+-----------------------------------------+
```

Headers swap with the mode: `LEFT`/`RIGHT` for `lvsr`, `ODD`/`EVEN` for `pvsi`. Each
block header shows team size + average rating, replacing the legacy "team ratings if
>2 teams" line.

### Flat list (`none` / `manual`)

```
PLAYERS                                       6 / 8
 #  CC  name        fac  col  team  cpu   rdy
 1  NL  Jip *       UEF  [4]   1    ###.  [x]
 2  US  Sprouto     AEO  [1]   1    ##..  [x]
 3  DE  Tagada      CYB  [7]   2    ###.  [ ]
 4  AI  Sorian      SER  [2]   2    ####  [x]
 5  --  - open -
 6  --  - open -
```

The per-row team dropdown only exists here (there's no positional rule to lean on).
`manual` is the same list — the host does the actual assignment by clicking map
markers, as today.

## Interaction model

- In 2-column mode the per-row team dropdown disappears; the auto-team is derived
  from **start position**, so the two columns literally mirror the map split.
- **Join / switch team** = take a spawn on that side: click the map, or click an
  `- open -` slot in a column (which picks a free spawn there). Client → host
  request; host applies. Host can drag any token (matches legacy swap/move).
- Compact cells: flag · name · faction · cpu · ready; colour swatch + full
  rating/ping on hover (reuse the CPU performance popover pattern). Right-click a
  cell = kick / move / →observer / AI personality.
- Observers sit in a thin strip under the blocks/list regardless of layout.

## How it maps onto the MVC structure

- A new **`CustomLobbyPlayersInterface`** component subscribes to `AutoTeams` +
  `SlotCount` + every slot, computes the strategy (2 columns vs flat list), and
  arranges the existing `CustomLobbySlotInterface` rows into team-group containers.
  The slot-row component barely changes — it gets re-parented / compacted.
- `CustomLobbyInterface` shrinks to: header, this players component (left), the
  tabbed panel (right), footer.
- No model changes beyond reading `AutoTeams` (already present on
  `CustomLobbyAuthoritativeModel` as part of game options / its own LazyVar).

## Open question

**How is a card's column decided for display?**

1. **Projected from start spot** — top-half spawns → `TOP`, etc. True to how
   auto-teams actually resolve at launch and visually consistent with the map, but
   needs the map's **spawn coordinates** loaded.
2. **By the `Team` field** — bucket Team 1 vs Team 2. Simple, no map dependency, but
   can drift from what auto-teams will do at launch.

Preference: **(1)** for honesty, with **(2)** as a pre-map fallback. This is exactly
why the design is parked — it depends on where scenario information (spawn data)
ends up being stored.
