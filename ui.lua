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

function Tune.grid.fretboard()
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then 
            local tune = props.tune

            local g = crops.handler 

            for i = 1, props.size do
                local lvl

                local x, y = Grid.util.index_to_xy(props, i)
                do
                    local o_x = props.flow == 'right' and props.x or props.x - props.wrap
                    local o_y = props.flow_wrap == 'up' and props.y or (
                        props.y - (props.size//props.wrap)
                    )
                    local column = x - o_x

                    mark = (
                        (props.heptatonic and (column%7 == 0))
                        or (props.pentatonic and (column%5 == 0))
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
            local is_enabled = deg and true
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
