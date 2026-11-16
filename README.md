# Custom Party Glow

**Custom Party Glow** is a World of Warcraft addon that adds a pulsing, class-colored glow to you and your party / raid members on the world map, so they are easy to spot at a glance.

## Features

- Class-colored glow for every party or raid member on the world map (uses the game's class colors).
- Solid class-colored dot with a dark outline on each member, drawn above quest and objective pins (Questie, etc.) so members stay visible. It replaces the game's tiny party dot; can be turned off.
- Optional glow on yourself.
- Adjustable glow size, spread and opacity.
- All settings are saved per account and kept between sessions.

## Opening the options

Any of these opens (or closes) the options panel:

- **World map button**: top-right corner of the map (top-left on WoW Forever), stacked with Blizzard's filter buttons.
- **Minimap button**: drag it around the minimap edge to move it. It can be hidden from the options.
- **Addon compartment**: the minimap dropdown that lists all your addons.
- **Slash commands**: `/cpg` or `/custompartyglow`.

## Options

| Option | Description |
|---|---|
| Size | Base size of the glow and the dot (16–128). The dot is half this size. |
| Glow Scale | How far the glow spreads around the icon (1–5). |
| Opacity | Glow opacity (0.1–1). |
| Show player | Show the glow on yourself. |
| Show dot | Draw the class-colored dot on each group member (never on yourself, so your arrow stays visible). |
| Show minimap button | Show the minimap button. |
| Test mode | Shows four fake group members around you, to preview the glow without a group. Not saved. |

## Languages

The interface follows your game client's language: English, Spanish (esES / esMX) and Portuguese (ptBR). Other clients fall back to English. To add a language, add a `GetLocale()` block with the translated strings at the top of `CustomPartyGlow.lua`.

## Limitations

- Party and raid positions only show in the open world. The game does not give addons other players' map positions inside dungeons, raids, battlegrounds or arenas.

## Installation

1. Download the release zip and extract it into `World of Warcraft/_retail_/Interface/AddOns/` (or `_forever_/Interface/AddOns/` for WoW Forever).
2. Make sure the folder is named `CustomPartyGlow`.
3. Launch the game and enable the addon from the AddOns menu.

### From source

The release zip bundles the libraries. When running from a git checkout, add them yourself under `Libs/`:

- [LibStub](https://repos.wowace.com/wow/libstub/trunk) → `Libs/LibStub/LibStub.lua`
- [Krowi_WorldMapButtons](https://github.com/TheKrowi/Krowi_WorldMapButtons) → `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons.lua`

## Requirements

- World of Warcraft Retail 12.1 or higher, or WoW Forever.
