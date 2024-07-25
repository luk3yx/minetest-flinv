-- Store contexts ourselves, unified_inventory has no API for it
local contexts = {}

minetest.register_on_leaveplayer(function(player)
    contexts[player:get_player_name()] = nil
end)

-- Remove backgrounds on image_buttons that shouldn't have them
local modify_tree = flinv._list_bg_helper("ui_itemslot.png", 1, nil, true)

local pos = rp_formspec.default.start_point
local default_padding = math.min(pos.x, pos.y)
local fs_x, fs_y = pos.x - default_padding, pos.y - default_padding
local fs_w, fs_h = rp_formspec.default.size.x, rp_formspec.default.size.y
local min_w = fs_w - fs_x * 2

-- These subtract pos.y again to add a bit of spacing due to the thicker border
-- below the background texture
local min_h = fs_h - fs_y * 2 - pos.y
local inv_min_h = fs_h / 2 - fs_y - pos.y

function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false

    -- No need to add prefixes, I think sfinv keeps field names clear
    local form = flinv._wrap_form(def, min_w, show_inv and inv_min_h or min_h,
        true, modify_tree)

    if show_inv then
        rp_formspec.register_page(name, rp_formspec.get_page("rp_formspec:2part") ..
            rp_formspec.default.player_inventory)
    else
        rp_formspec.register_page(name, rp_formspec.get_page("rp_formspec:default"))
    end

    rp_formspec.register_invpage(name, {
        get_formspec = function(pname)
            -- Initialise context
            contexts[pname] = contexts[pname] or {}
            contexts[pname][name] = contexts[pname][name] or {
                padding = default_padding
            }

            local player = minetest.get_player_by_name(pname)
            local ctx = contexts[pname][name]
            local fs, events = form:render_to_formspec_string(player, ctx)
            ctx.process_events = events

            -- Get the generic style_type[]s
            local prepend = player:get_formspec_prepend()
            local tree = formspec_ast.parse(prepend) or {}
            local style_nodes = {}
            local undo_styles = {}
            for _, node in ipairs(tree) do
                if node.type == "style_type" then
                    -- Remove properties defined in the shared prepend
                    node.props.content_offset = nil
                    node.props.sound = nil
                    if next(node.props) then
                        style_nodes[#style_nodes + 1] = node

                        -- Revert the style afterwards
                        local undo_node = {
                            type = node.type,
                            selectors = node.selectors,
                            props = {}
                        }
                        for prop in pairs(node.props) do
                            if prop ~= "border" then
                                undo_node.props[prop] = ""
                            end
                        end
                        if next(undo_node.props) then
                            undo_styles[#undo_styles + 1] = undo_node
                        end
                    end
                end
            end

            return rp_formspec.get_page(name) ..
                "container[" .. fs_x .. "," .. fs_y .. "]" ..
                "style_type[list;spacing=]" ..
                formspec_ast.unparse(style_nodes) ..
                fs ..
                formspec_ast.unparse(undo_styles) ..
                "container_end[]"
        end,
    })

    local icon = def.icon or "no_texture.png"
    rp_formspec.register_invtab(name, {
        icon = icon,
        icon_active = icon,
        tooltip = def.title,
    })
end


-- There's no API in rp_formspec to process fields, do it manually
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" then return end

    local pname = player:get_player_name()
    local page = rp_formspec.get_current_invpage(player)
    local ctx = contexts[pname] and contexts[pname][page]
    if ctx and ctx.process_events(fields) then
        rp_formspec.refresh_invpage(player, page)
    end
end)
