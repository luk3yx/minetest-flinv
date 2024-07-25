--
-- Flinv: Flow inventory compatibility layer
--
-- Copyright © 2024 by luk3yx
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

flinv = {}

local gui = flow.widgets
local next_id = 0
function flinv._wrap_form(def, min_w, min_h, use_prefix, modify_tree)
    -- The tab ID must be safe to use in names
    local tab_id = "flinv_" .. next_id
    next_id = next_id + 1

    local form = def.form
    local show = def.show

    return flow.make_gui(function(player, ctx)
        -- Use embed API if available, or fall back to undocumented function
        local tree
        if not show or not use_prefix or show(player) then
            tree = form.embed and form:embed{
                player = player,
                name = use_prefix and tab_id or nil,
            } or form._build(player, ctx)
        else
            tree = gui.Label{
                label = "Permission denied!",
                style = {font_size = "*2"},
            }
        end

        if modify_tree then
            tree = modify_tree(tree, player)
        end

        -- Set default padding
        tree.padding = tree.padding or (use_prefix and ctx.padding or 0.3)

        return gui.Stack{
            padding = 0,
            -- These might be specified in ctx
            min_w = min_w or ctx.min_w,
            min_h = min_h or ctx.min_h,
            tree
        }
    end), tab_id
end

function flinv._add_inv(tree, player)
    local size = player:get_inventory():get_size("main")
    local w = size > 32 and 9 or 8
    tree.expand = true
    return gui.VBox{
        tree,
        gui.List{
            inventory_location = "current_player", list_name = "main",
            w = w, h = math.ceil(size / w),
        }
    }
end

-- Used by inventory mods that have images as part of their background
local btn_style_reset = {bgimg = "", bgimg_hovered = "", bgimg_pressed = ""}
function flinv._list_bg_helper(bgimg, img_scale, img_middle, button_style_workaround)
    local img_offset = (1 - img_scale) / 2
    local function insert_list_background(tree, player, seen_listcolors)
        for i, node in ipairs(tree) do
            if node.type == "list" and not node.style and
                    not seen_listcolors then
                -- HACK: Due to the partially rendered state the form may be in
                -- we have to use a container and do things manually
                local container = {
                    type = "container", x = node.x, y = node.y,
                    w = node.w * 1.25 - 0.25, h = node.h * 1.25 - 0.25,
                    align_h = node.align_h ~= "fill" and node.align_h or "center",
                    align_v = node.align_v ~= "fill" and node.align_v or "center",
                }
                for x = 0, node.w - 1 do
                    for y = 0, node.h - 1 do
                        container[#container + 1] = {
                            type = "image",
                            x = x * 1.25 + img_offset, y = y * 1.25 + img_offset,
                            w = img_scale, h = img_scale, texture_name = bgimg,
                            middle_x = img_middle,
                        }
                    end
                end
                node.x, node.y = 0, 0
                container[#container + 1] = node
                tree[i] = container
            elseif node.type == "listcolors" then
                -- The mod is doing its own thing for inventory lists
                seen_listcolors = true
            elseif button_style_workaround and (node.type == "image_button" or
                    node.type == "image_button_exit") and
                    -- node.drawborder defaults to true, use == false
                    node.drawborder == false and not node.style then
                -- Add custom style
                node.style = btn_style_reset

                -- Add a name so that the style doesn't break i3's buttons
                if not node.name and not node.on_event then
                    node.name = "_flinv_ignore"
                end
            else
                insert_list_background(node, player, seen_listcolors)
            end
        end
        return tree
    end

    return insert_list_background
end

-- Load mod-specific code if inventory mods are detected
for _, mod in ipairs({"sway", "i3", "unified_inventory", "smart_inventory",
        "inventory_plus", "sfinv", "rp_formspec", "mcl_inventory",
        "player_style", "nc_player_gui"}) do
    if minetest.get_modpath(mod) or (mod == "mcl_inventory" and
            minetest.get_modpath("vlf_inventory")) then
        dofile(minetest.get_modpath("flinv") .. "/" .. mod .. ".lua")
        break
    end
end

-- Fallback
if not flinv.register_tab then
    dofile(minetest.get_modpath("flinv") .. "/fallback.lua")
end

flinv._get_add_inv = nil
flinv._list_bg_helper = nil
