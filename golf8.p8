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
      local rs="shot "..range_last_distance.."y"
      popup_print(rs,64-#rs*2,60,7)
    else
      popup_print(tt,64-#tt*2,60,7)
    end
  elseif swing_mode == "hole_pause" then
    local par = hole_locations[hole_number].par


    s = ""

    if shot_count == 1 then
      s = "hole in one!"
    elseif shot_count - par == -3 then
      s = "albatross!"
    elseif shot_count - par == -2 then
      s = "eagle!"
    elseif shot_count - par == -1 then
      s = "birdie!"
    elseif shot_count - par == 0 then
      s = "par!"
    elseif shot_count - par == 1 then
      s = "bogey"
    elseif shot_count - par == 2 then
      s = "double bogey"
    elseif shot_count - par == 3 then
      s = "triple bogey"
    else
      s="+"..shot_count-par
    end

    popup_print(s, 64-#s*2, 23, 7)

    if pl_h_sfx == 1 then

      score_sfx = 4

      if shot_count - par > 0 then
        score_sfx = 2
      end

      sfx(score_sfx)
      pl_h_sfx = 0
    end
  end


  if course_number==3 then
    print("range",1,1,7)
    print("target "..rem,1,9,7)
  else
    spr(67,1,1)
    print(hole_number,9,1,7)
    print("par"..hole_locations[hole_number].par,1,9,7)
    print("shot "..shot_count,1,17,7)
    print("dist "..rem,1,25,7)
  end


  --- terrain
  --- get map sprite
  local tx = flr(ball_x / 8)
  local ty = flr(ball_y / 8)
  local spr_id = mget(tx, ty)

  -- terrain fills its full hud segment with no inset border
  sspr(spr_id % 16 * 8, flr(spr_id / 16) * 8, 8, 8, 110, 111, 18, 17)
  -- put image of ball on tile
  circfill(119, 119, 4, 7)

  if club.name != "p" then
    -- put dot indicating shot shape
    dotx = 119
    doty = 119

    if ssh.left then
      dotx -= 2
    end
    if ssh.right then
      dotx += 2
    end

    if ssh.up then
      doty -= 2
    end

    if ssh.down then
      doty += 2
    end

    circfill(dotx, doty, 1, 8)
  end

  if swing_mode == "camera_pan" then
    popup_print("hole "..hole_number.."", 58, 64, 7)
  end

  -- club section: sprite upper-left, label lower-right
  local club_sprite = 66
  if current_club <= 2 then
    club_sprite = 64
  elseif current_club <= 6 then
    club_sprite = 65
  end

  spr(club_sprite, 1, 112)

  local club_label = clubs[current_club].name
  print(club_label, 17 - #club_label * 4, 121, 7)

  if game_message_timer > 0 then
    if game_message == "Landed in water\n+1 penalty stroke" or game_message == "Landed in ob\n+1 penalty stroke" then
      local line1 = game_message == "Landed in water\n+1 penalty stroke" and "Landed in water" or "Landed in ob"
      local line2 = "+1 penalty stroke"
      popup_print(line1, 64-#line1*2, 97, 7)
      popup_print(line2, 64-#line2*2, 104, 7)
    elseif game_message != "nice shot!" and game_message != "duffed shot!" then
      popup_print(game_message, 64-#game_message*2, 100, 7)
    end
  end
end

__gfx__
000000003bbbbbb33bb33bb3bbbbbbbb33333333ffffffffcccccccc33333333b3bb33bbbb33bb3bbb3333bbbbb33bbb50050055ffffffff0000000000000000
00000000bbbbbbbbbb33bb33bbbbbbbb33333333ffffffffcccccccc33399343b33bb33bb33bb33bb33bb33b33bbbb3355000550fffbffff0000000000000000
00700700bbbbbbbbb33bb43bbbbbbbbb33343333ffffffffcccc35cc43999933bb33bb3333bb33bb33bbbb33b33bb33b05505500fbfbffff0000000000000000
00077000bcbbbbcb33bb34bbbbbbbbbb334b3333ffff4fffcccc33ac338888333bb33bb33bb33bb33bb33bb3bb3333bb00555005fbfbffbf0000000000000000
00077000bbbbbbbb3bb43bb3bbbbbbbb33333333fff5ffffc76667cc399999933bb33bb33bb33bb3bb3333bb3bb33bb350055500f3bbffbf0000000000000000
00700700bbbbbbbbbb34bb33bbbbbbbb33333333ff4fffffcc5554cc38888883bb33bb3333bb33bbb33bb33b33bbbb3300550550fffbb3bf0000000000000000
00000000bbbbbbbbb33bb33bbbbbbbbb33333333ffffffffcccccccc33344333b33bb33bb33bb33b33bbbb33b33bb33b05500055fffbffff0000000000000000
000000003bbbbbb333bb33bbbbbbbbbb33333333ffffffffcccccccc34333343b3bb33bbbb33bb3bbbb33bbbbb3333bb55005005ffffffff0000000000000000
4b535b543543345335433b5433b3bb3b3bb3b33b333bb3333fbf33fb3f4ffb3ff44ff4ff5c31c35c3b1c4c3431c6343133343b3443343b4343b3343b99944444
bb33b5334b33bb33bb33bb34bb3bbbbbb3bb3bbbbbb3bbbbfffffffffffffffffffffff3c1c13cccc1cccc1ccccc1ccc433333333b33333b33333b3399444444
533bb33bb33bb33bb33bb3343bbbbbbbbbbbbbbbbbbbbbb33fffffffffffffffffffffffc4cccccc7cccccccccccccc1b4333333333333333333333494444444
33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbbb3bbffffffffffffffffffffffbdcccccccccccccc7ccccccc643333333333333333333333344444449
3bb33bb33bb33bb33bb33bbbb3bbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff4ccccccccccccccccccccccc33333333333333b333333333444444499
bb33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbb3b3fffffffffffffffffffffffbcccccccccccccccccc71ccbb3333333333b3333333333334444499f
433bb33bb33bb33bb33bb3353bbbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff3dcccccccccccccccccccccc13333b33333333333333333b3444999ff
33bb33bb33bb33bb33bb33b43bbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffff441cccccccccccc17cccccc13b33333333333333333333334499fffff
5bb33bb33bb33bb33bb33bb53bbbbbbbbbbbbbbbbbbbbbb33fffffffffffffffffffffff5cccccccccccccccccccccc6433333333333333333333333ff9949ff
5b33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff46cccccc7ccccccccccccccc3333333333333333333333334f994449f
bb3bb33bb33bb33bb33bb33433bbbbbbbbbbbbbbbbbbbbb3bffffffffffffffffffffffb3cccccc1cccccccccccccc1c3433333333333333333333b399444449
33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffff4c4ccccccccccccccccccccc1b3333333333333333333333394444449
5bb33bb33bb33bb33bb33bb5b3bbbbbbbbbbbbbbbbbbbb3b3fffffffffffffffffffffff1ccccccccccccccccc6ccccb33333333333333333333333b94444449
5b33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffb53ccccccccccccccccccccc1b3333333333b33333333333399444449
b33bb33bb33bb33bb33bb335bbbbbbbbbbbbbbbbbbbbbbb34fffffffffffffffffffffff61cccccccccccccccccc1ccc33333b333b33333333333334f994449f
43bb33bb33bb33bb33bb33b43bbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffff34cccccccccccccccccccccc3433333333333333333333333ff9949ff
4bb33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbb34ffffffffffffffffffffff33cccccccccccccccccccccc433333333333333333b333333ffffffff
5b33bb33bb33bb33bb33bb35b3bbbbbbbbbbbbbbbbbbbb3bbfffffffffffffffffffffff5cccccccccccccc6cccccc1cb3333333333333333333333399944499
433bb33bb33bb33bb33bb33b3bbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffff431cccccccccccccccc7cccc143333333333333333333333b94444449
33bb33bb33bb33bb33bb33bb3bbbbbbbbbbbbbbbbbbbbbb34ffffffffffffffffffffff31ccccccccccccccccccccccc33b33333333333333333333494444449
3bb33bb33bb33bb33bb33bb4b3bbbbbbbbbbbbbbbbbbbb3bffffffffffffffffffffffff4cccccccccccccccccccccc63b333333333333333333333394444449
bb33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffffbc1c71cccccccccccccccccc443333333333333333333333394444449
433bb33bb33bb33bb33bb334b3bbbbbbbbbb3bbbbbbb3bbbfffffffffffffffffff34fff57cccccccccc4cc6ccccccc63333333b3b3333333b33343399944499
54b4334553b433b4345b35bb33b3333b3bb3bb333b3b33333f3fb33343ffb3f33f3433b43135117417315c151c13b513b3b34b4b43b34b3bb33433b4ffffffff
000000d50000000500000550070000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbb
000000550000005500000550068800000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbb89bbb8b
000005500000005000000550068888000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9
0000060000000d0000000dd0068888800000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bb
0550d6000000600000000600068888000000000000000000000000000000000000000000000000000000000000000000bbb55555bb7777bbb55bbbbb56888bb9
55556000776d600000000600068800000000000000000000000000000000000000000000000000000000000000000000bbb55555b777777bb55bbbbb57888bbb
d66dd0007666000055555600060000000000000000000000000000000000000000000000000000000000000000000000bbb55bbbb777777bb55bbbbb57bbbbbb
5dd500005665000057775000060000000000000000000000000000000000000000000000000000000000000000000000bbb55bbbb777777bb55bbbbb57555bbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb55b55b667777bb55bbbbb57555bbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb55555b666777bb55555bb57bbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb55555bb6667bbb55555bb57bbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb5555bbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb577775bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb57733775bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb57333375bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb57333375bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb573375bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb577775bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb573375bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb57333375bbbbbbbbbccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb57333375bbbbbbcccccc
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbbbbbbbbbb57733775bbbbbccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033bbbbbbbbbbb577775bbbbccccccccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f33bbbbbbbbbbb5555bbbbcccccccccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff33bbbbbbbbbbbbbbbbbbcccccc35cc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff33bbbbbbbbbbbbbbbbccccccc33ac
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff33bbbbbbbbbbbbbbbcccc76667cc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff33bbbbbbbbbbbbbcccccc5554cc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff33bbbbbbbbbbbbcccccccccccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff3bbbbbbbbbbbbcccccccccccc
63830212217070a2a2a2b24040a0a0a0a0a0c1e140a2a2a2a2a24040d240d240d21111111162c3814091a1b140d2d212121212801212d26383d2c0c0c0c0c0c0
c2e1f2727273738392a3a2b262727272727272824003122362725072727272728232415193b262727373737372727250727282f3f3f3f3f3f3f3f18093a2a2a2
c2d203121221d2a2a2a2b24040903030308040e240a2a2a2a2a212d2403151704002121212637383409260b240d2d21212121323a0a0d2d2d2d2c0c0c0c0c0c0
71d3f2508301118061f293b362727272727373727181134062727272727272507281904252a26282400220806250727272728291a1a1a1b1b0b0b0807372d0b3
c240c1e21313d292a2a2b24040904242428070e240a2a2a2a29012129032425140021212121240704092a2b24010d2d2d2d2d270d270d270d2d2c0c0c0c0c0c0
f3f3f1824003234062f25050737372508391b163727250507372727272507373738233a071a2627271811040627272727272829260a2a2b3625072d0112162d0
c2d2d2d2d1d1d2a2a260b2404090b012b080c2e24040a260a29012124033435340031313122240409170e3b340d2d2d2d2d2d2d2d2d2d2d2d2d2c0c0c0c0c0c0
627272727171717172f2727291b1638391a3a3b1638391a1b1637373738391a1b16350508360637373735050d073727250738392a2a2b2902172728203e17272
c34040c3d210d293a3a3b240e29090128080c2e24040a2a2a29012717040b040707040d2d223404093a3b34040c14040404040404040404040c0c0c0c0c0c0c0
62737373f3f3f3f373f3f3b093a3a1a1b3628293a1a1a3a3a2a1a2a1a1a2a3a3a3a1a1a1a1a2a1a1a1b23141415162728291a1a2a2a2b3d0c372d07271715082
707070707070707070707040e29090128080c2e2404040a2a2a212638312121240707010404040407040704040d2d2d270e341415161d2d2e2c0c0c0c0c0c0c0
7290112290b0b0b0118040d0728293b371c2e17193b3618192a3a3a2b39011227193a3a2a2a3a2a2b23142b0428063f3f392a2a2a2b261727272727373737282
a1a1a1a1a1a1a1a1a1a14040e29090128080c2704040404040a2a212b0b0b0d240707070704040704040404040d240d2813242425262d2d2e2c0c0c0c0c0c0c0
d00323406271714003236172d0d073507382d36271717282a2d0d0718140134062718192b2729260a2b29043435391a2a1a2a2a2a2b262725082400220806282
91a2a2a260a2a3a2c1704040e29090128080c2e2704040121240a240a2a2a2a2a2c170d1d170d1d14040704070404063833343435363d2d2e2c0c0c0c0c0c0c0
d0727181c2e2627171717373727202112140615072727282a2d072727271717172508293b27292a2b26281012191a3a3a3a2a2a2a2b362727272718110406282
92a2b26181b3b09360a24040e29090128080c2e270404010121240a2a2a2a2a2a2c24040401212123141415140404040a2a21212a2a2c340e2c0c0c0c0c0c0c0
72727373507172727282c2e2628240031380627272737382a26272d0d07272507273f3f392a1a2a2a2a1b20222505072d093a3a3b36172727272725071717282
92a2b26231b0517093a2b140e29090128080c2e27040404040404040404040a2a2c201211212123142424252704040a2a2a2a2a2a2a2a2c3e2c0c0c0c0c0c0c0
62f301214062727250727171738391b1625072728391b173a26272f3f25072728202118093a2a3a3a3b361032323c37272717171717272727250727272727282
92a2b2623353d30121e2b240e2b0b0b0b0b0c2e27070707070404040404040a2a20112121212703342424252404040a2c1d1d10121e1a2a2e2c0c0c0c0c0c0c0
50b00313226250727272728291a1a3a3a1b1728391a3a3a1b26272507272d0728240032371606171717172724001217250727272727272507272737373735082
9360b26373737302127092a2a2a2a2a2a2a2a2a2617171837070d2404070407070021212121212e133434352e2a2a2a2c270121212c3e1a2e2c0c0c0c0c0c0c0
63507171717272727272727293b3618193a3a2a1b3628293b3627272727272725071717183a26250f372d072d202227272727272727272727282324141516382
d193a3a3a3a3022012c292a2a2a2a2a3a1a3a3a1728331415180d24040d2404070021212401212c3e3111153e2a2a2a2c20212122012e3a2e2c0c0c0c0c0c0c0
c2e2627273737372d0d0d0d072507373508193b371c2e26171727373737250d07272728291b26272727272725073737373727250f291b1d07272813242905250
c2d1d1d10213121223c39260a2b34040d24093a26331428052804040404040707002121240d270638202202240a2a2a2c2022012121221a2e2c0c0c0c0c0c0c0
61717282021122627272727282022080406271717271717272829011226272727272728292b262f372d050728240902022627272d09260b1807283a042536283
c27070401040d2707070e1a3b34010404040d2a27033b0425280d240d2d2d24070021212d270c0c082a0a0d2a2a2e1a2c3031212121222a2e2c0c0c0c0c0c0c0
6272728240134062727272725081106171727250727272727282032340627272d0f3728293b26272507272d07271811040627272f293a3b3f282324353b0a1b1
70707070707070707070c240d1d1d1d3d1d1e1a2b1403343538040d2a0a0a0e27002121270c0c0c082a0a08092c140a2a2c3e3a2a2122240e2c0c0c0c0c0c0c0
6272725081106172727250727272717272507272727272725072717171727250f27272728192627272727272725072717172727272b0b0f3f150a0718292a2b3
70d2d2d2d1d2d1d270b2c26181d3d3d3d3d3e292a2b0b0b0b0b04040111111e27002121270c0c0c06373838092c2d2e1a2a2a2a2e1032340e2c0c0c0c0c0c0c0
63737373737172725072727272727373737372727272507272727272725073737372727282b2d2d2d240d2d2d2d2d240d2d2d27272727273737372d092a2b250
c34061834141b040e2b2c283314141415170e2a2a2c3407070708140022022407002121270c0c0c070a0a08092c2d2d240d240d2d24040d240c0c0c0c0c0c0c0
91a1a1a1b2f3f3f3f3f3f3f3728231414151d0725072727272727250728202118062507291a2d2314151111111111121d2d2d27272728290112163738292d0b2
b1c3639043804353e2b2c2e2424242424251e292a2a2b26171814070132022e27002121270c0c0c070a0a08092c2d240d2d240d2404010d240c0c0c0c0c0c0c0
9260a2b33141516272727250728233903080526272727272725072727282401340627272a2a2d2324252618380121222d240d272725082e103234091a1b26281
92b1c3d3d3d36383d3b2c2e2334343434353e2a2a2a2b26373707070b01322407002121270c0c0c070a0a08092c24070404070404070d240e3c0c0c0c0c0c0c0
92a2b231424290627250727273f3f333a05361f373737350727272727272811061727272a2a2403343531212f3f3f122d2d2d272727272718191a1a2a3b36282
9260a1a3a1a3a1a3a3b2c2e2b0b0b0b0b0b0e292a2a2b24013131370d2b023e27002121270c0c0c070a0a091a24040d3e341414140404040c0c0c0c0c0c0c0c0
92a2b233a05261507272728291a1a1a1a1a1a1a1a1a1b163727373725072727172727291a2a2d240d202e1121220122270d2d2d0d07272738392a3b362715083
92a2b2d1d1d1a0a0e3b270e2b0b0b0b0b0b0e392a2a2a2c3b0b0b0d3d3d3b0407002121270c0c0c0701291a2a2d2e270614242428170d240c0c0c0c0c0c0c0c0
92a2a2b1335362d07373728292a2a2a2a3a3a3a2a2a2a2b17391b1627291a1a1a2a2a1a2a3b3d240d202121231415122d240407272738391a1b20211806382d0
92a2a2618101202181b2c2e2b0b0b0b0b0b040a2a2a2a2a290b0b0b0b0b080407002121270c0c0c0701292a2a240e2b16342a04283b140e2c0c0c0c0c0c0c0c0
92a2a2a2b2d082012140628292a2a2b202118092a2f3a2a2a1a2a2a1a1a2a2b38341f3414151d2d291b1125032425261d2d2d2738391a1a2a2b3400323c16281
92a2b2638302226282b2c24001111111216183a2a260a2b290011220122180d27002121270c0c0c0702092a2a24070a2b112a012a2a270e2c0c0c0c0c0c0c0c0
92a2a2b2617282031380727292a260b240134092a2a2a260a2a2a2a2b361323042424242305240d2e102121133435322d2d2d291a1a2a3a3b361717171f37282
92a2b3707002136283b2c2400220121261837092a2a2a2a290032013202380e27002121270c0c0c0407272a2a2c2a2a2a212a012a260b1e2c0c0c0c0c0c0c0c0
92a2a2b3f3f3f3f3b0b0f3f392a2a2a2a1a1a1a3a3a3a2a2a3a2a2b3628233a0a0a0b0b0b053d2d2d2d01212121212c1d240d293a3b362717172727272725082
92b2c1e312126383e1b2c24002121212627070a2a2a2a2a290b0b0b0b0b080e2700212124070c0c0402020a2a2c2a260a212a012a2a2a2e2c0c0c0c0c0c0c0c0
92a2b261b0b0b0b09011b0b093a2a2a2a2a2b290112192b2d092b26172728133434343435361d231415112121212122272d2d2819011216372727272d0727282
92b2c303121290c1e2b2c240021220126383e292a260a2b211111111111111d2700212121270c070401212e1a2c2a2a2a212a012a2a260e2c0c0c0c0c0c0c0c0
92a2b26372727282e10323728193a2a2a2a2b240032392a2a1a3b36272725071717171717150d2324252720312121222d2d2d2824003234062725072d0d07282
a3a2a1c2031290c2e2b2c240031212121221e2a2a2a2a2a202121213131323e2700212121212c070401212e2a2c260a2a212a012a2a2a2e2c0c0c0c0c0c0c0c0
92a260b2627272507181c162728193a3a3a3a3a1a3a1a3a3b361717273737372727272507272d233435312d202121222d2d2d272717150507372727272727282
70b3d1d2d2d2d24070b270404002131312237093a2a2a2a2c2132240d3d3d3e37002121212124040011223e2a2c2a2a2a212a012a2a2a2e2c0c0c0c0c0c0c0c0
93a3b36172507273737350725072717171717150505050717172508302118062725072727272d2d2d203131313137070d240d272728202118062727272507282
7070c3d2d2d2d2d270b270704023d2d2d27070704040e1a2c3d3d3e3a2a2a2a270e21212121240401212c1e3a2c2a2a2b340a040a2a2b3e2c0c0c0c0c0c0c0c0
617171507272820220224062727272727250824002208062507282e3e1032362727272727272d240d2d2d3d3d3d3d3d2d2d2d272508240134062725072727282
707070c310d3d37070b2707070c310d370707070104040a2a2a2a2a2a2c1d1e170e21212124010a2a2c3e3a2a2c240b34040104040b34040c0c0c0c0c0c0c0c0
625072727272728110617172727272507272727181104062727272812010c162727272725072d2d240e21020102010c240d2d272727281106150727272727282
70707070d2d2707070b270707070707070707070704040d1d1e1a2a2c3d3d3d370404040404040a2a2a2a2a2a240404040d2d2d240404040c0c0c0c0c0c0c0c0
6373737373737373507373737373737373737373735050737373737350505073737373737373d2d2d2e22012201220c2d2d2d273737373507373737373737383
__label__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88889999bbbbbbbbbbbb8888bbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88889999bbbbbbbbbbbb8888bbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88889999bbbbbbbbbbbb8888bbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88889999bbbbbbbbbbbb8888bbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9999
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8888bbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbbbbbb7777777777777777bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55556666888888888888bbbbbbbb9999
bbbbbbbbbbbb55555555555555555555bbbbbbbb7777777777777777bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55556666888888888888bbbbbbbb9999
bbbbbbbbbbbb55555555555555555555bbbbbbbb7777777777777777bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55556666888888888888bbbbbbbb9999
bbbbbbbbbbbb55555555555555555555bbbbbbbb7777777777777777bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55556666888888888888bbbbbbbb9999
bbbbbbbbbbbb55555555555555555555bbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777888888888888bbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777888888888888bbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777888888888888bbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777888888888888bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbbbbbbbbbbbbbb777777777777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbb55555555bbbb666666667777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbb55555555bbbb666666667777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbb55555555bbbb666666667777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555bbbb55555555bbbb666666667777777777777777bbbbbbbb55555555bbbbbbbbbbbbbbbbbbbb55557777555555555555bbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb666666666666777777777777bbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb666666666666777777777777bbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb666666666666777777777777bbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbb666666666666777777777777bbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbbbbbb6666666666667777bbbbbbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbbbbbb6666666666667777bbbbbbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbbbbbb6666666666667777bbbbbbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbb55555555555555555555bbbbbbbb6666666666667777bbbbbbbbbbbb55555555555555555555bbbbbbbb55557777bbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577773333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777333333333333333377775555bbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55557777777733333333777777775555bbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555577777777777777775555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccc
ffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555bbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc33335555cccccccc
ffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc33335555cccccccc
ffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc33335555cccccccc
ffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc33335555cccccccc
ffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc33333333aaaacccc
ffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc33333333aaaacccc
ffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc33333333aaaacccc
ffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccc33333333aaaacccc
ffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc77776666666666667777cccccccc
ffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc77776666666666667777cccccccc
ffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc77776666666666667777cccccccc
ffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc77776666666666667777cccccccc
ffffffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccc5555555555554444cccccccc
ffffffffffffffffffff33333333bbbbbbbb777b777b777bb77bb77bbbbbb77777bbbbbb777bb77bccccc77c777c777c777c777c5555555555554444cccccccc
ffffffffffffffffffff33333333bbbbbbbb7b7b7b7b7bbb7bbb7bbbbbbb77b7b77bbbbbb7bb7b7bcccc7cccc7cc7c7c7c7cc7cc5555555555554444cccccccc
ffffffffffffffffffff33333333bbbbbbbb777b77bb77bb777b777bbbbb777b777bbbbbb7bb7b7bcccc777cc7cc777c77ccc7cc5555555555554444cccccccc
ffffffffffffffffffffffff33333333bbbb7bbb7b7b7bbbbb7bbb7bbbbb77b7b77bbbbbb7bb7b7bcccccc7cc7cc7c7c7c7cc7cccccccccccccccccccccccccc
ffffffffffffffffffffffff33333333bbbb7bbb7b7b777b77bb77bbbbbbb77777bbbbbbb7bb77bbcccc77ccc7cc7c7c7c7cc7cccccccccccccccccccccccccc
ffffffffffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0001020408102040808080800240400002020204040410101020202008080890020202040404101010202020080808900202020404041010102020200808089000000000404010201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c070704040707192a2a2a2a2a2a2a2a2a3b1d1d1d1d1d1d1d1d1d1d1d1d1d1d0707000000000c161717171717171717171717171717182f2a2a2a2f131414151617171717181314141415052f1605171705171717171718191b162727170d2717170505051718
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c192a2a1a2a1a2a070404040707393a2a2a2a2a2a2a2a2a0704042112040404041011120404040407000000000c262813141415360d27272705272727282f292a2b2f23240335262727271c1e332403240b252f0513141415362727052738292b26270527273727282314153628
1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d2d1e2a2a2916171717182b04040413241516182a2a2a062a2a2a2a071021212111111111212121162718042e000000000c260533242409252627052727272727282f2a2a2b2f092425162727271c21211823240935172f26230324082526272728192a2b36372727380a3605280b242537
2c2d042d2d2d2d042d042d042d2d042d2d1e2a2a360b0b0b282a07041324242c27282a2a2a2a2a062a3b0721212121212121212121212627270404000000000c3f3f180a3435163737272727272705282f292a2a2f330a35262f27272121160d0a343526382f26330a34351627272728292a2b2c0a2628092d0826233408191b
2c2d2d2d04161717380b0b0b200b2112042d2a2906082409282b04332424242c27382a2a2a2a2a2a3b073e2121212121212121212121363738042e000000000c36373834160538191b3637270d0d27282f392a2b2f160505382f080b0b3f3f3f3f3f3f3f3f1f270d170d1c2727272738292a2b170b2605180b163f3f3f19062b
2c2d100212362208080808082021212112041e2a2a0a0a0a1e2b04042424242c36192a062a2a2a3b043e21211c3d202121210a0a0a212121212104000000000c192a1b2638191a3a2a1a1a1b0d271c3e2f17291b0911102204191a1a1a1a1a1a1a1a1a1a1a1b1c2e27381011082628192a2a2a261727283e2137391a3a3a3a2a
2c2d3002020222080808080830163208082c2e2a2a2a2a2a1e2a073324242435042a2a3a3a3a3b042121221c3e2a2021210910111208212121212d000000000c393a3a1a1a3a3b161e392a3b271111081628292b0931093217393a3a3a3a3a3a3a16182a3a3b3d0a38043032042f3829062a2b26270d2809111236171717172b
2c2d04202121040404042d2d3e27181314152e291c1d1d1d072b042c2424242c04392a1c0707073e2121222e2a2a0721210930313208212121212e000000000c260518392a1617101217171727202108362729061b2f163d1e2f04300209322d2727052a27273f3f3f3f3f3f3f1f292a2a2a2b363705280430322d26270d192b
2c2d2d20213204071a1a1a1b3737382408082e2a2c2121212d2a042c2424350b123e2a2d081021212121222e2a2a072121210b0b0b21212121212d000000000c260d27171727273737370d270d1821222f26292a3b2f2627273f3f1f19321b3f052737292a3a3a0b0b0b0b0b0b0b3a292a2a2a1a1b3638191a1a1b0d38192a2b
2c2d0420220407072a2a2a2d1012342408082e292c2121212d2b07132435082122082b08082021212121183e2a2a071c212121212121212121212d000000000c260d09102727381011082627272730322f052a2b092f050d0d191a1a3a3a3a1b3638192a2a1b162727273c31311108392a2a2a3a3a1a1a3b1618393a1a3a2a2b
2c2d0430220407192a2a2a2d30322e0824242e2a2c2121212d2a0433350b210222082b08082021212121382a2a2a073c212121212121212121212e000000000c26270d301e28043008042627272717182f372a3b092f26180d393a3b161718391a1a3a3a3a3b050d1b3f272804303217292a2b1618393b160d28201108261718
072d042d2d04072a2a2a2a2a2a072e080a353e292c2101212d2b2d0408022121223e2b080820212121323e2a2a2a2a071e2121212121212121212e000000000c262727373737051717172727053737382f192b0d2b2f26271717171727373728393b16171717273f393b362717180405392a2b272717172727281e20322d3638
07072d01042d07392a062a2a2a07070707072a293c3d2d3d3e2a042d21210221322a2b0808202121323e2a2a2a2a2a072d1e21212121211c2d2d2e000000000c262728042011222627270527382011222f392b362b2f2627052727272804200208042627272705272f091e262705172718292b0d0d270527270d183116182c2e
07072d2d042d2d2d2a2a2a2a2a2a2a2a2a2a2a2a2a3a2a3a3a3b040430212132042a2b08083031323e2a2a2a072a2a07042d2d1e2121212d191b04000000000c260527171831042605272728041731042f17292a3b2f26272727272727171801161727270527272727183d363737272738292a2a2b3737272705271727270d0d
0c0c0c0c0c0c0c0c0c0c0c2d2d2d2d2d2d2d1d1414142d0c0c0c07040421322d2e2a2a2a2a1b043e2a2a2a2a2a2a2a073c2d042d2d2d2d19063b2d000000000c262727272717172727273727172801052f37292b3f1f2627271f3f3f1a1b3f3f2f2705272727272727053c09112226281d392b050911123627272705270d2727
1c1d2d0404071d04042a2a0404070404040704230909042a2a2a0707042d04042e392a2a2a2a2a2a2a062a2a2a2a2a2a073c2d2d012d2d393b2d2d000000000c363737373737372737380136272813141415212108162727272f191a2a2a1a1b2f2727272727270527272804310426283d17290504203204262727273f272728
2c16130415040b15282a2a2c04040407040404242415182a2a2a040404042d2d041e392a2a2a2a2a2a2a2a2a2a2a2a2a0704040404040404040404000000000c191a1a1a1a1a1b05131414152628230b2408252108262705272f2b151713151e2f2f27272705272727272718011627271728063628311a2627270b191b0b270d
2c280b14090903353829062c0416382d020216242409282d042d04180404040407070707041d041d2a2a2a2a2a040404042d2d2d2d2a2a2a2a2a2a0c0c0c0c0c292a2a2a2a2a3b370b240835262833032425212108262727272f2a33140b353e272f21052727272727270527172727272728391a1a3a3a1b0b0b193a3a1a1a1b
2c3823243424243c1d292b2c07362d2d02023804242d380413153638040704040707070704040413141415182a162314142521212d2a2a2a2a2a2a0c0c0c0c0c292a2a062a2b0d2324092516272727330a3527272f363737372f39092435182b0d212127272727270527273737373737373718392b1618393a1a3b1618393a3b
2c2d0a16043334352e292b2c042d21210202072d2d042d04332435210a0a2d040707070404131424242425282a262324242536182d2a2a2a2a2a2a0c0c0c0c0c292a2a2a2a2b3f280a34350527272727272727272f191a1a1b3f3f3f0b16382a212121272727052727272823141414141415361717270d182011082627171718
2c07042637380a2c2e292b0404042121210707042d2d2d041835073e0a0a0a080707040404232424242416282a263334342521382d2a2a2a2a2a040c0c0c0c0c292a2a2a2a3a062b3f3f3f383f3f3f3f3f3f3f3f1f393a3a3a2a1a2a1b3f3f2a3c3f3f273737272727271c21092403242408252627272728043104260d272728
2c2d04261d10112c2e292b0404043131310404040404043638213c2111111208072c041638232424242436382a3630313131212a2a2a2d070704040c0c0c0c0c393a3a3a3b16172a1a2a1a2a2a1a2a2a1a2a1a2a2a16171717101218393a2a2a2a1a3f3f191b262727052c2334340a3435292b26272727051801162727270528
2c2d07362c21212208292b2c07042d2d072d2d2d2d2d2d040421213e0718220804042d3621333434343511212a2a2a2a2a2a2a2a2d2d21212107040c0c0c0c0c161717171727273f3f3f292a2a171718393a3b1617272727273c212717171727392a1a1a2a2b3f3f272721210b0b3f3f3f293f37373737373717370d37272728
2c042d2d2c21022208292b2c36382d0707192a3a3a2a1b040709200707282208042c0407210a0a0a0a0a21222a2a2a2a2a2a2a2d2d2121212107070c0c0c0c0c260d0537370d272727052a2a2b270d271717172737373705272727381011080d171727292a2a1a1b3f3f191a3a3a1b0b0b191a1a2a3a3a1a1b3f2f0827272728
2c042d042c21212128292b07103d3e27272a2b0b0b292a040409203637382208042d2d102121212121213132070707072a2a2a2d212121212104040c0c0c0c0c26273820110826050d27292a2a27050d270d2728090222262727280430322d260d2728392a063a2a1a1a3a3b0a0a391a1a3a3a2b23141415393b2f08271e2728
2c2d07040421212138292b2c202122042e292b2009292b2d0409200221212208042c10212121212121210404070707042a2a2d2d212121211821040c0c0c0c0c26283e16312d262727272a062b27270d0d272728040104262727051717171727270d2728292b1618393b1617272718393b1618291b23240b250d2f0808122738
2c072d043e21211e192a2b2c202122042e2a2b0209292a042d093031313132082d2d2121212121212107072d07072d042a2d2d2d212121363821040c0c0c0c0c26271728011627272727292a2b27272727052727170505373727272727272705273738292a2b2627171737373737270a0a2728292b330a350d382f0808322728
26183c3e2d213d3e2a062b2c202122042e292b3009292a040409210b0b0b0b042d2c3131313121212132042d070104042d2d2121212121212121040c0c0c0c0c260527271727273737372a2a2b2727052727272728131414152627272705272728091112292b262727281011110826272727282a2a1a1a1a1a3a3a1a2b172728
26380b0b2d042d072a2a2b07202132042e2a2a1a1a2a2a2a2a04040404042d04042c0a0a0707212132042d2d072d2d2d2d2d072d2d2d2d2d2d2d000c0c0c0c0c2627272727270d131415392a3b37270d272727272833090b352627052727272728043032393b262727280921322d2627052728292a2a1c3e3b2f08392b263f28
2c0411113d042d072a2a2b2c303204042e29062a2a2a2a2a2a2a2a04042d040404320a0a30212121042d2d04042d072d2d2d2d2d182d2d072d2d0c0c0c0c0c0c26272727052823240b0325293b1e0d270d2705272718333526052727272727270517180116172705270d1831161705272727282a062b2011082f08082b120a28
2c042121361807192a2a2b2c040404012e392a2a2a2a2a2a2a2a2a2a042d0401040a0a0a0a212121042d0407042d2d2d072d2d363813152d072d0c0c0c0c0c0c26270527272718093435052b173d2627052727273737370d0d2727272727052727272717373727273f2727170527270d272728292a3b0d3021262f08190a2d28
161820210436072a2a2a2b07040704072e07392a2a2a3b2a2a2a2d0404040404040a0a0a0a162d2d04040704042d2d2d2d07210821333516182d0c0c0c0c0c0c36372727270d271728191a2b261705272727272809111112262727270527272727373738191b2627270d052727270d2f0d0528373727383c32262f082b303228
__sfx__
03030000356603c6603d6603f6603f6603e6603b65038640376403464000600006000060000600006000060000600006000060000600006000060000600000000000000000000000000000000000000000000000
0204100013450035000a5000750005500035000150006500035000c50008500055000040000400004000040000400004000040000400004000040000400004000040000400004000040000000000000000000000
0108000017450004000f4500040004400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
810e00001d0321d0321d0321d032210322103221032210321c032180321c032010022103221032210322a0021f0321b0321a0321f0321f0321f0321f0321f0321c0021b0321b0321e03220002210322103221032
250c0000191501d150201502515025150251502215022150251502515025150251500010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83321000001620515209162021520516200152071520516205162041620216202162071620c1620716202162291021c1021a1021d1021f1021d1021c1021a10218102181021a1021c1021a10218102181021c102
c9321000215552150521555215551f555285551c55515555215552b5551d50523555235052f555235052355500505005050050500505005050050500505005050050500505005050050500505005050050500505
871420000b5570055701557005570055700557005570b557015570055700557015570b5571575715757157570c5571e7571e7571e7571e7571e75714757147570b7570b7570b7570b75710757107571075710757
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c2000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 05064744

