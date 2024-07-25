-- MineClone (& forks) support

-- Support VoxelForge (same API, just renamed mod)
local is_mcl = minetest.global_exists("mcl_inventory")
local mcl_inventory = is_mcl and mcl_inventory or vlf_inventory
local prefix = is_mcl and "mcl" or "vlf"

if not mcl_inventory.register_survival_inventory_tab then return end

-- Load the fallback anyway, it is needed for creative mode
dofile(minetest.get_modpath("flinv") .. "/fallback.lua")

local contexts = {}

minetest.register_on_leaveplayer(function(player)
    contexts[player:get_player_name()] = nil
end)

local modify_tree = flinv._list_bg_helper(prefix .. "_formspec_itemslot.png",
    1.1, nil, true)
flinv._fallback_modify_tree = modify_tree
local register_fallback_tab = flinv.register_tab
function flinv.register_tab(name, def)
    local show_inv = def.show_inventory ~= false
    local form, tab_id = flinv._wrap_form(def, 11.75,
        show_inv and 5.575 or 10.9, true, modify_tree)

    -- The API only accepts items as icons
    minetest.register_craftitem(":flinv:" .. tab_id, {
        inventory_image = def.icon or "no_texture.png",
        groups = {not_in_creative_inventory = 1},
    })

    mcl_inventory.register_survival_inventory_tab({
        id = tab_id,
        description = def.title or name,
        item_icon = "flinv:" .. tab_id,
        show_inventory = show_inv,
        build = function(player)
            local pname = player:get_player_name()
            -- Initialise context
            contexts[pname] = contexts[pname] or {}
            contexts[pname][tab_id] = contexts[pname][tab_id] or {}

            -- We have wrapped the form with an embed prefix (provided
            -- form:embed is available), it should be safe to store things in
            -- ctx
            local ctx = contexts[pname][tab_id]
            ctx.padding = 0.375
            local fs, events, i = form:render_to_formspec_string(player, ctx)
            ctx.process_events = events

            -- Make sure the formspec version in use is the latest one
            return "formspec_version[" .. i.formspec_version .. "]" .. fs
        end,
        handle = function(player, fields)
            local pname = player:get_player_name()
            local ctx = contexts[pname] and contexts[pname][tab_id]
            if ctx and ctx.process_events(fields) then
                mcl_inventory.update_inventory(player)
            end
        end,
        access = def.show,
    })

    -- Register the tab with the fallback API for creative mode
    register_fallback_tab(name, def)
end
