-- Sfinv support
function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false
    local ctx_key = "flinv:ctx_" .. name
    local events_key = "flinv:events_" .. name

    -- No need to add prefixes, I think sfinv keeps field names clear
    local form = flinv._wrap_form(def, 10.4875, show_inv and 6.2 or 11.36)
    local show = def.show

    -- This uses the name instead of tab_id as sfinv expects a namespaced
    -- identifier (modname:name) instead of something that can be used as a
    -- button name
    sfinv.register_page(name, {
        title = def.title or name,
        get = function(_, player, context)
            context[ctx_key] = context[ctx_key] or {}
            local fs, process_events, i = form:render_to_formspec_string(
                player, context[ctx_key]
            )
            context[events_key] = process_events
            fs = "formspec_version[" .. i.formspec_version .. "]" ..
                "real_coordinates[true]" .. fs
            return sfinv.make_formspec(player, context, fs, show_inv, "size[8,9.1]")
        end,
        on_player_receive_fields = function(_, player, context, fields)
            if not context[events_key] or context[events_key](fields) then
                sfinv.set_player_inventory_formspec(player, context)
            end
        end,
        is_in_nav = show and function(_, player) return show(player) end,
    })
end
