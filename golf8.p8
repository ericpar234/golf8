pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function _init()

  max_height = 0

  cam_x = 0
  cam_y = 0
  cam_pan_timer = 0
  cam_pan_start_x = 0
  cam_pan_start_y = 0
  cam_pan_end_x = 0
  cam_pan_end_y = 0

  hole_locations = {

    {par=4, tee_x=35, tee_y=37, hole_x=40*8+4, hole_y=20*8+4, bb={x1=33, y1=38, x2=44, y2=17}},
    {par=5, tee_x=5, tee_y=36,  hole_x=2*8+4, hole_y=17*8+4,  bb={x1=0, y1=37, x2=10, y2=15}},
    {par=4, tee_x=3, tee_y=12,   hole_x=16*8+4, hole_y=10*8+4,  bb={x1=0, y1=13, x2=18, y2=2}},
    {par=3, tee_x=22, tee_y=11, hole_x=22*8+4, hole_y=4*8+4,  bb={x1=19, y1=13, x2=25, y2=1}},
    {par=4, tee_x=14, tee_y=62, hole_x=14*8+4, hole_y=51*8+4, bb={x1=10, y1=63, x2=18, y2=47}},
    {par=3, tee_x=4, tee_y=46, hole_x=6*8+2, hole_y=41*8+4, bb={x1=0, y1=46, x2=9, y2=38}},
    {par=4, tee_x=14, tee_y=46, hole_x=15*8+4, hole_y=33*8+4, bb={x1=9, y1=47, x2=19, y2=31}},
    {par=3, tee_x=45, tee_y=34, hole_x=54*8,   hole_y=31*8,   bb={x1=44, y1=35, x2=57, y2=28}},
    {par=5, tee_x=38, tee_y=62, hole_x=42*8+4, hole_y=42*8+4, bb={x1=32, y1=63, x2=44, y2=39}},
    -- back nine
    {par=4, tee_x=4, tee_y=62, hole_x=6*8+4, hole_y=50*8+4,  bb={x1=0, y1=63, x2=9, y2=47}},
    {par=5, tee_x=20, tee_y=62, hole_x=22*8+4, hole_y=45*8+4, bb={x1=19, y1=63, x2=31, y2=43}},
    {par=4, tee_x=31, tee_y=30, hole_x=24*8+4, hole_y=18*8+4, bb={x1=23, y1=31, x2=32, y2=15}},
    {par=5, tee_x=52, tee_y=15, hole_x=29*8+4, hole_y=5*8+4,  bb={x1=26, y1=16, x2=62, y2=0}},
    {par=3, tee_x=23, tee_y=40, hole_x=30*8+4, hole_y=34*8+4, bb={x1=20, y1=42, x2=32, y2=32}},
    {par=3, tee_x=50, tee_y=62, hole_x=50*8+4, hole_y=53*8+4, bb={x1=45, y1=63, x2=55, y2=51}},
    {par=4, tee_x=54, tee_y=50, hole_x=50*8+4, hole_y=38*8+4, bb={x1=45, y1=51, x2=56, y2=36}},
    {par=4, tee_x=45, tee_y=27, hole_x=47*8+4, hole_y=19*8+4, bb={x1=44, y1=28, x2=58, y2=17}},
    {par=5, tee_x=15, tee_y=30, hole_x=19*8+4, hole_y=15*8+4, bb={x1=11, y1=31, x2=22, y2=13}},
  }

  for h=1, #hole_locations do
    hole_locations[h].score = -1
    hole_locations[h].tee_x	*= 8
    hole_locations[h].tee_y	*= 8
    hole_locations[h].tee_x	+= 4
    hole_locations[h].tee_y	+= 4
  end

  course2_locations = make_course("4,74,15,68,2,64,15,75,0,3,68,26,73,18,64,26,75,16,5,69,47,72,29,64,48,75,27,4,72,62,68,51,64,63,75,49,4,78,14,86,2,76,14,88,0,3,85,25,80,17,76,25,88,15,5,78,46,86,28,76,47,88,26,4,85,62,80,50,76,63,88,48,4,95,13,98,2,89,14,101,0,4,99,29,93,17,89,30,101,15,5,95,51,99,33,89,52,101,31,3,93,62,99,55,89,63,101,53,4,108,16,104,2,102,17,114,0,4,106,34,112,20,102,35,114,18,3,111,46,106,37,102,47,114,36,5,121,21,124,2,115,22,127,0,4,124,39,118,25,115,40,127,23,4,119,62,124,44,115,63,127,41")
  -- driving range lives in the unused lower-middle area of dune ridge
  range_locations = {{par=3,tee_x=108*8+4,tee_y=62*8+4,hole_x=109*8+4,hole_y=54*8+4,bb={x1=102,y1=63,x2=114,y2=48},score=-1}}
  range_targets = {{x=104*8+4,y=58*8+4},{x=109*8+4,y=54*8+4},{x=104*8+4,y=50*8+4}}
  courses = {hole_locations, course2_locations, range_locations}
  course_names = {"willow creek", "dune ridge", "driving range"}
  course_number = 1
  yards_per_pixel = 3

  hole_radius = 1.75

  -- terrain
  tt = "tee" -- "tee", "fairway", "green", "rough", "bunker", "water"

  ball_radius_ground = 1
  ball_radius_air = 2

  -- simple obstacle heights/collision
  rock_height = 1.8
  tree_canopy_low = 0.75
  tree_top = 3.0
  tree_trunk_r = 1.6

  -- swing state
  swing_mode = "start" -- "ready", "aiming", "powering", "accuracy", "flying", "terrain_pause"
  power = 0.2 -- raw meter value starts at bar_start
  power_max = 1.0
  swing_timer = 0
  power_lock = 0
  accuracy_timer = 0
  accuracy_diff = 0
  accuracy_window = 0.15

  -- bar visuals
  bar_x1 = 20
  bar_x2 = 108
  bar_y1 = 121
  bar_y2 = 126
  bar_start = 0.2 -- visual reference start

  -- club types
  clubs = {
    {name="1w", max_power=1.49, loft=18/360, roll=.90},
    {name="3w", max_power=1.36, loft=20/360, roll=.89},
    {name="3i", max_power=1.19, loft=24/360, roll=.87},
    {name="5i", max_power=1.03, loft=30/360, roll=.84},
    {name="9i", max_power=.85, loft=42/360, roll=.75},
    {name="sw", max_power=.75, loft=54/360, roll=.60},
    {name="p", max_power=1.0, loft=0, roll=.95}
  }

  -- shot shape
  ssh = {
    up = false,
    down = false,
    left = false,
    right = false,
  }


  drag_constant = 0.999
  g = 0.02
  WIND_FORCE = .00078
  CURVE_FORCE = .0085

  for club in all(clubs) do
    club.distance = calculate_club_distance(club)
  end

  hole_number = 1

  -- game setup menu
  game_modes={"stroke","practice"}
  mode_index=1
  game_mode="stroke"
  setup_row=1
  practice_hole=1
  -- practice/range default to fully random wind; speed -1 means random
  practice_wind_speed=-1
  practice_wind_dir=2
  wind_dir_names={"e","ne","n","nw","w","sw","s","se"}
  range_last_distance=0

  -- menu / scorecard music
  music(0)

end

function make_course(s)
  local a = split(s)
  local c = {}
  for i=1,#a,9 do
    add(c,{
      par=a[i],
      tee_x=a[i+1]*8+4,
      tee_y=a[i+2]*8+4,
      hole_x=a[i+3]*8+4,
      hole_y=a[i+4]*8+4,
      bb={x1=a[i+5],y1=a[i+6],x2=a[i+7],y2=a[i+8]},
      score=-1
    })
  end
  return c
end

function safe_dist(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  -- scale down to prevent overflow
  local scale = max(abs(dx), abs(dy))
  if scale == 0 then return 0 end
  dx /= scale
  dy /= scale
  return sqrt(dx^2 + dy^2) * scale
end

function yard_dist(x1,y1,x2,y2)
  return flr(safe_dist(x1,y1,x2,y2)*yards_per_pixel+.5)
end

function calculate_club_distance(club)
  local speed = club.max_power
  local vx = speed * cos(club.loft)
  local vz = speed * abs(sin(club.loft))
  local z = 0
  local distance = 0

  -- Match the real shot integration, without wind or shot shape.
  while z > 0 or abs(vz) > 0 do
    local airspeed = abs(vx)
    if airspeed > 0 then
      local drag_force = (1 - drag_constant) * airspeed^2
      vx -= drag_force
    end

    vz -= g
    distance += vx
    z += vz

    if z <= 0 and vz < 0 then
      z = 0
      vz = 0
    end
  end

  local roll = club.roll or .95
  while abs(vx) >= .01 do
    vx *= roll
    distance += vx
  end

  return distance
end

-- wind
function random_wind()
  wind_angle = rnd(1.0)
  wind_speed = flr(rnd(6))
  return cos(wind_angle) * wind_speed, sin(wind_angle) * wind_speed
end

function reset_ball_and_hole()
  local hole = hole_locations[hole_number]
  ball_x = hole.tee_x
  ball_y = hole.tee_y
  ball_z = 0
  ball_dx = 0
  ball_dy = 0
  ball_dz = 0


  hole_x = hole.hole_x
  hole_y = hole.hole_y

  -- angle from ball to hole
  angle = atan2(hole_x - ball_x, hole_y - ball_y)

  cam_pan_timer = 0
  cam_pan_end_x = hole.tee_x - 64
  cam_pan_end_y = hole.tee_y - 64
  cam_pan_start_x = hole.hole_x - 64
  cam_pan_start_y = hole.hole_y - 64
  penalty_box = 0

  -- score message
  game_message = ""
  game_message_timer = 0

  current_club = 1
  -- shot counter
  shot_count = 0

  swing_mode = "camera_pan"
  shot_terrain = "tee"
  tt = "tee"
  current_club = recommend_club()
  accuracy_window = 0.15

  if game_mode == "stroke" or practice_wind_speed < 0 then
    random_wind()
  else
    wind_speed=practice_wind_speed
    wind_angle=practice_wind_dir/8
  end
  sfx(3)
end

function set_shot_shape()
  ssh.left = btn(0)
  ssh.right = btn(1)
  ssh.up = btn(2)
  ssh.down = btn(3)
end

-- determine terrain from map sprite
function get_terrain(x, y)

  -- check if out of	bounds
  local bb = hole_locations[hole_number].bb
  if x < bb.x1*8 or x > (bb.x2*8) + 8 or y > (bb.y1*8) + 8 or y < bb.y2*8 then
    return "ob"
  end


  local tx = flr(x / 8)
  local ty = flr(y / 8)
  local spr_id = mget(tx, ty)

  -- Rock faces are bunker+flag7 tiles. The whole tile is one
  -- directionless obstacle; art/orientation does not affect physics.
  if fget(spr_id,4) and fget(spr_id,7) then
    return "rock"
  end

  if fget(spr_id, 0) then
    return "tee"
  elseif fget(spr_id, 1) then
    return "fairway"
  elseif fget(spr_id, 2) then
    return "green"
  elseif fget(spr_id, 3) then
    return "rough"
  elseif fget(spr_id, 4) then
    return "bunker"
  elseif fget(spr_id, 5) then
    return "water"
  elseif fget(spr_id, 6) then
    return "tree"
  elseif fget(spr_id, 7) then
    if spr_id == 8 then
      return "right"
    elseif spr_id == 9 then
      return "left"
    elseif spr_id == 10 then
      return "up"
    elseif spr_id == 11 then
      return "down"
    else
      return "ob"
    end
  else
    return "ob"
  end
end


function water_drop_position(x, y)
  local entry_dist = safe_dist(x, y, hole_x, hole_y)
  local best_x = x
  local best_y = y
  local best_score = 9999
  local tx = flr(x / 8)
  local ty = flr(y / 8)
  for r=0,4 do
    for yy=ty-r,ty+r do
      for xx=tx-r,tx+r do
        if abs(xx-tx) == r or abs(yy-ty) == r then
          local px = xx*8+4
          local py = yy*8+4
          local t = get_terrain(px,py)
          if t == "fairway" or t == "rough" or t == "tee" or t == "bunker" then
            local hole_dist = safe_dist(px,py,hole_x,hole_y)
            if hole_dist >= entry_dist - 2 then
              local lie_penalty = t == "bunker" and 20 or (t == "rough" and 2 or 0)
              local score = safe_dist(px,py,x,y) + lie_penalty
              if score < best_score then
                best_score = score
                best_x = px
                best_y = py
              end
            end
          end
        end
      end
    end
    if best_score < 9999 then break end
  end
  return best_x,best_y
end

function slope_on_green(x,y)
  local tx=flr(x/8)
  local ty=flr(y/8)
  for yy=ty-1,ty+1 do
    for xx=tx-1,tx+1 do
      if fget(mget(xx,yy),2) then return true end
    end
  end
  return false
end

function to_ready()
  power = bar_start
  swing_mode = "ready"
end

function recommend_club()
  local terrain = shot_terrain

  -- Green and green-slope tiles should always suggest putter.
  if terrain == "green" or ((terrain == "left" or terrain == "right" or
    terrain == "up" or terrain == "down") and slope_on_green(ball_x,ball_y)) then
    return 7
  end

  -- Driver is only recommended from a tee. It remains manually selectable
  -- elsewhere, but normal lies start with 3w or shorter.
  local first_club = terrain == "tee" and 1 or 2

  -- In a bunker, recommend an iron or wedge rather than a wood.
  if terrain == "bunker" or terrain == "rock" then
    first_club = 4
  end

  local lie_scale = 1
  if terrain == "rough" or terrain == "tree" then
    lie_scale = .9
  elseif terrain == "bunker" or terrain == "rock" then
    lie_scale = .8
  end

  local dist = safe_dist(ball_x, ball_y, hole_x, hole_y)
  local pick = first_club

  -- Choose the shortest allowed club that can still reach at full power.
  -- If none can reach, this leaves us on the longest allowed club.
  for i=6,first_club,-1 do
    if clubs[i].distance * lie_scale >= dist then
      pick = i
      break
    end
  end

  return pick
end


-- plays a single programmatic tone using sfx slot 0
-- pitch: 0-63 (0=c-2, 12=c-3, 24=c-4, etc.)
-- instr: 0-7 (0=sine, 1=triangle, 2=sawtooth, 3=square)
-- vol:   0-7 (0=silent, 7=loudest)
function play_tone(pitch, instr, vol)
  local sfx_id = 16
  local base_addr = 0x3200 + (sfx_id * 68)

  -- set note 0 pitch
  poke(base_addr, pitch)

  -- combine instrument and volume into the second byte
  -- (shifting volume left by 3 bits)
  local instr_vol_byte = instr + (vol * 8)
  poke(base_addr + 1, instr_vol_byte)

  -- change sfx speed (offset 65) to play quickly
  poke(base_addr + 65, 8)

  -- set sfx loop section to only play note 0 (offsets 66 & 67)
  poke(base_addr + 66, 0) -- loop start note
  poke(base_addr + 67, 1) -- loop end note

  -- play the programmatic note on channel 0 for 1 note length
  sfx(sfx_id, -1, 0, 1)
end

function clear_scores()
  for h=1,#hole_locations do
    hole_locations[h].score = -1
  end
end

function start_selected_game()
  music(-1)
  hole_locations=courses[course_number]
  if course_number==3 then
    game_mode="practice"
    mode_index=2
    hole_number=1
  else
    clear_scores()
    hole_number=game_mode=="practice" and practice_hole or 1
  end
  reset_ball_and_hole()
end

function reset_range_shot()
  local h=range_locations[1]
  if practice_wind_speed < 0 then random_wind() end
  ball_x=h.tee_x ball_y=h.tee_y ball_z=0
  ball_dx=0 ball_dy=0 ball_dz=0
  hole_x=h.hole_x hole_y=h.hole_y
  angle=atan2(hole_x-ball_x,hole_y-ball_y)
  shot_count=0 shot_terrain="tee" tt="tee"
  current_club=recommend_club()
  ssh.left=false ssh.right=false ssh.up=false ssh.down=false
  range_last_distance=0
  to_ready()
end

function draw_small_arrow(x, y, dir, col)
  col = col or 7
  if dir < 0 then
    pset(x, y + 2, col)
    line(x + 1, y + 1, x + 1, y + 3, col)
    line(x + 2, y, x + 2, y + 4, col)
  else
    pset(x + 2, y + 2, col)
    line(x + 1, y + 1, x + 1, y + 3, col)
    line(x, y, x, y + 4, col)
  end
end

function _update()

  if swing_mode == "start" then
    if btnp(5) then
      swing_mode = "setup"
      setup_row = 1
    end
    return
  end

  if swing_mode == "setup" then
    local range=course_number==3
    local max_row=2
    if game_mode=="practice" then max_row=range and 4 or 5 end

    if btnp(2) then
      setup_row=max(1,setup_row-1)
    elseif btnp(3) then
      setup_row=min(max_row,setup_row+1)
    end

    if setup_row==1 then
      if btnp(0) then course_number=(course_number-2)%#courses+1
      elseif btnp(1) then course_number=(course_number%#courses)+1 end
      hole_locations=courses[course_number]
      if course_number==3 then
        game_mode="practice"
        mode_index=2
      else
        practice_hole=min(practice_hole,#hole_locations)
      end
    elseif setup_row==2 then
      if not range then
        if btnp(0) then mode_index=(mode_index-2)%#game_modes+1
        elseif btnp(1) then mode_index=(mode_index%#game_modes)+1 end
        game_mode=game_modes[mode_index]
      else
        game_mode="practice"
        mode_index=2
      end
    elseif game_mode=="practice" and not range and setup_row==3 then
      if btnp(0) then practice_hole=(practice_hole-2)%#hole_locations+1
      elseif btnp(1) then practice_hole=(practice_hole%#hole_locations)+1 end
    else
      local speed_row=range and 3 or 4
      local dir_row=speed_row+1
      if setup_row==speed_row then
        if btnp(0) then
          if practice_wind_speed < 0 then practice_wind_speed=5
          elseif practice_wind_speed==0 then practice_wind_speed=-1
          else practice_wind_speed-=1 end
        elseif btnp(1) then
          if practice_wind_speed < 0 then practice_wind_speed=0
          elseif practice_wind_speed==5 then practice_wind_speed=-1
          else practice_wind_speed+=1 end
        end
      elseif setup_row==dir_row and practice_wind_speed >= 0 then
        if btnp(0) then practice_wind_dir=(practice_wind_dir+7)%8
        elseif btnp(1) then practice_wind_dir=(practice_wind_dir+1)%8 end
      end
    end

    if btnp(5) then start_selected_game() end
    return
  end

  penalty_box = 0.2
  bar_start = 0.2

  if shot_terrain == "bunker" or shot_terrain == "rock" then
    if clubs[current_club].name != "5i" and clubs[current_club].name != "9i" and
      clubs[current_club].name != "sw" then
      penalty_box = 0.02 -- Difficult to hit with non-iron/wedge clubs
    else
      penalty_box = 0.05
    end
  elseif shot_terrain == "rough" or shot_terrain == "tree" then
    penalty_box = 0.05
  elseif shot_terrain == "fairway" or shot_terrain == "green" then
    penalty_box = 0.1
  elseif shot_terrain == "tee" then
    penalty_box = 0.15
  else
    penalty_box = 0.1
  end

  -- Additional condition for driver off the tee
  if (clubs[current_club].name == "1w") and (shot_terrain != "tee") then
    penalty_box = 0.01 -- Tiny penalty box for driver off the tee
  end

  if game_message_timer > 0 then
    game_message_timer -= 1
  end

  if swing_mode == "camera_pan" then
    cam_pan_timer += 1
    local t = cam_pan_timer / 90
    if t >= 1 then
      to_ready()
    else
      cam_x = cam_pan_start_x * (1 - t) + cam_pan_end_x * t
      cam_y = cam_pan_start_y * (1 - t) + cam_pan_end_y * t
    end
    return
  end



  if swing_mode == "terrain_pause" then
    if btnp(5) then
      if course_number==3 then
        reset_range_shot()
      else
        to_ready()
        -- aim to the hole
        angle = atan2(hole_x - ball_x, hole_y - ball_y)
      end
    end
    return
  end

  if swing_mode == "aiming" then
    if btnp(5) then
      to_ready()
    end
    if btnp(2) then
      current_club = (current_club - 2) % #clubs + 1

    end
    if btnp(3) then
      current_club = (current_club % #clubs) + 1

    end
    if btn(1) then angle -= 0.0025 end
    if btn(0) then angle += 0.0025 end
    return
  end

  if swing_mode == "ready" then
    if btnp(4) then
      swing_mode = "aiming"
      return
    end
    if btnp(5) then
      accuracy_window = penalty_box
      swing_mode = "powering"
      swing_timer = 0
    end
    if btnp(2) then current_club = (current_club - 2) % #clubs + 1

    end

    if btnp(3) then current_club = (current_club % #clubs) + 1

    end

    if btn(1) then angle -= 0.0025 end
    if btn(0) then angle += 0.0025 end

  elseif swing_mode == "powering" then
    set_shot_shape()
    swing_timer += 0.02
    local phase = swing_timer % 2
    power = phase < 1 and (bar_start + (1.0 - bar_start) * phase)
    or (bar_start + (1.0 - bar_start) * (2 - phase))

    -- if back at beginning, go back to ready
    if swing_timer >= 2 then
      to_ready()
    end

    if btnp(5) then
      power_lock = power
      accuracy_timer = 0
      swing_mode = "accuracy"
    end


  elseif swing_mode == "accuracy" then
    accuracy_timer += 0.02

    power = power_lock - accuracy_timer

    set_shot_shape()


    if btnp(5) then

      local accuracy_diff = abs(bar_start - power)
      local is_duff = accuracy_diff > accuracy_window
      local penalty_ratio = mid(0, accuracy_diff / accuracy_window, 1)
      local offset_angle = (accuracy_diff / 1.0) * 0.6
      local direction = rnd(1) < 0.5 and -1 or 1
      local final_angle = angle + (direction * offset_angle)
      local club = clubs[current_club]

      local power_scale = 1
      if shot_terrain == "rough" or shot_terrain == "tree" then
        power_scale = 0.9
      elseif shot_terrain == "bunker" or shot_terrain == "rock" then
        power_scale = 0.8
      end


      if is_duff then
        final_angle += rnd(1) * 0.2
        power_lock *= 0.5
        game_message = "duffed shot!"
        game_message_timer = 59
      end

      if (accuracy_diff < .02 and power_lock > 0.975) then
        accuracy_diff = 0
        power_lock = 1
        game_message = "nice shot!"
        game_message_timer = 59
      end

      local shot_speed = power_lock * club.max_power * power_scale
      local horizontal_speed = shot_speed * cos(club.loft)

      ball_dx = cos(final_angle) * horizontal_speed
      ball_dy = sin(final_angle) * horizontal_speed
      ball_dz = abs(sin(club.loft)) * shot_speed

      --game_message = "initial_swing: "..abs((club.loft))..","..ball_dx..","..ball_dy..","..ball_dz
      --game_message_timer = 60

      swing_mode = "flying"
      ball_prev_x = ball_x
      ball_prev_y = ball_y
      water_drop_x = ball_x
      water_drop_y = ball_y

      -- Last non-rock position lets a rock hit kick the ball back out.
      rock_clear_x = ball_x
      rock_clear_y = ball_y

      -- A ball starting under a tree/cactus may leave its current tile freely.
      tree_ignore_tx = flr(ball_x/8)
      tree_ignore_ty = flr(ball_y/8)
      tree_ignore_active = shot_terrain == "tree"
      tree_contacted = false

      shot_count += 1

      local s = 0

      if is_duff then
        s = 2
      elseif club.name == "p"	then
        s = 1
      end
      sfx(s)

      first_touch = true
      if club.name == "p" then
        first_touch = false
      end
    end

  elseif swing_mode == "flying" then
    tt = get_terrain(ball_x, ball_y)

    local speed = sqrt(ball_dx^2 + ball_dy^2)

    if ball_z > 0 or abs(ball_dz) > 0 then
      -- Wind is a small continuous acceleration. Higher shots feel it
      -- slightly more, but wedges no longer get trapped by it.
      local wind_force = wind_speed * WIND_FORCE * (.75 + min(max(ball_z, 0), 8) / 16)
      ball_dx += cos(wind_angle) * wind_force
      ball_dy -= sin(wind_angle) * wind_force

      -- Curve perpendicular to the current flight path. Scaling with
      -- speed makes woods bend more than wedges in absolute distance.
      speed = sqrt(ball_dx^2 + ball_dy^2)
      if speed > 0 then
        local nx = ball_dx / speed
        local ny = ball_dy / speed
        local curve_force = CURVE_FORCE * speed

        if ssh.right and not ssh.left then
          ball_dx += ny * curve_force
          ball_dy -= nx * curve_force
        elseif ssh.left and not ssh.right then
          ball_dx -= ny * curve_force
          ball_dy += nx * curve_force
        end
      end

      speed = sqrt(ball_dx^2 + ball_dy^2)
      if speed > 0 then
        local vx = ball_dx / speed
        local vy = ball_dy / speed
        local drag_force = (1 - drag_constant) * speed^2
        ball_dx -= drag_force * vx
        ball_dy -= drag_force * vy
      end


      ball_dz -= g

      play_tone(ball_z + 24, 0, 5)

    else -- Grounded
      ball_z = 0
      ball_dz = 0

      if first_touch then
        --apply shotshape spin
        if ssh.up then
          ball_dx += cos(angle) * .75
          ball_dy += sin(angle) * .75
        end
        if ssh.down then
          ball_dx -= cos(angle) * .9
          ball_dy -= sin(angle) * .9
        end
        first_touch = false
      end


      local slope_const = .015
      if (tt == "left" or tt == "right" or tt == "up" or tt == "down") and not slope_on_green(ball_x,ball_y) then
        slope_const = .024
      end
      local roll_friction = clubs[current_club].roll or .95
      local green_roll_friction = 1 - (1 - roll_friction) * .8
      if speed < .01 then
        slope_const = 0
      end
      if tt == "bunker" then
        ball_dx *= 0.75
        ball_dy *= 0.75
      elseif tt == "rock" then
        ball_dx *= 0.18
        ball_dy *= 0.18
      elseif tt == "rough" or tt == "tree" then
        ball_dx *= 0.8
        ball_dy *= 0.8
      elseif tt == "fairway" or tt == "tee" then
        ball_dx *= roll_friction
        ball_dy *= roll_friction
      elseif tt == "green" then
        ball_dx *= green_roll_friction
        ball_dy *= green_roll_friction
      elseif tt == "left" then
        ball_dx -= slope_const
        ball_dy *= green_roll_friction
        ball_dx *= green_roll_friction
      elseif tt == "right" then
        ball_dx += slope_const
        ball_dy *= green_roll_friction
        ball_dx *= green_roll_friction
      elseif tt == "up" then
        ball_dy -= slope_const
        ball_dx *= green_roll_friction
        ball_dy *= green_roll_friction
      elseif tt == "down" then
        ball_dy += slope_const
        ball_dx *= green_roll_friction
        ball_dy *= green_roll_friction
      end

    end

    local before_x = ball_x
    local before_y = ball_y
    local before_tt = tt
    ball_x += ball_dx
    ball_y += ball_dy
    ball_z += ball_dz

    local after_tt = get_terrain(ball_x,ball_y)

    -- Rock face: one simple collision from every direction. Low shots and
    -- ground roll hit it; sufficiently high shots clear it. Never settle
    -- inside the rock tile.
    if after_tt == "rock" and ball_z < rock_height then
      ball_x = rock_clear_x
      ball_y = rock_clear_y
      if ball_z > 0 then
        ball_dx *= -0.25
        ball_dy *= -0.25
        ball_dz = max(abs(ball_dz)*0.2,0.03)
      else
        ball_dx *= -0.18
        ball_dy *= -0.18
        ball_dz = 0
      end
      game_message = "hit rock!"
      game_message_timer = 30
      after_tt = get_terrain(ball_x,ball_y)
    elseif after_tt != "rock" then
      rock_clear_x = ball_x
      rock_clear_y = ball_y
    end

    -- Trees and cacti share the same behavior. The tree containing the ball
    -- at shot start is harmless until the ball exits that tile. A continuous
    -- tree patch can then affect the shot only once, preventing pinball.
    local tree_tx = flr(ball_x/8)
    local tree_ty = flr(ball_y/8)
    if tree_ignore_active and (tree_tx != tree_ignore_tx or tree_ty != tree_ignore_ty) then
      tree_ignore_active = false
    end
    if after_tt != "tree" then tree_contacted = false end
    local ignore_tree = tree_ignore_active and tree_tx == tree_ignore_tx and tree_ty == tree_ignore_ty

    if after_tt == "tree" and not ignore_tree and not tree_contacted then
      local cx = tree_tx*8+4
      local cy = tree_ty*8+4
      local tdx = ball_x-cx
      local tdy = ball_y-cy
      local td2 = tdx*tdx+tdy*tdy

      -- Small solid trunk/core. A direct hit reflects predictably instead of
      -- using RNG. This also applies to cacti.
      if ball_z < tree_top and td2 < tree_trunk_r*tree_trunk_r then
        if td2 > 0.01 then
          local td = sqrt(td2)
          local nx = tdx/td
          local ny = tdy/td
          local into = ball_dx*nx+ball_dy*ny
          if into < 0 then
            ball_dx = (ball_dx-2*into*nx)*0.35
            ball_dy = (ball_dy-2*into*ny)*0.35
          else
            ball_dx *= -0.35
            ball_dy *= -0.35
          end
          ball_x = cx+nx*(tree_trunk_r+0.2)
          ball_y = cy+ny*(tree_trunk_r+0.2)
        else
          ball_dx *= -0.35
          ball_dy *= -0.35
        end
        ball_dz *= 0.6
        tree_contacted = true
        game_message = "hit tree!"
        game_message_timer = 24

      -- Low shots pass beneath the canopy. Mid-height shots catch branches
      -- once and lose distance; high shots clear the tree completely.
      elseif ball_z >= tree_canopy_low and ball_z < tree_top then
        ball_dx *= 0.55
        ball_dy *= 0.55
        ball_dz *= 0.65
        tree_contacted = true
        game_message = "caught branches!"
        game_message_timer = 24
      end
    end

    if after_tt == "water" and before_tt != "water" then
      water_drop_x = before_x
      water_drop_y = before_y
    end

    if ball_z <= 0 and ball_dz < 0 then
      ball_z = 0
      ball_dz = 0
    end

    if ball_z == 0 and ball_dz == 0 then
      if abs(ball_dx) < .01 then ball_dx = 0 end
      if abs(ball_dy) < .01 then ball_dy = 0 end
    end

    -- Terrain can change during this frame, especially on landing.
    tt = get_terrain(ball_x, ball_y)

    if max_height < ball_z then
      max_height = ball_z
    end

    if ball_z == 0 and (tt == "water" or tt == "ob") then
      if course_number==3 then
        local rt=range_locations[1]
        range_last_distance=yard_dist(rt.tee_x,rt.tee_y,before_x,before_y)
      end
      game_message = "Landed in "..tt.."\n+1 penalty stroke"
      game_message_timer = 60
      shot_count += 1
      ball_dx = 0
      ball_dy = 0
      ball_dz = 0
      if tt == "water" then
        ball_x,ball_y = water_drop_position(water_drop_x,water_drop_y)
      else
        ball_x = ball_prev_x
        ball_y = ball_prev_y
      end
      tt = get_terrain(ball_x, ball_y)
      shot_terrain = tt
      current_club = recommend_club()
      ssh.left = false
      ssh.right = false
      ssh.up = false
      ssh.down = false
      swing_mode = "terrain_pause"
      return
    end

    local dist =	safe_dist(ball_x, ball_y, hole_x, hole_y)
    local current_speed = sqrt(ball_dx^2 + ball_dy^2)
    if course_number!=3 and (ball_z == 0) and (dist < hole_radius + ball_radius_ground * 0.6) then
      if current_speed < 0.2 then
        ball_dx = 0
        ball_dy = 0
        ball_dz = 0
        ball_x = hole_x
        ball_y = hole_y

        swing_mode = "hole_pause"
        pl_h_sfx = 1
        return
      end
    end

    if ball_dx == 0 and ball_dy == 0 and ball_z == 0 and ball_dz == 0 then
      if course_number==3 then
        local rt=range_locations[1]
        range_last_distance=yard_dist(rt.tee_x,rt.tee_y,ball_x,ball_y)
      end
      swing_mode = "terrain_pause"
      ball_dx = 0
      ball_dy = 0
      ball_dz = 0
      ssh.left = false
      ssh.right = false
      ssh.up = false
      ssh.down = false
      tt = get_terrain(ball_x, ball_y)
      shot_terrain = tt
      current_club = recommend_club()
    end

  elseif swing_mode == "hole_pause" then
    hole_locations[hole_number].score = shot_count

    if btnp(5) then
      swing_mode = "scoreboard"
      music(0)
    end

  elseif swing_mode == "scoreboard" then
    if btnp(5) then
      if game_mode == "practice" then
        swing_mode = "setup"
        setup_row = 3
        return
      end

      if hole_number >= #hole_locations then
        swing_mode = "start"
        return
      end

      music(-1)
      hole_number += 1
      reset_ball_and_hole()
    end
  end
end

function popup_print(text, x, y, col)
  local w = #text * 4
  rectfill(x - 2, y - 2, x + w + 2, y + 6, 1)
  print(text, x, y, col or 7)
end

function _draw()
  cls()
  if swing_mode == "start" then
    -- show map
    --
    local map_x = 124
    local map_y = 60
    local tiles_w = 4
    local tiles_h = 4

    local tile_draw_w =  128 / 4 -- 128/16 = 8
    local tile_draw_h =  128 / 4 -- 128/16 = 8

    for my=0, tiles_h-1 do
      for mx=0, tiles_w-1 do
        local tile = 0x4c + mx + my * 16
        local sx = (tile % 16) * 8
        local sy = flr(tile / 16) * 8
        local dx = mx * tile_draw_w
        local dy = my * tile_draw_h

        sspr(sx, sy, 8, 8, dx, dy, tile_draw_w, tile_draw_h)
      end
    end
    print("press ❎ to start", 36, 117, 7)
    return
  end


  if swing_mode == "setup" then
    cls(3)
    print("game setup",46,6,7)
    line(24,15,103,15,11)

    local ys={26,43,60,77,94}
    local range=course_number==3
    local max_row=2
    if game_mode=="practice" then max_row=range and 4 or 5 end
    for r=1,max_row do
      if setup_row==r then rectfill(0,ys[r]-4,127,ys[r]+8,1) spr(67,3,ys[r]-1) end
    end

    -- center values between the left/right arrows
    local vc=94
    local course_text=course_names[course_number]
    print("course",14,ys[1],setup_row==1 and 7 or 6)
    print(course_text,vc-#course_text*2,ys[1],7)
    draw_small_arrow(64,ys[1],-1,setup_row==1 and 10 or 6)
    draw_small_arrow(121,ys[1],1,setup_row==1 and 10 or 6)

    local mode_text=game_mode=="stroke" and "stroke play" or "practice"
    print("mode",14,ys[2],setup_row==2 and 7 or 6)
    print(mode_text,vc-#mode_text*2,ys[2],range and 5 or 7)
    if not range then
      draw_small_arrow(64,ys[2],-1,setup_row==2 and 10 or 6)
      draw_small_arrow(121,ys[2],1,setup_row==2 and 10 or 6)
    end

    if game_mode=="practice" and not range then
      print("start hole",14,ys[3],setup_row==3 and 7 or 6)
      local ph=""..practice_hole
      print(ph,vc-#ph*2,ys[3],7)
      draw_small_arrow(64,ys[3],-1,setup_row==3 and 10 or 6)
      draw_small_arrow(121,ys[3],1,setup_row==3 and 10 or 6)
    end

    if game_mode=="practice" then
      local sr=range and 3 or 4
      local dr=sr+1
      print("wind speed",14,ys[sr],setup_row==sr and 7 or 6)
      local ws=practice_wind_speed<0 and "random" or (""..practice_wind_speed)
      print(ws,vc-#ws*2,ys[sr],7)
      draw_small_arrow(64,ys[sr],-1,setup_row==sr and 10 or 6)
      draw_small_arrow(121,ys[sr],1,setup_row==sr and 10 or 6)
      print("wind dir",14,ys[dr],setup_row==dr and 7 or 6)
      local wd=practice_wind_speed<0 and "random" or wind_dir_names[practice_wind_dir+1]
      print(wd,vc-#wd*2,ys[dr],practice_wind_speed<0 and 5 or 7)
      if practice_wind_speed>=0 then
        draw_small_arrow(64,ys[dr],-1,setup_row==dr and 10 or 6)
        draw_small_arrow(121,ys[dr],1,setup_row==dr and 10 or 6)
      end
    end

    print("⬆️⬇️⬅️➡️ select   ❎ start",18,120,7)
    return
  end

  if swing_mode == "scoreboard" then
    cls(7)
    rectfill(0,0,127,14,3)
    print("scorecard",46,2,7)
    local mode_text=game_mode=="stroke" and "stroke play" or "practice"
    local meta=course_names[course_number].." / "..mode_text
    print(meta,64-#meta*2,9,6)

    local total=0
    local total_par=0
    local course_par=0
    for h=1,#hole_locations do course_par+=hole_locations[h].par end

    for nine=0,1 do
      local y0=19+nine*40
      rect(1,y0,127,y0+35,5)
      line(10,y0,10,y0+35,5)
      for c=1,8 do line(10+c*13,y0,10+c*13,y0+35,6) end
      for r=1,3 do line(1,y0+r*9,127,y0+r*9,6) end
      print("h",4,y0+2,1)
      print("p",4,y0+11,1)
      print("yd",2,y0+20,1)
      print("s",4,y0+29,1)

      for c=0,8 do
        local h=nine*9+c+1
        local hole=hole_locations[h]
        local cx=16+c*13
        local yds=yard_dist(hole.tee_x,hole.tee_y,hole.hole_x,hole.hole_y)
        local hs=""..h print(hs,cx-#hs*2+(#hs>1 and 1 or 0),y0+2,1)
        local ps=""..hole.par print(ps,cx-#ps*2+(#ps>1 and 1 or 0),y0+11,1)
        local ys=""..yds print(ys,cx-#ys*2+(#ys>1 and 1 or 0),y0+20,5)
        local ss="-"
        if hole.score!=-1 then
          ss=""..hole.score
          total+=hole.score total_par+=hole.par
          local d=hole.score-hole.par
          if d<0 then circ(cx,y0+31,4,3) elseif d>0 then rect(cx-4,y0+27,cx+4,y0+35,8) end
        end
        print(ss,cx-#ss*2+(#ss>1 and 1 or 0),y0+29,1)
      end
    end

    local diff=total-total_par
    local ds=diff>0 and "+"..diff or ""..diff
    print("par "..course_par,4,101,5)
    print("score "..total,38,101,1)
    print("+/-:",80,101,5)
    print(ds,122-#ds*4,101,diff<0 and 3 or (diff>0 and 8 or 1))
    if game_mode=="practice" then
      print("practice / ❎ setup",28,117,5)
    elseif hole_number>=#hole_locations then
      print("round complete / ❎ title",20,117,5)
    else
      print("❎ next hole",42,117,5)
    end
    return
  end

  --map(flr(cam_x / 8), flr(cam_y / 8), 0, 0, 128, 32)
  camera(cam_x, cam_y)

  bb = hole_locations[hole_number].bb

  camera(0, 0)
  for x=-7, 132, 8 do
    for y=-7, 132, 8 do
      spr(12, x - cam_x%8, y - cam_y%8)
    end
  end

  --camera(cam_x, cam_y)

  --map(0, 0)
  camera(0, 0)

  local cell_x = (cam_x / 8)
  local cell_y	= (cam_y / 8)
  local sx = 0-cam_x%8
  local sy = 0-cam_y%8
  local w = 32
  local h = 32
  --print("sx: "..sx..",w"..w.."", 0, 80, 7)

  -- only print if within map
  if bb.x1 > cell_x 	then
    sx -= (cell_x -	bb.x1 ) * 8 - cam_x%8
    cell_x = bb.x1
    w -= ( bb.x1 - cell_x)
  end

  if bb.x2 < (cell_x + w) then
    w -= cell_x + w - bb.x2 - 1 - (cam_x%8/8)
  end

  if bb.y2 > cell_y 	then
    sy -= (cell_y - bb.y2) *8 - cam_y%8
    cell_y = bb.y2
    h -= (bb.y2 - cell_y)
  end

  if bb.y1 < (cell_y + h) then
    h -= cell_y + h - bb.y1 - 1 - (cam_y%8/8)
  end

  map(cell_x, cell_y, sx, sy, w, h)

  local club = clubs[current_club]
  local distance = club.distance
  local aim_x = ball_x + cos(angle) * distance
  local aim_y = ball_y + sin(angle) * distance

  if swing_mode == "ready" then
    local cx = ball_x
    local cy = ball_y
    cam_x = cx - 64
    cam_y = cy - 64
    camera(cam_x, cam_y)
  elseif swing_mode == "camera_pan" then
    camera(cam_x, cam_y)
  elseif swing_mode == "aiming" then
    cam_x = aim_x - 64
    cam_y = aim_y - 64
    camera(cam_x, cam_y)
  else
    cam_x = ball_x - 64
    cam_y = ball_y - 64
    camera(cam_x, cam_y)
  end


  camera(cam_x, cam_y)
  -- draw holes / range targets
  if course_number==3 then
    local rt=range_locations[1]
    for t in all(range_targets) do
      circfill(t.x,t.y,hole_radius,1)
      spr(67,t.x-1,t.y-8)
      local yd=yard_dist(rt.tee_x,rt.tee_y,t.x,t.y).."y"
      print(yd,t.x-#yd*2,t.y+5,7)
    end
  else
    circfill(hole_x,hole_y,hole_radius,1)
    if safe_dist(ball_x,ball_y,hole_x,hole_y)>16 and shot_terrain!="green" then
      spr(67,hole_x-1,hole_y-8)
    end
  end

  -- draw ball
  local radius = ball_z > 0 and ball_radius_air or ball_radius_ground
  circfill(ball_x, ball_y, radius, 7)

  if swing_mode == "aiming" or swing_mode == "powering" or swing_mode == "accuracy" or swing_mode == "ready" then
    line(ball_x, ball_y, aim_x, aim_y, 10)
    line(aim_x - 1, aim_y, aim_x + 1, aim_y, 10)
    line(aim_x, aim_y - 1, aim_x, aim_y + 1, 10)
  end

  -- distance remaining (drawn with the top-left hole hud below)
  camera()
  local rem=yard_dist(ball_x,ball_y,hole_x,hole_y).."y"

  -- wind
  local cx, cy = 122, 8
  circfill(cx, cy, 4, 1)

  if wind_speed > 	0 then
    line(cx, cy, cx + cos(wind_angle)*5, cy - sin(wind_angle)*5 , 7)
  end
  print(""..wind_speed.."", cx -1  , cy +6, 7)
  --print(""..cos(wind_angle).."\n"..sin(wind_angle).."", cx - 20  , cy +13, 7)


  camera()

  -- permanent bottom hud
  -- one dark instrument-panel base; color is reserved for useful state
  rectfill(0, 110, 127, 127, 1)

  -- club section: muted dark green, terrain fills the opposite end
  rectfill(0, 111, 17, 127, 3)
  line(0, 110, 127, 110, 5)
  line(18, 110, 18, 127, 5)
  line(109, 110, 109, 127, 5)

  -- power meter: subdued track, warm fill, red accuracy target
  rectfill(bar_x1, bar_y1, bar_x2, bar_y2, 0)
  rectfill(bar_x1 + 1, bar_y1 + 1, bar_x2 - 1, bar_y2 - 1, 5)

  local w = (bar_x2 - bar_x1 - 2)

  -- orange means power only: live while powering, frozen once locked
  local meter_power = 0
  if swing_mode == "powering" then
    meter_power = power
  elseif swing_mode == "accuracy" or swing_mode == "flying" then
    meter_power = power_lock
  end

  if meter_power > 0 then
    local fill_x = bar_x2 - 1 - mid(0, meter_power, 1) * w
    rectfill(fill_x, bar_y1 + 1, bar_x2 - 1, bar_y2 - 1, 9)
  end

  local display_penalty_box = penalty_box
  if swing_mode == "powering" or swing_mode == "accuracy" or swing_mode == "flying" then
    display_penalty_box = accuracy_window
  end
  local x1 = bar_x2 - 1 - mid(0, bar_start + display_penalty_box, 1) * w
  local x2 = bar_x2 - 1 - mid(0, bar_start - display_penalty_box, 1) * w
  rectfill(x1, bar_y1 + 1, x2, bar_y2 - 1, 8)

  -- neutral minimum-power tick
  local start_x = bar_x2 - 1 - bar_start * w
  line(start_x, bar_y1 + 1, start_x, bar_y2 - 1, 6)

  -- white is always the live cursor
  if swing_mode == "powering" or swing_mode == "accuracy" then
    local marker_x = bar_x2 - 1 - mid(0, power, 1) * w
    line(marker_x, bar_y1, marker_x, bar_y2, 7)
  end

  if swing_mode == "accuracy" or swing_mode == "flying" then
    -- locked power is gold so it stays distinct from the live cursor
    local power_lock_x = bar_x2 - 1 - mid(0, power_lock, 1) * w
    line(power_lock_x, bar_y1 + 1, power_lock_x, bar_y2 - 1, 10)
  end


  -- green inset
  if swing_mode == "flying" or swing_mode == "hole_pause" or terrain_pause then
    local dist = safe_dist(ball_x, ball_y, hole_x, hole_y)


    -- Draw green box if on green and within distance

    if (ball_z == 0) and (dist < 4) then
      local scale = 8
      local screen_cx = 64
      local screen_cy = 64
      local box_size = 8*scale  -- size of green box (smaller than screen)

      local box_left = screen_cx - box_size / 2
      local box_top = screen_cy - box_size / 2
      local box_right = screen_cx + box_size / 2
      local box_bottom = screen_cy + box_size / 2

      -- Draw border
      rectfill(box_left - 2, box_top - 2, box_right + 2, box_bottom + 2, 1)

      -- Draw current green sprite on top of box
      local spr_id = mget(flr(hole_x / 8), flr(hole_y / 8))
      -- sspr( sx, sy, sw, sh, dx, dy, [dw,] [dh,] [flip_x,] [flip_y] )
      sspr(spr_id % 16 * 8, flr(spr_id / 16) * 8, 8, 8, box_left + 2, box_top + 2, box_size - 4, box_size - 4)

      -- Draw inner green area
      --rectfill(box_left, box_top, box_right, box_bottom, 11) -- light green

      -- Draw enlarged hole at center
      circfill(screen_cx, screen_cy, hole_radius * scale, 1)

      -- Offset the ball relative to the hole
      local dx = (ball_x - hole_x) * scale
      local dy = (ball_y - hole_y) * scale

      if swing_mode == "hole_pause" then
        scale *= .8
      end

      -- Draw the ball relative to the hole's center
      circfill(screen_cx + dx, screen_cy + dy, ball_radius_ground * scale, 7)
    end
  end



  local hud_text = ""
  if game_message_timer > 0 and (game_message == "nice shot!" or game_message == "duffed shot!") then
    hud_text = game_message
  elseif swing_mode == "powering" then
    hud_text = "power  ❎"
  elseif swing_mode == "accuracy" then
    hud_text = "accuracy  ❎"
  elseif swing_mode == "ready" then
    hud_text = "press ❎ to swing"
  elseif swing_mode == "aiming" then
    hud_text = "❎ done aiming"
  elseif swing_mode == "terrain_pause" or swing_mode == "hole_pause" then
    hud_text = "❎ continue"
  end

  if hud_text != "" then
    print(hud_text, 64-#hud_text*2, 112, 7)
  end

  if swing_mode == "terrain_pause" then
    if course_number==3 then
      local rs="shot "..r
