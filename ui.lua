local Tune = { grid = {}, screen = {} }

function Tune.of_param(tune, id)
    local p_id = tune:get_param_id(id)
    return {
        params:get(p_id),
        params.set, params, p_id
    }
end

--'A','A#','B','C','C#','D','D#','E','F','F#','G','G#'
-- 1   2    3   4   5    6   7    8   9   10   11  12

local OCT, OCT_5TH, SHARP = 1, 2, 3

local function get_level(props, ivs, tonic, pattern, x, y)
    local lvl
    local o_x = props.flow == 'right' and props.x or props.x - props.wrap
    local o_y = props.flow_wrap == 'up' and props.y or (
        props.y - (props.size//props.wrap)
    )
    local column = x - o_x + 1 + (props.column_offset or 0)
    local row = o_y - y + 1 + (props.row_offset or 0)

    local deg = props.tune:degoct(column, row, props.trans, props.toct)
    local iv = ivs[deg]
    local n = (iv+tonic)%12+1

    local mark = (
        pattern == OCT and (
            iv == 0
        ) or pattern == OCT_5TH and (
            iv == 0 or iv == 7
        ) or pattern == SHARP and (
            n==2 or n==5 or n==7 or n==10 or n==12
        )
    )
    lvl = props.levels[mark and 2 or 1]

    return lvl
end

function Tune.grid.fretboard()
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then 
            local tune = props.tune

            local g = crops.handler 

            local ivs = tune:get_intervals()
            local tonic = tune:get_tonic()
            local pattern = tune:get_param('fret_marks')

            for i = 1, props.size do

                local x, y = Grid.util.index_to_xy(props, i)
                local lvl = get_level(props, ivs, tonic, pattern, x, y)

                do
                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

function Tune.screen.fretboard()
    return function(props)
        if crops.device == 'screen' and crops.mode == 'redraw' then 
            local tune = props.tune
            local ivs = tune:get_intervals()
            local tonic = tune:get_tonic()
            local pattern = tune:get_param('fret_marks')

            for i = 1, props.size do
                local mask_props = {
                    flow = props.flow,
                    flow_wrap = props.flow_wrap,
                    wrap = props.wrap,
                    padding = props.padding,
                    column_offset = props.column_offset,
                    row_offset = props.row_offset,
                    tune = props.tune,
                    levels = props.levels,
                    x = 1,
                    y = 1,
                }

                local x, y = Grid.util.index_to_xy(mask_props, i)
                local lvl = get_level(mask_props, ivs, tonic, pattern, x, y)

                do
                    if lvl>0 then 
                        screen.level(lvl)
                        screen.pixel(
                            (x - 1)*2 + props.x, 
                            (y - 1)*2 + props.y
                        )
                        screen.fill()
                    end
                end
            end
        end
    end
end

-- local 
kb = {}
do
    local __ = nil
    kb.grid = {
             { -11, __, -8, -6, __, -3, -1, 01, __, 04, 06, __, 09, 11, 13, __, 16, 18, __, 21 },
         { -12, -10,  -9, -7, -5, -4, -2, 00, 02, 03, 05, 07, 08, 10, 12, 14, 15, 17, 19, 20, 22, }
    }
end
kb.pos = {}
for i = -12,22 do
    for y = 1,2 do
        for x,v in pairs(kb.grid[y]) do
            if i == v then
                kb.pos[i] = { x=x, y=y }
                kb.pos[i+0.5] = { x=x, y=y }
            end
        end
    end
end
kb.pos_octs = {}
for i = -12, -1 do
    kb.pos_octs[i] = {}
    kb.pos_octs[i + 0.5] = {}
    kb.pos_octs[i + 12] = {}
    kb.pos_octs[i + 12 + 0.5] = {}
    for oct = 0,2 do
        local i_o = oct*12 + i
        kb.pos_octs[i][oct + 1] = kb.pos[i_o]
        kb.pos_octs[i + 0.5][oct + 1] = kb.pos[i_o]
        kb.pos_octs[i + 12][oct + 1] = kb.pos[i_o]
        kb.pos_octs[i + 12 + 0.5][oct + 1] = kb.pos[i_o]
    end
end

function Tune.grid.tonic()
    return function(props)
        if crops.device == 'grid' then 
            local left, top = props.left or 1, props.top or 1
            local base = params:get('base_tonic')

            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)

                for i = -11,11 do
                    local pos = kb.pos[i + base]
                    local d = pos.x - (base//2) - props.nudge

                    if
                        z == 1 
                        and x == left + d 
                        and y == top + pos.y - 1 
                        and d >= 0 and d < props.width
                    then
                        crops.set_state(props.state, i)
                        break
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler 

                for i = -11,11 do
                    local v = crops.get_state(props.state) or 1
                    local pos = kb.pos[i + base]
                    local lvl = props.levels[(v == i) and 2 or 1]
                    local d = pos.x - (base//2) - props.nudge
                    local x = left + d
                    local y = top + pos.y - 1

                    if lvl>0 and d >= 0 and d < props.width then g:led(x, y, lvl) end
                end
            end
        end
    end
end

function Tune.grid.scale_degrees_background()
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then 
            local g = crops.handler 
            local left, top = props.left or 1, props.top or 1
            local lvl = props.level
            local base = params:get('base_tonic')

            for i = -11,11 do
                local pos = kb.pos[i + base]
                local d = pos.x - (base//2) - props.nudge
                local x = left + d
                local y = top + pos.y - 1

                if lvl>0 and d >= 0 and d < props.width then g:led(x, y, lvl) end
            end
        end
    end
end

function Tune.grid.scale_degree()
    return function(props)
        if crops.device == 'grid' then 
            local left, top = props.left or 1, props.top or 1
            local base = params:get('base_tonic')

            local tune = props.tune
            local deg = props.degree
            local ivs = tune:get_scale_ivs()
            local iv = ivs[deg]

            if iv then
                local i = (math.floor(iv) + tune:get_tonic()) % 12
                local ii = i
                if ii > 2.5 then ii = ii - 12 end

                if crops.mode == 'input' then
                    local x, y, z = table.unpack(crops.args)

                    for oct, pos in ipairs(kb.pos_octs[ii]) do 
                        local d = pos.x - (base//2) - props.nudge
                        if 
                            z == 1 
                            and x == left + d 
                            and y == top + pos.y - 1 
                            and d >= 0 and d < props.width
                        then
                            local v = crops.get_state(props.state) or 0

                            crops.set_state(props.state, ~ v & 1)
                            break
                        end 
                    end
                elseif crops.mode == 'redraw' then
                    local g = crops.handler 

                    local v = crops.get_state(props.state) or 0
                    local lvl = props.levels[v + 1]

                    if lvl>0 then for oct, pos in ipairs(kb.pos_octs[ii]) do
                        local d = pos.x - (base//2) - props.nudge
                        local x = left + d
                        local y = top + pos.y - 1

                        if d >= 0 and d < props.width then g:led(x, y, lvl) end
                    end end
                end
            end
        end
    end
end

-- ^ for half flat/sharp
local note_names = {
    [1] = 'A', [1.5] = 'A^#', 
    [2] = 'A#', [2.5] = 'B^b', 
    [3] = 'B', [3.5] = 'B^#', 
    [4] = 'C', [4.5] = 'C^#', 
    [5] = 'C#', [5.5] = 'D^b', 
    [6] = 'D', [6.5] = 'D^#', 
    [7] = 'D#', [7.5] = 'E^b',
    [8] = 'E',  [8.5] = 'E^#', 
    [9] = 'F', [9.5] = 'F^#', 
    [10] = 'F#', [10.5] = 'G^b', 
    [11] = 'G', [11.5] = 'G^#', 
    [12] = 'G#', [12.5] = 'A^b',
}
local tonic_names = {}
for i = 4, 15 do table.insert(tonic_names, note_names[(i-1)%12+1]) end

function Tune.screen.scale_degrees()
    local _notes = {}
    for i = 1, 24 do _notes[i] = Produce.screen.text_highlight() end

    return function(props)
        local tune = props.tune
            
        local left, top = props.x or 1, props.y or 1
        local base = params:get('base_tonic')
        local tuning = tune:get_tuning()
        local ji = tuning.temperment == 'just'
        local ivs = tune:get_scale_ivs()
        local tonic = tune:get_tonic()

        for i = #_notes, 1, -1 do
            local _note = _notes[i]
            local ii = i/2 + 0.5 - 1

            local iv = (ii-tonic)%12
            local st = (iv+tonic)%12+1
            local deg = tab.key(ivs, iv)

            local is_interval = tab.contains(ivs, iv)
            local is_enabled = deg and tune:get_interval_enabled(deg)
            local is_tonic = iv==0

            for oct, pos in ipairs(kb.pos_octs[ii]) do
                local d = pos.x - (base//2) - props.nudge
                local xx = left + d*10
                local yy = top + (pos.y - 1)*10
                
                if d >= 0 and d < props.width then
                    _note{
                        x = xx, y = yy,
                        padding = 1.5,
                        font_face = 2,
                        nudge = true, squish = true,
                        levels = {
                            is_tonic and 0 or (is_interval and is_enabled) and 15  or 2,
                            (is_interval and is_enabled and is_tonic) and 10  or 0
                        },
                        text = (
                            is_interval and (note_names[st]) or '.'
                        )
                    }
                end
            end
        end
    end
end

return Tune
