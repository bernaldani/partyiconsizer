# Custom Party Glow

**Custom Party Glow** is a World of Warcraft addon that adds a pulsing, class-colored glow to you and your party / raid members on the world map, so they are easy to spot at a glance.

## Features

- Class-colored glow for every party or raid member on the world map (uses the game's class colors).
- Optional glow on yourself.
- Adjustable glow size, spread and opacity.
- All settings are saved per account and kept between sessions.

## Opening the options

Any of these opens (or closes) the options panel:

- **World map button**: top-right corner of the map, stacked with Blizzard's filter buttons.
- **Minimap button**: drag it around the minimap edge to move it. It can be hidden from the options.
- **Addon compartment**: the minimap dropdown that lists all your addons.
- **Slash commands**: `/cpg` or `/custompartyglow`.

## Options

| Option | Description |
|---|---|
| Size | Glow icon size (16–128). |
| Glow Scale | How far the glow spreads around the icon (1–5). |
| Opacity | Glow opacity (0.1–1). |
| Show player | Show the glow on yourself. |
| Show minimap button | Show the minimap button. |

## Languages

The interface follows your game client's language: English, Spanish (esES / esMX) and Portuguese (ptBR). Other clients fall back to English. To add a language, add a `GetLocale()` block with the translated strings at the top of `CustomPartyGlow.lua`.

## Limitations

- Party and raid positions only show in the open world. The game does not give addons other players' map positions inside dungeons, raids, battlegrounds or arenas.

## Installation

1. Download the release zip and extract it into `World of Warcraft/_retail_/Interface/AddOns/`.
2. Make sure the folder is named `CustomPartyGlow`.
3. Launch the game and enable the addon from the AddOns menu.

### From source

The release zip bundles the libraries. When running from a git checkout, add them yourself under `Libs/`:

- [LibStub](https://repos.wowace.com/wow/libstub/trunk) → `Libs/LibStub/LibStub.lua`
- [Krowi_WorldMapButtons](https://github.com/TheKrowi/Krowi_WorldMapButtons) → `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons.lua`

## Requirements

- World of Warcraft Retail 12.1 or higher.
