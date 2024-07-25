-- Inventory plus support
-- This just uses form:show() so there aren't any back buttons, but I don't
-- think inventory_plus is widely used.
local add_inv = flinv._add_inv

local forms = {}
function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local title = def.title or name

    local show_inv = def.show_inventory ~= false
    local show = def.show
    local form, tab_id = flinv._wrap_form(def, 10.4875, 9.51, false,
        show_inv and add_inv or nil)

    forms[tab_id] = form
    minetest.register_on_joinplayer(function(player)
        if not show or show(player) then
            inventory_plus.register_button(player, tab_id, title)
        end
    end)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "" then
        for field in pairs(fields) do
            if forms[field] then
                forms[field]:show(player)
                break
            end
        end
    end
end)
