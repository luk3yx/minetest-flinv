-- Unified inventory support

-- Store contexts ourselves, unified_inventory has no API for it
local contexts = {}

minetest.register_on_leaveplayer(function(player)
    contexts[player:get_player_name()] = nil
end)

local modify_tree = flinv._list_bg_helper("ui_single_slot.png", unified_inventory.imgscale, 16)
function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false

    local form, tab_id = flinv._wrap_form(def, nil, nil, true, modify_tree)

    -- Use tab_id as the name since unified_inventory uses this as a button name
    unified_inventory.register_page(tab_id, {
        get_formspec = function(player, perplayer_formspec)
            local pname = player:get_player_name()
            -- Initialise context
            contexts[pname] = contexts[pname] or {}
            contexts[pname][tab_id] = contexts[pname][tab_id] or {}

            -- We have wrapped the form with an embed prefix (provided
            -- form:embed is available), it should be safe to store things in
            -- ctx
            local ctx = contexts[pname][tab_id]

            -- Figure out what size the form should be
            if show_inv then
                ctx.min_w = perplayer_formspec.page_x
                ctx.min_h = perplayer_formspec.std_inv_y
            elseif perplayer_formspec.is_lite_mode then
                ctx.min_w = perplayer_formspec.page_x
                ctx.min_h = perplayer_formspec.formh
            else
                ctx.min_w = perplayer_formspec.formw
                ctx.min_h = perplayer_formspec.main_button_y
            end
            ctx.padding = perplayer_formspec.form_header_x

            if perplayer_formspec.is_lite_mode then
                ctx.min_w = ctx.min_w - 0.2
            end

            local fs, events, i = form:render_to_formspec_string(player, ctx)
            ctx.process_events = events

            -- We want to make sure that the latest formspec version is used
            fs = "formspec_version[" .. i.formspec_version .. "]" .. fs

            -- Add the inventory tiles background
            if show_inv then
                fs = fs .. perplayer_formspec.standard_inv_bg
            end

            return {
                formspec = fs,
                draw_inventory = show_inv,
                draw_item_list = show_inv or perplayer_formspec.is_lite_mode,
            }
        end,
    })

    unified_inventory.register_button(tab_id, {
        type = "image",
        image = def.icon or "no_texture.png",
        tooltip = def.title or name,
        condition = def.show,
    })
end

-- There's no API in unified_inventory to process fields, do it manually
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" then return end

    local pname = player:get_player_name()
    local page = unified_inventory.current_page[pname]
    local ctx = contexts[pname] and contexts[pname][page]
    if ctx and ctx.process_events(fields) then
        unified_inventory.set_inventory_formspec(player, page)
    end
end)
