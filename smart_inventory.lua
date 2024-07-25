-- Smart inventory support
local add_inv = flinv._add_inv

local function rebuild(self)
    local fs, process_events, i = self.data.form:render_to_formspec_string(
        minetest.get_player_by_name(self.data.pname), self.data.ctx
    )
    self.data.code =
        "formspec_version[" .. i.formspec_version .. "]" ..
        "real_coordinates[true]" ..
        "container[0.2,0.3]" ..
        fs ..
        "container_end[]" ..
        "real_coordinates[false]"
    self.data.process_events = process_events
end

local function on_input(state, fields, player)
    local code = state:get("code")
    if code.data.process_events and code.data.process_events(fields) then
        rebuild(code)
    end
end

function flinv.register_tab(_, def)
    -- Localise variables so the def table can get garbage collected
    local show_inv = def.show_inventory ~= false

    -- No need to add prefixes, I think sfinv keeps field names clear
    local form, tab_id = flinv._wrap_form(def, 25, 12, true,
        show_inv and add_inv or nil)
    local show = def.show

    smart_inventory.register_page({
        name = tab_id,
        icon = def.icon,
        label = not def.icon and def.title or nil,
        tooltip = def.title,
        smartfs_callback = function(state)
            local code = state:element("code", {
                name = "code",
                code = "",
                ctx = {},
                pname = state.location.rootState.location.player,
                form = form,
            })

            -- We only want to actually build the formspec when flow thinks
            -- there needs to be an update, so that things like scrollbars
            -- aren't completely broken.
            rebuild(code)
            state:onInput(on_input)
        end,
        is_visible_func = show and function(state)
            return show(minetest.get_player_by_name(state.location.player))
        end,
    })
end
