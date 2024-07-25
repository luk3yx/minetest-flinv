# flinv

Inventory API compatibility layer (this is not a standalone inventory mod). Uses
[flow](https://content.minetest.net/packages/luk3yx/flow/) to render forms and
expands them to fit into the space provided by whatever inventory mod is in use.

## Supported inventory mods/games (alphabetical order)

 - [i3](https://content.minetest.net/packages/mt-mods/i3/)[^1]
 - [Inventory Plus](https://content.minetest.net/packages/TenPlus1/inventory_plus/)[^2]
 - [NodeCore](https://content.minetest.net/packages/Warr1024/nodecore/)[^2]
 - [Repixture](https://content.minetest.net/packages/Wuzzy/repixture/)
 - [sfinv](https://content.minetest.net/packages/rubenwardy/sfinv/)
 - [Smart Inventory](https://content.minetest.net/packages/bell07/smart_inventory/)[^2]
 - [Sway](https://content.minetest.net/packages/lazerbeak12345/sway/)
 - [Unified Inventory](https://content.minetest.net/packages/RealBadAngel/unified_inventory/)[^3]
 - [VoxeLibre](https://content.minetest.net/packages/Wuzzy/mineclone2/)[^4][^5] (and [Mineclonia](https://content.minetest.net/packages/ryvnf/mineclonia/) and VoxelForge[^5])
 - [XaEnvironment](https://content.minetest.net/packages/AiTechEye/xaenvironment/)

If no supported inventory mod is installed, a button list can be accessed with
`/flinv`.

[^1]: May have issues with scrollbars on older versions of flow (see the TODO
comment in `i3.lua`).
[^2]: Usable but not perfect.
[^3]: "Lite mode" is supported, but some forms might be too big to fit.
[^4]: Survival mode only, in creative mode you have to use `/flinv`.
[^5]: Not tested (but presumed to work due to testing on Mineclonia), may not work.

## License note

While flinv itself is licensed under the LGPL, some of the underlying
mods/games (such as Smart Inventory) may be licensed under the GPL, if you plan
to distribute proprietary mods that use flinv note that you may not be able to
distribute them with all games.

## Registering tabs

Note that your form should be reasonably small so that it fits in all inventory
mods. You can stretch things with `expand = true` or `gui.Spacer{}`. Currently,
Sway is the only inventory mod which will expand its own form to fit content
that's too large to fit.

Some inventory mods place a limit on the amount of tabs that can be
registered, such as i3, which only allows 6 tabs (including the built-in
"inventory" tab). If this limit is reached, calling flinv.register_tab will
error.

```lua
local gui = flow.widgets

flinv.register_tab("flinv:test", {
    title = "My tab",
    icon = "air.png",
    form = flow.make_gui(function(player, ctx)
        ctx.i = ctx.i or 0
        return gui.VBox{
            gui.Label{label = "Hello world! " .. ctx.i},
            gui.List{
                inventory_location = "current_player",
                list_name = "craft",
                w = 2, h = 2,
            },
            gui.Spacer{},
            gui.Button{
                label = "This is a button",
                on_event = function(player, ctx)
                    ctx.i = ctx.i + 1
                    return true
                end,
            },
        }
    end),

    -- Defaults to true, shows the player's inventory. Disable if you don't
    -- need it to get more space.
    show_inventory = true,

    -- Optional: Restrict the visibility of the tab. In inventory mods that
    -- don't support this, a "permission denied" message will be shown.
    -- show = function(player)
    --     return minetest.check_player_privs(player, "server")
    -- end,
})
```

Both `title` and `icon` should be specified for maximum compatibility.

The tab will automatically be expanded to fit in whatever inventory mod is
being used.
