-- XaEnvironment support
local add_inv = flinv._add_inv

function flinv.register_tab(name, def)
    -- Localise variables so the def table can get garbage collected
    local title = def.title or name

    local show_inv = def.show_inventory ~= false
    local show = def.show
    local form, tab_id = flinv._wrap_form(def, 10.4875, 9.51, false,
        show_inv and add_inv or nil)

    player_style.register_button({
        type = def.icon and "image" or nil,
        name = tab_id,
        label = not def.icon and title or nil,
        image = def.icon,
        info = title,
        action = function(player)
            if not show or show(player) then
                form:show(player)
            else
                minetest.chat_send_player(player:get_player_name(),
                    "Permission denied")
            end
        end
    })
end
