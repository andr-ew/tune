local Tune = { grid = {}, screen = {} }

--TODO: trans & toct props, maybe
function Tune.grid.fretboard()
    return function(props)
        if crops.device == 'grid' and crops.mode == 'redraw' then 
            local g = crops.handler 

            for i = 1, props.size do
                local x, y = Grid.util.index_to_xy(props, i)

                local v = (tune.degoct(x, y) == 1) and 1 or 0
                local lvl = props.levels[v + 1]

                if lvl>0 then g:led(x, y, lvl) end
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
kb.grid = {
      { 05, 07, 00, 10, 12, 02, },
    { 04, 06, 08, 09, 11, 01, 03, }
}
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

local function KeyboardBackground(args)
    local left, top = args.left or 1, args.top or 1
    local width = args.width or 16

    return function(props)
        local lvl = 4

        local g = nest.grid.device()

        if nest.grid.is_drawing() then
            for i = 1,12 do
                local pos = kb.pos[i]

                g:led(left + pos.x - 1, top + pos.y - 1, lvl)
            end
        end
    end
end

function Tune.grid.scale_degrees(args)
    local left, top = args.left or 1, args.top or 1
    local width = args.width or 16

    local _bg = KeyboardBackground({ left = left, top = top, width = width })

    local _mutes = {}
    for i = 1, 24 do _mutes[i] = Grid.toggle() end

    return function(props)
        props.preset = props.preset or 1
        local p = props.preset

        _bg()

        for i,_mute in ipairs(_mutes) do
            local ii = i/2 + 0.5

            local scl = state(p).scale
            local ivs = mode(p).scales[scl].iv
            local iv = (ii-1-tonic(p))%12
            local deg = tab.key(ivs, iv)
            local is_interval = tab.contains(ivs, iv)

            if is_interval then _mute{
                x = left + kb.pos[ii].x - 1,
                y = top + kb.pos[ii].y - 1,
                lvl = { 8, 15 },
                state = {
                    deg and state(p).toggles[scl][deg] or 0,
                    function(v)
                        if deg then state(p).toggles[scl][deg] = v end
                        nest.screen.make_dirty()
                    end
                },
            } end
        end
    end
end

function Tune.grid.tonic(args)
    local left, top = args.left or 1, args.top or 1
    local width = args.width or 16

    local _bg = KeyboardBackground({ left = left, top = top, width = width })

    local _toggles = {}
    for i = 1, 12 do _toggles[i] = Grid.toggle() end

    return function(props)
        props.preset = props.preset or 1
        local p = props.preset

        _bg()

        for i,_toggle in ipairs(_toggles) do
            _toggle{
                x = left + kb.pos[i].x - 1,
                y = top + kb.pos[i].y - 1,
                lvl = { 0, 15 },
                state = {
                    states[p].tonic == (i - 4)%12+1 and 1 or 0,
                    function(v)
                        if v > 0 then
                            states[p].tonic = (i - 4)%12+1
                            nest.screen.make_dirty()
                        end
                    end
                }
            }
        end
    end
end

function Tune.screen.scale_degrees(args)
    local _labels = {}
    for i = 1, 24 do _labels[i] = Text.label() end

    return function(props)
        props.preset = props.preset or 1
        local i = props.preset

        for ii2,_label in ipairs(_labels) do
            local ii = ii2/2 + 0.5

            local mul = 10
            local p = kb.pos[ii]
            local xx = 4 + (p.x - 1) * 20
            local yy = y[1.5] + (p.y - 1) * 10

            local ji = mode(i).temperment == 'just'
            local scl = state(i).scale
            local ivs = mode(i).scales[scl].iv
            local iv = (ii-1-tonic(i))%12
            local st = (iv+tonic(i))%12+1
            local deg = tab.key(ivs, iv)

            local is_interval = tab.contains(ivs, iv)
            local is_enabled = deg and (state(i).toggles[scl][deg] == 1)
            local is_tonic = iv==0

            _label{
                x = xx, y = yy, 
                padding = 1.5,
                font_face = 2,
                lvl = is_tonic and 0 or (is_interval and is_enabled) and 15  or 2,
                fill = (is_interval and is_enabled and is_tonic) and 10  or 0,
                label = (
                    tab.contains(ivs, iv) and (  
                        ji and (
                            string.format(
                                "%d/%d",
                                to_frac(mode(i).ratios[iv+1])
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
