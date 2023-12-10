local tune = {}
tune.__index = tune 

-- local tunings, scales, presets
-- local tuning_names, scale_names = {}, {}
-- local action = function() end

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
    self.scale_names = {}

    for i,tuning in ipairs(self.tunings) do
        self.tuning_names[i] = tuning.name
    end

    for k,group in pairs(self.scales) do
        self.scale_names[k] = {}

        for i,scale in ipairs(group) do
            self.scale_names[k][i] = scale.name
        end
    end

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

function tune:get_scale_param_id()
    local group = self:get_tuning().scales

    return self:get_param_id('scale_'..group)
end

function tune:get_scale_idx()
    local group = self:get_tuning().scales
    local idx = self:get_param('scale_'..group)

    return idx
end

function tune:get_scale_ivs()
    local group = self:get_tuning().scales
    local idx = self:get_param('scale_'..group)
    
    return self.scales[group][idx].iv
end

function tune:hide_show_params()
    local show = self.visibility_condition(self)

    if self.add_param_separator then 
        local id = 'tuning_sep_'..self.id
        if show then params:show(id) else params:hide(id) end
    elseif self.add_param_group then 
        local id = 'tuning_grp_'..self.id
        if show then params:show(id) else params:hide(id) end
    end

    for _,base in ipairs(self.param_ids) do
        local id = self:get_param_id(base)
        if show then params:show(id) else params:hide(id) end
    end

    local ivs = self:get_scale_ivs()
    for i = 1,12 do
        local id = self:get_param_id('enable_'..i)
        local showdeg = i <= #ivs
        if show and showdeg then params:show(id) else params:hide(id) end
    end

    if show then
        local group = self:get_tuning().scales

        for group_name, _ in pairs(self.scales) do
            local showgroup = group_name == group
            local id = self:get_param_id('scale_'..group_name)
            if showgroup then params:show(id) else params:hide(id) end
        end
    end

    _menu.rebuild_params() --questionable?
end

function tune:update_tuning()
    self:hide_show_params()
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
    return self:get_param('tonic')
end


function tune:get_interval_enabled(i)
    return self:get_param('enable_'..i) > 0
end

function tune:get_intervals()
    local scl = self:get_scale_idx()
    local all = self:get_scale_ivs()

    local some = {}
    for i,v in ipairs(all) do
        if self:get_interval_enabled(i) then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end

    return some
end

function tune:get_row_tuning()
    return self:get_param('row_tuning')
end

local fret_pattern_names = { '8ve', '8ve+5th', '#+b' }
local OCT, OCT_5TH, SHARP = 1, 2, 3


function tune:add_params(separator_name)
    local param_count = 2 + #self.scales + 2 + 12 + 2

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
        default = 3, min = -9, max = 14,
        formatter = function(p) 
            return tonic_names[p:get()]
        end
    }
    for group_name, _ in pairs(self.scales) do
        self:add_param{
            type = 'option', id = 'scale_'..group_name, name = 'scale',
            options = self.scale_names[group_name],
        }
    end
    self:add_param{
        type = 'number', id = 'row_tuning', name = 'row tuning',
        min = 1, max = 12, default = 6,
        formatter = function(p) 
            local iv = self:get_intervals()

            local rowint = p:get()

            local deg = (rowint - 1)%#iv + 1
            local interval = math.floor(iv[deg])

            return interval_names[interval + 1]
        end
    }
    self:add_param{
        type = 'option', id = 'fret_marks', name = 'fret marks',
        options = fret_pattern_names, default = SHARP,
    }

    -- params:add_group(self:get_param_id('note_toggles'), 'note toggles', 12)
    for i = 1,12 do
        self:add_param{
            type = 'binary', behavior = 'toggle', 
            id = 'enable_'..i, name = 'enable scale degree '..i,
            default = 1,
        }
    end

    self:hide_show_params()
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
    local rowint = self:get_row_tuning() - 1
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0)
    deg, oct = self:wrap(deg, oct)
    
    return deg, oct
end

-- tune.is_tonic = function(row, column, trans)
--     return tune.degoct(row, column, trans) == 1
-- end

--number to be multiplied by center freq in hz
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

--TODO
function tune:midi() end

return tune
