-- import 12tet scales from musicutil

local major = { 0, 2, 4, 5, 7, 9, 11 }

-- local 
function mode(scale, base)
    local m = {}

    for i = 1,#scale do
        local iv = util.wrap(i + base - 1, 1, #scale)
        local offset = scale[base]

        table.insert(m, util.wrap(scale[iv] - offset, 0, 11))
    end

    return m
end

-- local 
heptatonic = {
    { name = 'ionian', iv = mode(major, 1) },
    { name = 'dorian', iv = mode(major, 2) },
    { name = 'phrygian', iv = mode(major, 3) },
    { name = 'lydian', iv = mode(major, 4) },
    { name = 'myxolydian', iv = mode(major, 5) },
    { name = 'aeolian', iv = mode(major, 6) },
    { name = 'locrian', iv = mode(major, 7) },
}

local pentatonic = {}

-- maqam scales - could defnintely use some more !
local maqam = {
    { name = 'Bayati (Jins Nahawand)', iv = { 0, 1.5, 3, 5, 7, 8, 10, }},
    { name = 'Bayati (Jins Rast)', iv = { 0, 1.5, 3, 5, 7, 8.5, 10, }},
    { name = 'Bayati Shuri', iv = { 0, 1.5, 3, 5, 6, 9.5, 10, }},
    { name = 'Hijaz (Jins Nahawand)', iv = { 0, 1, 4, 5, 7, 8, 10, }},
    { name = 'Hijaz (Jins Rast)', iv = { 0, 1, 4, 5, 7, 8.5, 10, }},
}

-- local scale_groups = {
--     ['12 tone'] = { heptatonic = heptatonic, pentatonic = pentatonic, },
--     ['maqam'] = { heptatonic = maqam },
-- }
local scale_groups = {
    ['12 tone'] = heptatonic,
    ['maqam'] = maqam,
}

local tunings = {
    { name='12tet', temperment = 'equal', tones = 12, scales = '12 tone' },
    { name='maqam', temperment = 'equal', tones = 12, scales = 'maqam' },
}

-- JI tunings -- thx ezra !

local JI = require 'lib/intonation'

local pythag = function()
   local function p5(a, b)
       print(3^a, 2^b) 
      return (3^a) / (2^b)
   end
   local function p4(a, b)
       print(2^a, 3^b) 
      return (2^a) / (3^b)
   end
   return {
      1,          -- unison
      p4(8, 5),   -- min 2nd
      p5(2, 3),   -- Maj 2nd
      p4(5, 3),   -- min 3rd
      p5(4, 6),   -- Maj 3rd
      p4(2, 1),   -- p 4th
      --p4(10, 6),  -- dim 5th
      p5(6, 9),   -- aug 4th
      p5(1, 1),   -- p 5th
      p4(7, 4),   -- min 6th
      p5(3, 4),   -- maj 6th
      p4(4, 2),   -- min 7th
      p5(5, 7),   -- maj 7th
   }
end
table.insert(tunings, {
    name = 'ji pythagoras',
    scales = '12 tone',
    ratios = pythag(),
    temperment = 'just',
})

-- "chromaticized" version of ptolemy's intense diatonic
-- (new intervals constructed from major thirds)

table.insert(tunings, {
    name = 'ji ptolemaic',
    scales = '12 tone',
    temperment = 'just',
    ratios = {	    
        1,            -- C  
        4/3 * 4/5,    -- Db
        9/8,          -- D
        3/2 * 4/5,    -- Eb
        5/4,          -- E
        4/3,          -- F
        9/8 * 5/4,    -- F#
        3/2,          -- G
        5/4 * 5/4,    -- G#
        5/3,          -- A
        9/4 * 4/5,    -- Bb
        15/8,         -- B
    },
})

table.insert(tunings, {
    name = 'ji normal',
    scales = '12 tone',
    ratios = JI.normal(),
    temperment = 'just',
})

table.insert(tunings, {
    name = 'ji overtone',
    scales = '12 tone',
    ratios = JI.overtone(),
    temperment = 'just',
})

table.insert(tunings, {
    name = 'ji undertone',
    scales = '12 tone',
    ratios = JI.undertone(),
    temperment = 'just',
})

table.insert(tunings, {
    name = 'ji lamonte',
    scales = '12 tone',
    ratios = JI.lamonte(),
    temperment = 'just',
})

-- quarter-comma meantone
local qmt = function()
   local a = 5 ^ 0.5
   local b = 5 ^ 0.25
   local c = a * b
   return {
      1,           -- unison
      8 * c / 25,   -- min 2nd
      a / 2,       -- Maj 2nd
      4 * b / 5,   -- min 3rd
      5 / 4,       -- Maj 3rd
      2 * c / 5,   -- p 4th
      --16 * a/25, -- dim 5th
      5 * a / 8,   -- aug 4th
      b,           -- p 5th
      8 / 5,       -- min 6th
      c / 2,       -- Maj 6th
      4 * a / 5,   -- min 7th
      5 * b / 4    -- Maj 7th
   }
end
table.insert(tunings, {
    name = 'ji meantone',
    scales = '12 tone',
    ratios = qmt(),
    temperment = 'just',
})

-- werckmeister III
local werck3 = function()
   local a = 2 ^ 0.5
   local a2 = 2 ^ 0.25
   return {
      1,
      256 / 243,
      64 / 81 * a,
      32 / 27,
      256 / 243 * a2,
      4 / 3,
      1024 / 729,
      8 / 9 * (8 ^ 0.25),
      128 / 81,
      1024 / 729 * a2,
      16 / 9,
      128 / 81 * a2
   }
end
table.insert(tunings, {
    name = 'ji werck3',
    scales = '12 tone',
    ratios = werck3(),
    temperment = 'just',
})

return tunings, scale_groups
