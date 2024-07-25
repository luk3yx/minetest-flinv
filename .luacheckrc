max_line_length = 100 -- TODO: Maybe decrease this to 80

globals = {
    "flinv",
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "indexof"}},
    "formspec_ast",
    "minetest",
    "hud_fs",
    "flow",
    "dump",

    "i3",
    "inventory_plus",
    "mcl_inventory",
    "nodecore",
    "player_style",
    "rp_formspec",
    "sfinv",
    "smart_inventory",
    "sway",
    "unified_inventory",
    "vlf_inventory",
}

-- This error is thrown for methods that don"t use the implicit "self"
-- parameter.
ignore = {"212/self", "432/player", "43/ctx", "212/player", "212/ctx", "212/value"}
