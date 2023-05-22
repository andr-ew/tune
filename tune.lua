-- states = {
--     {
--         mode, --(tuning item)
--         tonic,
--         { --for each tuning item
--             scale,
--             tuning = { --row tuning, for each scale
--                 1,
--             },
--             toggles = { --note toggle, for each scale
--                 { 1, 1, 1... },
--             }
--         }
--     }
-- }

local tune = {}

local tunings, scales, presets
local tuning_names, scale_names = {}, {}

function tune.setup(args)
    tunings = args.tunings or {}
    scales = args.scale_groups or {}
    presets = args.presets or 8

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

local function get_tuning()
    return tunings[params:get('tuning_preset_'..params:get('tuning_preset'))]
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

-- local tonics = {}
-- for i = 1, 12 do
--     local n = i - 9 - 1 -- start from C below middle A
--     tonics[i] = n
-- end


local function tonic(pre)
    return tonics[states[pre].tonic]
end

local function tuning(pre)
    local scl = state(pre).scale
    return state(pre).tuning[scl]
end

local function intervals(pre)
    local scl = state(pre).scale
    local all = mode(pre).scales[scl].iv

    local some = {}
    for i,v in ipairs(all) do
        if state(pre).toggles[scl][i] > 0 then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end
    return some
end

tune.get_intervals = intervals

tune.wrap = function(deg, oct, pre)
    local iv = intervals(pre)

    oct = oct + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1

    return deg, oct
end

--TODO: start row wrapping in the middle of the grid vertically somehow
tune.degoct = function(row, column, pre, trans, toct)
    local iv = intervals(pre)
    local rowint = tuning(pre) - 1
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0)
    deg, oct = tune.wrap(deg, oct, pre)
    
    return deg, oct
end

tune.is_tonic = function(row, column, pre, trans)
    return tune.degoct(row, column, pre, trans) == 1
end

--number to be multiplied by center freq in hz
tune.hz = function(row, column, trans, toct, pre)
    local iv = intervals(pre)
    local toct = toct or 0
    local deg, oct = tune.degoct(row, column, pre, trans, toct - 5)

    return (
        2^(tonic(pre)/(mode(pre).tones or 12)) * 2^oct 
        * (
            (mode(pre).temperment == 'just') 
            and (mode(pre).ratios[iv[deg] + 1])
            or (2^(iv[deg]/mode(pre).tones))
        )
    )
end

local JIVOLT = 1 / math.log(2)
local function justvolts(f) return math.log(f) * JIVOLT end

tune.volts = function(row, column, trans, toct, pre) 
    local iv = intervals(pre)
    local toct = toct or 0
    local deg, oct = tune.degoct(row, column, pre, trans, toct)

    if mode(pre).temperment == 'just' then
        return (
            justvolts(mode(pre).ratios[math.abs(tonic(pre)) + 1]) 
            + oct 
            + justvolts(mode(pre).ratios[iv[deg] + 1])
            - 1
        )
    else
        return (
            (tonic(pre)/(mode(pre).tones)) 
            + oct 
            + (iv[deg]/mode(pre).tones)
        )
    end
end

--TODO
tune.midi = function() end

return tune
