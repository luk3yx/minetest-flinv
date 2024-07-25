-- Fallback
local add_inv = flinv._add_inv
local gui = flow.widgets

local btns = {}

function flinv.register_tab(name, def)
    local show_inv = def.show_inventory ~= false
    local form = flinv._wrap_form(def, 10.4875, 9.51, false,
            function(tree, player)
        if show_inv then
            tree = add_inv(tree, player)
        end

        -- Used in mcl_inventory.lua
        if flinv._fallback_modify_tree then
            tree = flinv._fallback_modify_tree(tree, player)
        end
        return tree
    end)
    btns[#btns + 1] = {def.title or name, def.icon, def.show, form}
end

local btn_form = flow.make_gui(function(player, ctx)
    local vbox = {name = "flinv", min_w = 10}
    for _, btn in ipairs(btns) do
        if not btn[3] or btn[3](player) then
            vbox[#vbox + 1] = gui.Stack{
                min_h = 1.4,
                gui.Button{
                    label = btn[1],
                    on_event = function() btn[4]:show(player) end,
                },
                btn[2] and gui.Image{
                    w = 1, h = 1, padding = 0.2, align_h = "left",
                    texture_name = btn[2]
                } or gui.Nil{},
            }
        end
    end

    return gui.VBox{
        gui.Label{label = "Select a button"},
        gui.ScrollableVBox(vbox),
    }
end)

minetest.register_chatcommand("flinv", {
    description = "Shows a list of buttons",
    func = function(name)
        btn_form:show(minetest.get_player_by_name(name))
    end,
})
