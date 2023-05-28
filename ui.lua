local Tune = { grid = {}, screen = {} }

function Tune.of_preset_param(id)
    local p_id = id..'_preset_'..tune.get_preset()
    return {
        params:get(p_id),
        params.set, params, p_id
    }
end

--'A','A#','B','C','C#','D','D#','E','F','F#','G','G#'
-- 1   2    3   4   5    6   7    8   9   10   11  12

local OCT, OCT_5TH, SHARP = 1, 2, 3

function Tune.grid.fretboard()
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then 
            local g = crops.handler 

            local ivs = tune.get_intervals()
            -- local toct = toct or 0
            local tonic = tune.get_tonic()
            local pattern = tune.get_preset_param('fret_marks')

            for i = 1, props.size do
                local lvl

                local x, y = Grid.util.index_to_xy(props, i)
                do
                    local o_x = props.flow == 'right' and props.x or props.x - props.wrap
                    local o_y = props.flow_wrap == 'up' and props.y or (
                        props.y - (props.size//props.wrap)
                    )
                    local column = x - o_x + 1 + (props.column_offset or 0)
                    local row = o_y - y + 1 + (props.row_offset or 0)

                    local deg = tune.degoct(column, row, props.trans, props.toct)
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
                end

                do
                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

-- https://stackoverflow.com/questions/43565484/how-do-you-take-a-decimal-to-a-fraction-in-lua-with-no-added-libraries
local function to_frac(num)
    local W = math.floor(num)
    local F = num - W
    local pn, n, N = 0, 1
    local pd, d, D = 1, 0
    local x, err, q, Q
    repeat
        x = x and 1 / (x - q) or F
        q, Q = math.floor(x), math.floor(x + 0.5)
        pn, n, N = n, q*n + pn, Q*n + pn
        pd, d, D = d, q*d + pd, Q*d + pd
        err = F - N/D
   until math.abs(err) < 1e-15

   return N + D*W, D, err
end

local kb = {}
do
    --TODO: add lower octave
    local __ = nil
    kb.grid = {
          { 04, 06, __, 09, 11, 13, },
        { 03, 05, 07, 08, 10, 12, 14, }
    }
end
kb.pos = {}
for i = 1,12 do
    for y = 1,2 do
        for x,v in ipairs(kb.grid[y]) do
            if i == v then
                kb.pos[i] = { x=x, y=y }
                kb.pos[i+0.5] = { x=x, y=y }
            end
        end
    end
end

function Tune.grid.tonic()
    return function(props)
        if crops.device == 'grid' then 
            local left, top = props.left or 1, props.top or 1

            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)

                for i = 1,12 do
                    if 
                        z == 1 
                        and x == (left + kb.pos[i].x - 1) 
                        and y == (top + kb.pos[i].y - 1) 
                    then
                        crops.set_state(props.state, i)
                        break
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler 

                for i = 1,12 do
                    local v = crops.get_state(props.state) or 1
                    local pos = kb.pos[i]
                    local lvl = props.levels[(v == i) and 2 or 1]

                    if lvl>0 then g:led(left + pos.x - 1, top + pos.y - 1, lvl) end
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

            for i = 1,12 do
                local pos = kb.pos[i]

                if lvl>0 then g:led(left + pos.x - 1, top + pos.y - 1, lvl) end
            end
        end
    end
end

function Tune.grid.scale_degree()
    return function(props)
        if crops.device == 'grid' then 
            local left, top = props.left or 1, props.top or 1

            local deg = props.degree
            local ivs = tune.get_scale_ivs()
            local iv = ivs[deg]

            if iv then
                local i = (math.floor(iv) + tune.get_tonic()) % 12 + 1

                if crops.mode == 'input' then
                    local x, y, z = table.unpack(crops.args)

                    if 
                        z == 1 
                        and x == (left + kb.pos[i].x - 1) 
                        and y == (top + kb.pos[i].y - 1) 
                    then
                        local v = crops.get_state(props.state) or 0

                        crops.set_state(props.state, ~ v & 1)
                    end
                elseif crops.mode == 'redraw' then
                    local g = crops.handler 

                    local v = crops.get_state(props.state) or 0
                    local pos = kb.pos[i]
                    local lvl = props.levels[v + 1]

                    if lvl>0 then g:led(left + pos.x - 1, top + pos.y - 1, lvl) end
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
        for i = #_notes, 1, -1 do
            local _note = _notes[i]
            local ii = i/2 + 0.5

            local mul = 10
            local p = kb.pos[ii]
            local xx = props.x + (p.x - 1) * 20
            local yy = props.y + (p.y - 1) * 10

            local tuning = tune.get_tuning()
            local ji = tuning.temperment == 'just'
            local ivs = tune.get_scale_ivs()
            local tonic = tune.get_tonic()
            local iv = (ii-1-tonic)%12
            local st = (iv+tonic)%12+1
            local deg = tab.key(ivs, iv)

            local is_interval = tab.contains(ivs, iv)
            local is_enabled = deg and tune.get_interval_enabled(deg)
            local is_tonic = iv==0

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
                    is_interval and (  
                        ji and (
                            string.format(
                                "%d/%d",
                                to_frac(tuning.ratios[iv+1])
                            )
                        ) or (
                            note_names[st]
                        )
                    ) or '.'
                )
            }
        end
    end
end

return Tune
