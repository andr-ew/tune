local tune = {}
tune.__index = tune 

-- local tunings, scales, presets
-- local tuning_names, scale_names = {}, {}
-- local action = function() end

function tune.add_global_params(action)
    params:add{
        type = 'number', id = 'base_tonic', name = 'base key',
        default = 3, min = 0, max = 11,
        formatter = function(p) 
            return tune.tonic_names[p:get()]
        end,
        action = action,
    }
end

local class_names = { 'heptatonic', 'pentatonic' }

function tune.new(args)
    local self = {}
    setmetatable(self, tune)

    self.id = args.id or ''
    self.add_param_separator = not (args.add_param_separator == false)
    self.add_param_group = not (args.add_param_group == false)
    self.tunings = args.tunings or {}
    self.scales = args.scale_groups or {}
    self.action = args.action or function() end
    self.visibility_condition = args.visibility_condition or function() return true end

    self.tuning_names = {}
    -- self.scale_names = {}

    for i,tuning in ipairs(self.tunings) do
        self.tuning_names[i] = tuning.name
    end

    -- for k,group in pairs(self.scales) do
    --     self.scale_names[k] = {}

    --     for class_name,class in pairs(group) do
    --         for i,scale in ipairs(class) do
    --             self.scale_names[k][class_name][i] = scale.name
    --         end
    --     end
    -- end

    self.param_ids = {}

    return self
end

function tune:get_param(id)
    return params:get('tuning_'..self.id..'_'..id)
end

function tune:get_param_id(id)
    return 'tuning_'..self.id..'_'..id
end

function tune:get_tuning()
    return self.tunings[self:get_param('tuning')]
end

function tune:get_scale_idx()
    local idx = self:get_param('scale')

    return idx
end

function tune:get_scale_ivs()
    local group = self:get_tuning().scales
    local class = class_names[self:get_param('scale_class')]
    local idx = self:get_param('scale')

    return self.scales[group][class][idx].iv
end

function tune:update_tuning()
    self.action()
end

function tune:add_param(args)
    table.insert(self.param_ids, args.id)

    local a = {}; for k,v in pairs(args) do a[k] = v end
    a.id = self:get_param_id(args.id)
    a.action = function() self:update_tuning() end
    params:add(a)
end

local tonic_names = {
    [-12] = 'A',
    [-11] = 'A#',
    [-10] = 'B',
    [-9] = 'C',
    [-8] = 'C#',
    [-7] = 'D',
    [-6] = 'D#',
    [-5] = 'E',
    [-4] = 'F',
    [-3] = 'F#',
    [-2] = 'G',
    [-1] = 'G#', 
    [0] = 'A',
    [1] = 'A#',
    [2] = 'B',
    [3] = 'C',
    [4] = 'C#',
    [5] = 'D',
    [6] = 'D#',
    [7] = 'E',
    [8] = 'F',
    [9] = 'F#',
    [10] = 'G',
    [11] = 'G#', 
    [12] = 'A',
    [13] = 'A#',
    [14] = 'B',
    [15] = 'C',
    [16] = 'C#',
    [17] = 'D',
    [18] = 'D#',
    [19] = 'E',
    [20] = 'F',
    [21] = 'F#',
    [22] = 'G',
    [23] = 'G#', 
}
tune.tonic_names = tonic_names

-- local seman_cinot = tab.invert(tonic_names)

local interval_names = {
    'octaves',
    "min 2nds", "maj 2nds",
    "min 3rds", "maj 3rds", "4ths",
    "tritones", "5ths", "min 6ths",
    "maj 6ths", "min 7ths", "maj 7ths",
}


function tune:get_tonic()
    return self:get_param('tonic') + params:get('base_tonic')
end


function tune:get_interval_enabled(i)
    return self:get_param('enable_'..i) > 0
end

function tune:get_intervals()
    return self:get_scale_ivs()
end

local fret_pattern_names = { '8ve', '8ve+5th', '#+b' }
local OCT, OCT_5TH, SHARP = 1, 2, 3

function tune:add_params(separator_name)
    local param_count = 4 

    -- params:add_separator('tuning')
    if self.add_param_separator then 
        params:add_separator('tuning_sep_'..self.id, separator_name) 
    elseif self.add_param_group then 
        params:add_group('tuning_grp_'..self.id, separator_name, param_count) 
    end

    -- params:add{
    --     type = 'number', id = 'tuning_preset', name = 'preset',
    --     min = 1, max = presets, default = 1, action = update_tuning,
    -- }

    self:add_param{
        type = 'option', id = 'tuning', name = 'tuning',
        options = self.tuning_names,
    }
    self:add_param{
        type = 'number', id = 'tonic', name = 'tonic',
        default = 0, min = -10, max = 10,
        formatter = function(p) 
            return tonic_names[self:get_tonic()]
        end
    }
    --TODO: base key
    -- for group_name, _ in pairs(self.scales) do
    --     self:add_param{
    --         type = 'option', id = 'scale_'..group_name, name = 'scale',
    --         options = self.scale_names[group_name],
    --     }
    -- end
    self:add_param{
        type = 'option', id = 'scale_class', name = 'scale class',
        options = class_names,
    }
    self:add_param{
        type = 'number', id = 'scale', name = 'scale', min = 1, max = 7,
        formatter = function(p)
            local group = self:get_tuning().scales
            local class = class_names[self:get_param('scale_class')]
            local idx = self:get_param('scale')

            return self.scales[group][class][idx].name
        end
    }
end

function tune:wrap(deg, oct)
    local iv = self:get_intervals()

    oct = oct + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1

    return deg, oct
end

--TODO: start row wrapping in the middle of the grid vertically somehow
function tune:degoct(row, column, trans, toct)
    local iv = self:get_intervals()
    local rowint = 0 
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0)
    deg, oct = self:wrap(deg, oct)
    
    return deg, oct
end

-- tune.is_tonic = function(row, column, trans)
--     return tune.degoct(row, column, trans) == 1
-- end

--number to be multiplied by reference A in hz
function tune:hz(row, column, trans, toct)
    local iv = self:get_intervals()
    local deg, oct = self:degoct(row, column, trans, toct)
    local tuning = self:get_tuning()

    return (
        2^(self:get_tonic()/(tuning.tones or 12)) * 2^oct 
        * (
            (tuning.temperment == 'just') 
            and (tuning.ratios[iv[deg] + 1])
            or (2^(iv[deg]/tuning.tones))
        )
    )
end

local JIVOLT = 1 / math.log(2)
local function justvolts(f) return math.log(f) * JIVOLT end

--0v == A
function tune:volts(row, column, trans, toct) 
    local iv = self:get_intervals()
    local toct = toct or 0
    local deg, oct = self:degoct(row, column, trans, toct)
    local tuning = self:get_tuning()

    if tuning.temperment == 'just' then
        return (
            justvolts(tuning.ratios[self:get_tonic() % 12 + 1]) 
            + oct 
            + justvolts(tuning.ratios[iv[deg] + 1])
            - 1
        )
    else
        return (
            (self:get_tonic()/(tuning.tones)) 
            + oct 
            + (iv[deg]/tuning.tones)
        )
    end
end

--number to be added to referece A
function tune:midi(row, column, trans, toct) 
    local iv = self:get_intervals()
    local deg, oct = self:degoct(row, column, trans, toct)

    return self:get_tonic() + (oct * 12) + iv[deg]
end

return tune
