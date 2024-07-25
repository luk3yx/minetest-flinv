-- I3 support
local btn_style = {
    bgimg = "i3_btn9.png",
    bgimg_hovered = "i3_btn9_hovered.png",
    bgimg_pressed = "i3_btn9_pressed.png",
    bgimg_middle = "4,6",
    sound = "i3_click",
}

-- Add button styles to all buttons that don't have their own style set or
-- drawborder disabled
local buttons = {button = true, image_button = true, item_image_button = true,
    button_exit = true, image_button_exit = true}
local function inject_button_styles(tree)
    for _, node in ipairs(tree) do
        if buttons[node.type] and node.drawborder ~= false and
                not node.style then
            -- Add custom style
            node.style = btn_style

            -- Add a name so that the style doesn't break i3's buttons
            if not node.name and not node.on_event then
                node.name = "_flinv_ignore"
            end
        end
        inject_button_styles(node)
    end
    return tree
end

function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false
    local ctx_key = "flinv:ctx_" .. name
    local events_key = "flinv:events_" .. name

    local form, tab_id = flinv._wrap_form(def, nil, nil,
        true, inject_button_styles)
    local show = def.show

    -- The i3 tab name is used as a button, use the tab ID instead
    i3.new_tab(tab_id, {
        description = def.title or name,
        -- image = def.icon, -- Overlaps with label
        slots = show_inv,

        access = function(player)
            return not show or show(player)
        end,

        formspec = function(player, data, fs)
            data[ctx_key] = data[ctx_key] or {}
            local ctx = data[ctx_key]
            ctx.min_w = data.inv_width + 0.1
            ctx.min_h = show_inv and (data.legacy_inventory and 6.7 or 6.9) or 12
            ctx.padding = data.legacy_inventory and 0.23 or 0.22
            -- TODO: Store this and only call render_to_formspec_string again
            -- if process_events returns true
            local formspec, process_events = form:render_to_formspec_string(
                player, ctx
            )
            data[events_key] = process_events

            fs("style_type[field,textarea;border=true]")
            fs("style_type[list;spacing=]")
            fs(formspec)
            fs("style_type[list;spacing=0.1]")
            fs("style_type[field,textarea;border=false]")

            if i3.tabs[1].slots == nil then
                -- Old i3 mod, add inventory slots manually
                -- Positions from the fl_workshop mod
                fs("label[0.25,7.1;Inventory]")
                fs("list[current_player;main;0.25,7.5;9,4]")
            end
        end,

        fields = function(player, data, fields)
            if data[events_key] and not data[events_key](fields) then
                -- Make sure the formspec is redrawn if i3's own buttons are
                -- pressed
                for field in pairs(fields) do
                    -- form:embed{} prefixes use a control character
                    if field:find("^[A-Za-z0-9]") then
                        if data.window_timer == nil then
                            -- This is an old i3 version, call set_fs manually
                            -- to refresh the page.
                            i3.set_fs(player)
                        end
                        return
                    end
                end

                -- Otherwise prevent formspec updates when not needed
                return false
            elseif data.window_timer == nil then
                -- This is an old i3 version, call set_fs manually to refresh
                -- the page.
                i3.set_fs(player)
            end
        end,
    })
end
