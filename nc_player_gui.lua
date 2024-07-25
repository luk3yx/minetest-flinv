-- NodeCore inventory support
local add_inv = flinv._add_inv

-- Store contexts ourselves
local contexts = {}

minetest.register_on_leaveplayer(function(player)
    contexts[player:get_player_name()] = nil
end)

function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false
    -- local show = def.show

    local form, tab_id = flinv._wrap_form(def, nil, nil, true, show_inv and add_inv or nil)

    nodecore.register_inventory_tab({
        title = def.title or name,
        -- Breaks tab buttons
        -- visible = show and function(_, player) return show(player) end,
        content = function(player, geom)
            -- Initialise context
            local pname = player:get_player_name()
            contexts[pname] = contexts[pname] or {}
            contexts[pname][tab_id] = contexts[pname][tab_id] or {}

            local ctx = contexts[pname][tab_id]
            contexts[pname].active = ctx
            ctx.padding = geom.x * 1.25
            ctx.min_w = geom.w * 1.25
            ctx.min_h = geom.h * 1.15 - 0.1

            local fs, events, i = form:render_to_formspec_string(player, ctx)
            ctx.process_events = events

            return {
                "real_coordinates[true]",
                "container[0,", tostring((geom.y - geom.x) * 1.15 + 0.3), "]",
                "formspec_version[", tostring(i.formspec_version), "]",
                "listcolors[#808080;#c0c0c0;#000000c8]",
                fs,
                "container_end[]",
                "real_coordinates[false]",
            }
        end,
        raw = true,
    })
end

-- There's no API to process fields, do it manually
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" then return end

    local pname = player:get_player_name()
    local ctx = contexts[pname] and contexts[pname].active
    if ctx and ctx.process_events(fields) then
        nodecore.inventory_formspec_update(player)
    end
end)
