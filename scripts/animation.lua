-- scripts/animation.lua
-- loads every sprite sheet into memory once, then exposes them as
-- lookup tables that the player state machine can just index into.
-- each entry is { frames = <array of Image>, loop = bool, frame_time = seconds }

local animation = {}

-- builds a frame array from a folder + tile count.
-- names are zero-padded to 3 digits, because that's what the export tool gives us
local function loadSheet(folder, count)
    local out = {}
    for i = 0, count - 1 do
        local name = string.format("assets/%s/tile_%03d.png", folder, i)
        out[#out + 1] = love.graphics.newImage(name)
    end
    return out
end

function animation.load()
    -- keep the pixel art crisp at any zoom level
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- NOTE: the "Idel" typo in the folder name is on purpose, that's the path
    local idle_Frames = {
        love.graphics.newImage("assets/Player_Idel/tile_000.png"),
        love.graphics.newImage("assets/Player_Idel/tile_001.png"),
        love.graphics.newImage("assets/Player_Idel/tile_002.png"),
        love.graphics.newImage("assets/Player_Idel/tile_003.png"),
        love.graphics.newImage("assets/Player_Idel/tile_004.png"),
        love.graphics.newImage("assets/Player_Idel/tile_005.png"),
    }

    local walk_Frames = {
        love.graphics.newImage("assets/player_right_walk/tile_000.png"),
        love.graphics.newImage("assets/player_right_walk/tile_001.png"),
        love.graphics.newImage("assets/player_right_walk/tile_002.png"),
        love.graphics.newImage("assets/player_right_walk/tile_003.png"),
        love.graphics.newImage("assets/player_right_walk/tile_004.png"),
        love.graphics.newImage("assets/player_right_walk/tile_005.png"),
        love.graphics.newImage("assets/player_right_walk/tile_006.png"),
        love.graphics.newImage("assets/player_right_walk/tile_007.png"),
        love.graphics.newImage("assets/player_right_walk/tile_008.png"),
        love.graphics.newImage("assets/player_right_walk/tile_009.png"),
        love.graphics.newImage("assets/player_right_walk/tile_010.png"),
        love.graphics.newImage("assets/player_right_walk/tile_011.png"),
    }

    local jump_Frames = {
        love.graphics.newImage("assets/player_jump/tile_000.png"),
        love.graphics.newImage("assets/player_jump/tile_001.png"),
        love.graphics.newImage("assets/player_jump/tile_002.png"),
        love.graphics.newImage("assets/player_jump/tile_003.png"),
        love.graphics.newImage("assets/player_jump/tile_004.png"),
        love.graphics.newImage("assets/player_jump/tile_005.png"),
        love.graphics.newImage("assets/player_jump/tile_006.png"),
        love.graphics.newImage("assets/player_jump/tile_007.png"),
        love.graphics.newImage("assets/player_jump/tile_008.png"),
        love.graphics.newImage("assets/player_jump/tile_009.png"),
        love.graphics.newImage("assets/player_jump/tile_010.png"),
        love.graphics.newImage("assets/player_jump/tile_011.png"),
        love.graphics.newImage("assets/player_jump/tile_012.png"),
        love.graphics.newImage("assets/player_jump/tile_013.png"),
    }

    local dead_frames = {
        love.graphics.newImage("assets/player_die/tile_000.png"),
        love.graphics.newImage("assets/player_die/tile_001.png"),
        love.graphics.newImage("assets/player_die/tile_002.png"),
        love.graphics.newImage("assets/player_die/tile_003.png"),
        love.graphics.newImage("assets/player_die/tile_004.png"),
        love.graphics.newImage("assets/player_die/tile_005.png"),
        love.graphics.newImage("assets/player_die/tile_006.png"),
        love.graphics.newImage("assets/player_die/tile_007.png"),
        love.graphics.newImage("assets/player_die/tile_008.png"),
        love.graphics.newImage("assets/player_die/tile_009.png"),
    }

    local idle_lookaround_Frames = {
        love.graphics.newImage("assets/player_lookaround/tile_000.png"),
        love.graphics.newImage("assets/player_lookaround/tile_001.png"),
        love.graphics.newImage("assets/player_lookaround/tile_002.png"),
        love.graphics.newImage("assets/player_lookaround/tile_003.png"),
        love.graphics.newImage("assets/player_lookaround/tile_004.png"),
        love.graphics.newImage("assets/player_lookaround/tile_005.png"),
    }

    local slide_Frames = {
        love.graphics.newImage("assets/player_slide/tile_000.png"),
        love.graphics.newImage("assets/player_slide/tile_001.png"),
        love.graphics.newImage("assets/player_slide/tile_002.png"),
        love.graphics.newImage("assets/player_slide/tile_003.png"),
        love.graphics.newImage("assets/player_slide/tile_004.png"),
        love.graphics.newImage("assets/player_slide/tile_005.png"),
        love.graphics.newImage("assets/player_slide/tile_006.png"),
        love.graphics.newImage("assets/player_slide/tile_007.png"),
        love.graphics.newImage("assets/player_slide/tile_008.png"),
        love.graphics.newImage("assets/player_slide/tile_009.png"),
        love.graphics.newImage("assets/player_slide/tile_010.png"),
        love.graphics.newImage("assets/player_slide/tile_011.png"),
    }

    local punch_Frames = {
        love.graphics.newImage("assets/player_punch/tile_000.png"),
        love.graphics.newImage("assets/player_punch/tile_001.png"),
        love.graphics.newImage("assets/player_punch/tile_002.png"),
        love.graphics.newImage("assets/player_punch/tile_003.png"),
        love.graphics.newImage("assets/player_punch/tile_004.png"),
        love.graphics.newImage("assets/player_punch/tile_005.png"),
        love.graphics.newImage("assets/player_punch/tile_006.png"),
        love.graphics.newImage("assets/player_punch/tile_007.png"),
        love.graphics.newImage("assets/player_punch/tile_008.png"),
        love.graphics.newImage("assets/player_punch/tile_009.png"),
        love.graphics.newImage("assets/player_punch/tile_010.png"),
        love.graphics.newImage("assets/player_punch/tile_011.png"),
        love.graphics.newImage("assets/player_punch/tile_012.png"),
        love.graphics.newImage("assets/player_punch/tile_013.png"),
        love.graphics.newImage("assets/player_punch/tile_014.png"),
        love.graphics.newImage("assets/player_punch/tile_015.png"),
        love.graphics.newImage("assets/player_punch/tile_016.png"),
        love.graphics.newImage("assets/player_punch/tile_017.png"),
    }

    local crouch_Frames = {
        love.graphics.newImage("assets/player_crouch/tile_000.png"),
        love.graphics.newImage("assets/player_crouch/tile_001.png"),
        love.graphics.newImage("assets/player_crouch/tile_002.png"),
        love.graphics.newImage("assets/player_crouch/tile_003.png"),
        love.graphics.newImage("assets/player_crouch/tile_004.png"),
        love.graphics.newImage("assets/player_crouch/tile_005.png"),
        love.graphics.newImage("assets/player_crouch/tile_006.png"),
        love.graphics.newImage("assets/player_crouch/tile_007.png"),
        love.graphics.newImage("assets/player_crouch/tile_008.png"),
        love.graphics.newImage("assets/player_crouch/tile_009.png"),
    }

    local look_down_Frames = {
        love.graphics.newImage("assets/player_look_down/tile_000.png"),
        love.graphics.newImage("assets/player_look_down/tile_001.png"),
        love.graphics.newImage("assets/player_look_down/tile_002.png"),
        love.graphics.newImage("assets/player_look_down/tile_003.png"),
        love.graphics.newImage("assets/player_look_down/tile_004.png"),
        love.graphics.newImage("assets/player_look_down/tile_005.png"),
        love.graphics.newImage("assets/player_look_down/tile_006.png"),
        love.graphics.newImage("assets/player_look_down/tile_007.png"),
        love.graphics.newImage("assets/player_look_down/tile_008.png"),
        love.graphics.newImage("assets/player_look_down/tile_009.png"),
    }

    local look_up_Frames = {
        love.graphics.newImage("assets/player_look_up/tile_000.png"),
        love.graphics.newImage("assets/player_look_up/tile_001.png"),
        love.graphics.newImage("assets/player_look_up/tile_002.png"),
        love.graphics.newImage("assets/player_look_up/tile_003.png"),
        love.graphics.newImage("assets/player_look_up/tile_004.png"),
        love.graphics.newImage("assets/player_look_up/tile_005.png"),
        love.graphics.newImage("assets/player_look_up/tile_006.png"),
        love.graphics.newImage("assets/player_look_up/tile_007.png"),
        love.graphics.newImage("assets/player_look_up/tile_008.png"),
        love.graphics.newImage("assets/player_look_up/tile_009.png"),
    }

    -- yes, "coruch" is misspelled in the folder. don't rename it or load breaks
    local crouch_walk_Frames = {
        love.graphics.newImage("assets/player_coruch_walk/tile_000.png"),
        love.graphics.newImage("assets/player_coruch_walk/tile_001.png"),
        love.graphics.newImage("assets/player_coruch_walk/tile_002.png"),
        love.graphics.newImage("assets/player_coruch_walk/tile_003.png"),
    }

    local ladder_frames = {
        love.graphics.newImage("assets/player_ladders_climb/tile_000.png"),
        love.graphics.newImage("assets/player_ladders_climb/tile_001.png"),
        love.graphics.newImage("assets/player_ladders_climb/tile_002.png"),
        love.graphics.newImage("assets/player_ladders_climb/tile_003.png"),
        love.graphics.newImage("assets/player_ladders_climb/tile_004.png"),
    }

    local hang_frames = {
        love.graphics.newImage("assets/player_down_the_wall/tile_000.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_001.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_002.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_003.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_004.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_005.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_006.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_007.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_008.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_009.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_010.png"),
        love.graphics.newImage("assets/player_down_the_wall/tile_011.png"),
    }

    local dash_frames = {
        love.graphics.newImage("assets/player_dash/tile_000.png"),
        love.graphics.newImage("assets/player_dash/tile_001.png"),
        love.graphics.newImage("assets/player_dash/tile_002.png"),
        love.graphics.newImage("assets/player_dash/tile_003.png"),
        love.graphics.newImage("assets/player_dash/tile_004.png"),
        love.graphics.newImage("assets/player_dash/tile_005.png"),
        love.graphics.newImage("assets/player_dash/tile_006.png"),
        love.graphics.newImage("assets/player_dash/tile_007.png"),
        love.graphics.newImage("assets/player_dash/tile_008.png"),
        love.graphics.newImage("assets/player_dash/tile_009.png"),
    }

    local crouch_jump_Frames = {
        love.graphics.newImage("assets/player_crouch_jump/tile_000.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_001.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_002.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_003.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_004.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_005.png"),
        love.graphics.newImage("assets/player_crouch_jump/tile_006.png"),
    }

    -- frame_time here is per-frame seconds, not fps.
    -- loop=false on the one-shots so the player controller can detect the end.
    animation.idle            = { frames = idle_Frames,            loop = true,  frame_time = 0.25 }
    animation.walk            = { frames = walk_Frames,            loop = true,  frame_time = 0.05 }
    animation.jump            = { frames = jump_Frames,            loop = true,  frame_time = 0.04 }
    animation.crouch          = { frames = crouch_Frames,          loop = true,  frame_time = 0.08 }
    animation.crouch_walk     = { frames = crouch_walk_Frames,     loop = true,  frame_time = 0.08 }
    animation.crouch_jump     = { frames = crouch_jump_Frames,     loop = true,  frame_time = 0.05 }
    animation.dead            = { frames = dead_frames,            loop = true,  frame_time = 0.10 }
    animation.idle_lookaround = { frames = idle_lookaround_Frames, loop = true,  frame_time = 0.30 }
    animation.punch           = { frames = punch_Frames,           loop = false, frame_time = 0.03 }
    animation.dash            = { frames = dash_frames,            loop = false, frame_time = 0.03 }
    animation.slide           = { frames = slide_Frames,           loop = false, frame_time = 0.04 }
    animation.hang            = { frames = hang_frames,            loop = true,  frame_time = 0.08 }
    animation.ladder          = { frames = ladder_frames,          loop = true,  frame_time = 0.08 }
    animation.look_up         = { frames = look_up_Frames,         loop = true,  frame_time = 0.10 }
    animation.look_down       = { frames = look_down_Frames,       loop = true,  frame_time = 0.10 }
end

return animation