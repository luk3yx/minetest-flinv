-- Sway inventory support
local gui = flow.widgets

local i = 0
function flinv.register_tab(name, def)
    local show_inv = def.show_inventory ~= false
    -- No need to wrap the form
    local form = def.form
    local show = def.show
    i = i + 1
    local prefix_name = "flinv_" .. i
    sway.register_page(name, {
        title = def.title or name,
        get = function(_, player, ctx)
            return sway.Form{
                show_inv = show_inv,
                -- flinv forms expect to be expanded a bit, use a stack so
                -- that align_{h,v} will still work
                gui.Stack{
                    min_w = 9.75, min_h = show_inv and 3.5 or 8.4,
                    form.embed and form:embed{
                        player = player,
                        name = prefix_name,
                    } or form._build(player, ctx),
                },
            }
        end,
        is_in_nav = show and function(_, player) return show(player) end,
    })
end
