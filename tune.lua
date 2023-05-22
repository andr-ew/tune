local tune = {}

local tunings, scales, presets
local tuning_names, scale_names = {}, {}
local action = function() end

function tune.setup(args)
    tunings = args.tunings or {}
    scales = args.scale_groups or {}
    presets = args.presets or 8
    action = args.action or function() end

    for i,tuning in ipairs(tunings) do
        tuning_names[i] = tuning.name
    end

    for k,group in pairs(scales) do
        scale_names[k] = {}

        for i,scale in ipairs(group) do
            scale_names[k][i] = scale.name
        end
    end
end

local param_ids = {}

local function get_preset()
    return params:get('tuning_preset')
end

local function get_preset_param(id)
    return params:get(id..'_preset_'..get_preset())
end

local function get_tuning()
    return tunings[get_preset_param('tuning')]
end

local function hide_show_params()
    for pre = 1, presets do
        local show = params:get('tuning_preset') == pre

        for _,base in ipairs(param_ids) do
            local id = base..'_preset_'..pre
            if show then params:show(id) else params:hide(id) end
        end

        for i = 1,12 do
            local id = 'enable_'..i..'_preset_'..pre
            if show then params:show(id) else params:hide(id) end
        end

        if show then
            local group = get_tuning().scales
    
            for group_name, _ in pairs(scales) do
                local showgroup = group_name == group
                local id = 'scale_'..group_name..'_preset_'..pre
                if showgroup then params:show(id) else params:hide(id) end
            end
        end
    end
    _menu.rebuild_params() --questionable?
end

local function update_tuning()
    hide_show_params()
    action()
end

local function add_preset_param(args)
    table.insert(param_ids, args.id)

    for pre = 1, presets do
        local a = {}; for k,v in pairs(args) do a[k] = v end
        a.id = args.id..'_preset_'..pre
        a.action = update_tuning
        params:add(a)
    end
end

local tonic_names = { 'A','A#','B','C','C#','D','D#','E','F','F#','G','G#', }
local interval_names = {
    'octaves',
    "min 2nds", "maj 2nds",
    "min 3rds", "maj 3rds", "4ths",
    "tritones", "5ths", "min 6ths",
    "maj 6ths", "min 7ths", "maj 7ths",
}


local function get_tonic()
    return get_preset_param('tonic')
end

local function get_scale_idx()
    local group = get_tuning().scales
    local idx = get_preset_param('scale_'..group)

    return idx
end

local function get_scale_ivs()
    local group = get_tuning().scales
    local idx = get_preset_param('scale_'..group)
    
    return scales[group][idx].iv
end

local function get_interval_enabled(i)
    return params:get('enable_'..i..'_preset_'..get_preset()) > 0
end

local function get_intervals()
    local scl = get_scale_idx()
    local all = get_scale_ivs()

    local some = {}
    for i,v in ipairs(all) do
        if get_interval_enabled(i) then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end

    return some
end

local function get_row_tuning()
    return get_preset_param('row_tuning')
end

tune.get_intervals = intervals

function tune.params()
    params:add_separator('tuning')

    params:add{
        type = 'number', id = 'tuning_preset', name = 'preset',
        min = 1, max = presets, default = 1, action = update_tuning,
    }

    add_preset_param{
        type = 'option', id = 'tuning', name = 'tuning',
        options = tuning_names,
    }
    add_preset_param{
        type = 'option', id = 'tonic', name = 'tonic',
        options = tonic_names,
    }
    for group_name, _ in pairs(scales) do
        add_preset_param{
            type = 'option', id = 'scale_'..group_name, name = 'scale',
            options = scale_names[group_name],
        }
    end
    add_preset_param{
        type = 'number', id = 'row_tuning', name = 'row tuning',
        min = 1, max = 12, default = 1,
        formatter = function(p) 
            local iv = get_intervals()

            local rowint = p:get()

            local deg = (rowint - 1)%#iv + 1
            local interval = math.floor(iv[deg])

            return interval_names[interval + 1]
        end
    }

    params:add_group('toggle intervals', 12 * presets)
    for pre = 1,presets do
        for i = 1,12 do
            params:add{
                type = 'binary', behavior = 'toggle', 
                id = 'enable_'..i..'_preset_'..pre, name = 'enable interval '..i,
                default = 1, action = update_tuning,
            }
        end
    end

    hide_show_params()
end

tune.wrap = function(deg, oct)
    local iv = get_intervals()

    oct = oct + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1

    return deg, oct
end

--TODO: start row wrapping in the middle of the grid vertically somehow
tune.degoct = function(row, column, trans, toct)
    local iv = get_intervals()
    local rowint = get_row_tuning() - 1
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0)
    deg, oct = tune.wrap(deg, oct)
    
    return deg, oct
end

-- tune.is_tonic = function(row, column, trans)
--     return tune.degoct(row, column, trans) == 1
-- end

--number to be multiplied by center freq in hz
tune.hz = function(row, column, trans, toct)
    local iv = get_intervals()
    local toct = toct or 0
    local deg, oct = tune.degoct(row, column, trans, toct - 5)
    local tuning = get_tuning()

    return (
        2^(get_tonic()/(tuning.tones or 12)) * 2^oct 
        * (
            (tuning.temperment == 'just') 
            and (tuning.ratios[iv[deg] + 1])
            or (2^(iv[deg]/tuning.tones))
        )
    )
end

local JIVOLT = 1 / math.log(2)
local function justvolts(f) return math.log(f) * JIVOLT end

tune.volts = function(row, column, trans, toct) 
    local iv = get_intervals()
    local toct = toct or 0
    local deg, oct = tune.degoct(row, column, trans, toct)
    local tuning = get_tuning()

    if tuning.temperment == 'just' then
        return (
            justvolts(tuning.ratios[math.abs(get_tonic()) + 1]) 
            + oct 
            + justvolts(tuning.ratios[iv[deg] + 1])
            - 1
        )
    else
        return (
            (get_tonic()/(tuning.tones)) 
            + oct 
            + (iv[deg]/tuning.tones)
        )
    end
end

--TODO
tune.midi = function() end

return tune
