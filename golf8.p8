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
  
  -- constants
  hole_locations = {
			   --{par=10,hole_x=120*8+4, hole_y=50*8+4, tee_x=67*8+4, tee_y=61*8+4},
      {par=4,hole_x=5*8+4, hole_y=50*8+4, tee_x=4*8+4, tee_y=63*8+4},
      {par=3,hole_x=5*8+2, hole_y=42*8+4, tee_x=4*8+4, tee_y=47*8+4},
      {par=5,hole_x=1*8+4, hole_y=18*8+4, tee_x=4*8+4, tee_y=38*8+4},
      {par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
      {par=3,hole_x=22*8+4, hole_y=7*8+4, tee_x=22*8+4, tee_y=14*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},
{par=4,hole_x=17*8+4, hole_y=13*8+4, tee_x=3*8+4, tee_y=15*8+4},

  }
		

		for h=1, #hole_locations do
			hole_locations[h].score = -1
		end

  hole_radius = 1.75
  
  -- terrain
  tt = "tee" -- "tee", "fairway", "green", "rough", "bunker", "water"
  
  ball_radius_ground = 1
  ball_radius_air = 2
  
  -- swing state
  swing_mode = "start" -- "ready", "aiming", "powering", "accuracy", "flying", "terrain_pause"
  power = 0.2 -- raw meter value starts at bar_start
  power_max = 1.0
  swing_timer = 0
  power_lock = 0
  accuracy_timer = 0
  accuracy_diff = 0
  
  -- bar visuals
  bar_x1 = 16
  bar_x2 = 110
  bar_y1 = 122 
  bar_y2 = 127
  bar_start = 0.2 -- visual reference start
  
  -- club types
  clubs = {
      {name="1w", max_power=1.3,    loft=18.0/360},
      {name="3w", max_power=1.2,   loft=20/360},
      {name="3i", max_power=1.0,    loft=25/360},
      {name="5i", max_power=.9,    loft=27/360},
      {name="9i", max_power=.75,     loft=43/360},
      {name="sw", max_power=.75,    loft=58/360},
      {name="p", max_power=1.0, loft=0}
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
  
  for club in all(clubs) do
      club.distance = calculate_club_distance(club)
  end
  
  hole_number = 5
  
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

function calculate_club_distance(club)
    local power = club.max_power
    local vx = power * cos(club.loft)
    local vz = power * abs(sin(club.loft))
    local z = 0.0
    local distance = 0

    while z > 0 or vz > 0 do
        -- Compute speed
        if vx > 0 then

            local drag_force = (1 - drag_constant) * vx^2

            -- Apply drag as force opposite to velocity
            vx -= drag_force * vx
        end

        -- Apply gravity
        vz -= g

        -- Update position
        distance += vx
        z += vz

        if z <= 0 then
            z = 0
            vz = 0
        end
    end

    -- Simulate roll
    while abs(vx) > 0.01 do
        vx *= 0.95  -- friction on ground
        distance += vx
    end

    return distance
end

-- wind
function random_wind()
    wind_angle = rnd(1.0)
    wind_speed = flr(rnd(8))
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
    
    random_wind()
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
    local tx = flr(x / 8)
    local ty = flr(y / 8)
    local spr_id = mget(tx, ty)
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


function to_ready()
   power = bar_start
   swing_mode = "ready"
end

function _update()

   if swing_mode == "start" then
							if btnp(5) then
											reset_ball_and_hole()
							end
							return
				end


    penalty_box = 0.2
    bar_start = 0.2

    if shot_terrain == "bunker" then
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
            to_ready()
            -- aim to the hole
            angle = atan2(hole_x - ball_x, hole_y - ball_y)

            if tt == "green" then
              current_club = 7
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
            local is_duff = accuracy_diff > penalty_box
            local penalty_ratio = mid(0, accuracy_diff / penalty_box, 1)
            local offset_angle = (accuracy_diff / 1.0) * 0.6
            local direction = rnd(1) < 0.5 and -1 or 1
            local final_angle = angle + (direction * offset_angle)
            local club = clubs[current_club]

            local power_scale = 1
            if shot_terrain == "rough" or tt == "tree" then power_scale = 0.9
            elseif shot_terrain == "bunker" then power_scale = 0.75 end


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

            ball_dx = cos(final_angle) * power_lock * club.max_power * power_scale
            ball_dy = sin(final_angle) * power_lock * club.max_power * power_scale
            ball_dz = abs(sin(club.loft))   * power_lock * club.max_power * power_scale 

            game_message = "accuracy"..accuracy_diff..""
            game_message_timer = 1000

            --game_message = "initial_swing: "..abs((club.loft))..","..ball_dx..","..ball_dy..","..ball_dz
            --game_message_timer = 60

            swing_mode = "flying"
            ball_prev_x = ball_x
            ball_prev_y = ball_y
            shot_count += 1
            shot_terrain = tt

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
           -- Compute current velocity components

           -- Apply wind

											
           ball_dx += cos(wind_angle) * wind_speed *.002
           ball_dy -= sin(wind_angle) * wind_speed *.002


           -- Apply shot shape
           if ssh.right then
             ball_dx += sin(angle) * 0.02
             ball_dy -= cos(angle) * 0.02

           end

           if ssh.left then
             ball_dx -= sin(angle) * 0.02
             ball_dy += cos(angle) * 0.02
           end
           
           if speed > 0 then
               -- Normalize velocity vector for drag direction
               vx = ball_dx / speed
               vy = ball_dy / speed
     
               -- Apply quadratic drag (opposite to direction of motion)
               drag_force = (1-drag_constant) * speed^2
               ball_dx -= drag_force * vx
               ball_dy -= drag_force * vy

           end


           --- tree swatter
           if tt == "tree" and ball_z > 0.5 and ball_z < 1.5 then

             ball_dx *= 0.85
             ball_dy *= 0.85
             ball_dz *= 0.85

             --- Very unlikely randomly flip all directions
              if rnd(1) < 0.05 then
                  ball_dx *= -1
                  ball_dy *= -1
                  ball_dz *= -1
              end
           end

           ball_dz -= g

           if ball_z < 0 then
               ball_z = 0
               ball_dz = 0
           end
        else -- Grounded
          ball_z = 0
          ball_dz = 0

            if first_touch then
              --apply shotshape spin
              if ssh.up then
                  ball_dx += cos(angle) * .5 
                  ball_dy += sin(angle) * .5
              end
              if ssh.down then
                  ball_dx -= cos(angle) * .5
                  ball_dy -= sin(angle) * .5
              end
              first_touch = false
            end


            local slope_const = .01
            if speed < .02 then
              slope_const = 0
            end
            if tt == "bunker" then
                ball_dx *= 0.75
                ball_dy *= 0.75
            elseif tt == "rough" or tt == "tree" then
                ball_dx *= 0.8
                ball_dy *= 0.8
            elseif tt == "fairway" or tt == "green" or tt == "tee" then
                ball_dx *= 0.95
                ball_dy *= 0.95
            elseif tt == "left" then
                ball_dx -= slope_const
                ball_dy *= 0.95
                ball_dx *= 0.95
            elseif tt == "right" then
                ball_dx += slope_const
                ball_dy *= 0.95
                ball_dx *= 0.95
            elseif tt == "up" then
                ball_dy -= slope_const
                ball_dx *= 0.95
                ball_dy *= 0.95
            elseif tt == "down" then
                ball_dy += slope_const
                ball_dx *= 0.95
                ball_dy *= 0.95
            end
 
        end

        if abs(ball_dx) < 0.01 then ball_dx = 0 end
        if abs(ball_dy) < 0.01 then ball_dy = 0 end

        ball_x += ball_dx
        ball_y += ball_dy
        ball_z += ball_dz

        if max_height < ball_z then
            max_height = ball_z
        end

        if ball_z == 0 and (tt == "water" or tt == "ob") then
            game_message = "Landed in "..tt.."\n+1 penalty stroke"
            game_message_timer = 60
            shot_count += 1
            ball_dx = 0
            ball_dy = 0
            ball_dz = 0
            ball_x = ball_prev_x
            ball_y = ball_prev_y
            shot_terrain = get_terrain(ball_x, ball_y)
            ssh.left = false
            ssh.right = false
            ssh.up = false
            ssh.down = false
            swing_mode = "terrain_pause"
            return
        end


								-- check overflow on dist

								local dist =	safe_dist(ball_x, ball_y, hole_x, hole_y)
        if (ball_z == 0) and (dist < hole_radius + ball_radius_ground * 0.6) then
            if speed < 0.2 then
                ball_dx = 0
                ball_dy = 0
                ball_dz = 0
                ball_x = hole_x
                ball_y = hole_y

                swing_mode = "hole_pause"
                return
            end
        end

        if ball_dx == 0 and ball_dy == 0 and ball_z == 0 and ball_dz == 0 then
                swing_mode = "terrain_pause"
                ball_dx = 0
                ball_dy = 0
                ball_dz = 0
                ssh.left = false
                ssh.right = false
                ssh.up = false
                ssh.down = false
                shot_terrain = get_terrain(ball_x, ball_y)
        end

        elseif swing_mode == "hole_pause" then
            game_message = "press ❎ to continue"
            game_message_timer = 60
												hole_locations[hole_number].score = shot_count
            if btnp(5) then
													  swing_mode = "scoreboard"
												end

								elseif swing_mode == "scoreboard" then
												if btnp(5) then
																hole_number += 1
																reset_ball_and_hole()

   									end
								end
    
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
         local tile = mget(map_x + mx, map_y + my)
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
		   

				if swing_mode == "scoreboard" then
					  local total	= 0
							local ou = 0
					  for h=1, #hole_locations do
									local hole = hole_locations[h]
									local par = hole.par
									local score	= hole.score

									if score == -1 then
											score = "-"
								else
										total += score
										ou = score	- par
									end
									local sb_x = 1

									if h > 9 then
										sb_x = 65
									end

										print("hole "..h..": p"..par.." "..score.."", sb_x, 8 + ((h-1)%9) * 8, 7)
					  end
							local tstr = "total: "
							if total > 0 then
								tstr =	"total: +"
							end
							print("total: "..total.." "..ou.."", 40, 110, 7)
							print("❎ to continue", 40, 120, 7)
							return
				end

    --map(flr(cam_x / 8), flr(cam_y / 8), 0, 0, 128, 32)
    camera(cam_x, cam_y)
    map(0, 0)
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

    -- draw hole
    circfill(hole_x, hole_y, hole_radius, 1)

    -- draw ball
    local radius = ball_z > 0 and ball_radius_air or ball_radius_ground
    circfill(ball_x, ball_y, radius, 7)

    if swing_mode == "aiming" or swing_mode == "powering" or swing_mode == "accuracy" or swing_mode == "ready" then
      line(ball_x, ball_y, aim_x, aim_y, 10)
      line(aim_x - 1, aim_y, aim_x + 1, aim_y, 10)
      line(aim_x, aim_y - 1, aim_x, aim_y + 1, 10)
    end

    -- wind
    camera()
    local cx, cy = 122, 8
    circfill(cx, cy, 4, 1)

    line(cx, cy, cx + cos(wind_angle)*5, cy - sin(wind_angle)*5 , 7)
    print(""..wind_speed.."", cx -1  , cy +6, 7)
    --print(""..cos(wind_angle).."\n"..sin(wind_angle).."", cx - 20  , cy +13, 7)


    camera()
    rectfill(bar_x1, bar_y1, bar_x2, bar_y2, 1) -- clear bar
    local w = (bar_x2 - bar_x1 - 2)
    local x1 = bar_x2 - 1 - mid(0, bar_start + penalty_box, 1) * w
    local x2 = bar_x2 - 1 - mid(0, bar_start - penalty_box, 1) * w
    rectfill(x1, bar_y1 + 1, x2, bar_y2 - 1, 8) -- draw accuracy box
    
    local marker_x = bar_x2 - 1 - mid(0, power, 1) * w
    local start_x = bar_x2 - 1 - bar_start * w
    line(start_x, bar_y1 + 1, start_x, bar_y2 - 1, 13)
    line(marker_x, bar_y1 + 1, marker_x, bar_y2 - 1, 7)

    if swing_mode == "accuracy" or swing_mode == "flying" then
      --- power marker for power lock
      local power_lock_x = bar_x2 - 1 - mid(0, power_lock, 1) * w
      line(power_lock_x, bar_y1 + 1, power_lock_x, bar_y2 - 1, 7)
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
        local spr_id = mget(flr(ball_x / 8), flr(ball_y / 8))
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



    if swing_mode == "powering" then
      print("power", 36, 117, 7)
    elseif swing_mode == "accuracy" then
      print("accuracy", 36, 117, 7)
    elseif swing_mode == "ready" then
        print("press ❎ to swing", 36, 117, 7)
    elseif swing_mode == "terrain_pause" then
        print("landed in: "..tt.."", 32, 60, 7)
        print("press ❎ to continue", 24, 68, 7)
    elseif swing_mode == "hole_pause" then
        local par = hole_locations[hole_number].par

        if shot_count == 1 then
            print("hole in one!", 64, 90, 7)
        elseif shot_count - par == -3 then
            print("albatross!", 64, 90, 7)
        elseif shot_count - par == -2 then
            print("eagle!", 32, 90, 7)
        elseif shot_count - par == -1 then
            print("birdie!", 32, 90, 7)
        elseif shot_count - par == 0 then
            print("par!", 32, 90, 7)
        elseif shot_count - par == 1 then
            print("bogey!", 32, 90, 7)
        elseif shot_count - par == 2 then
            print("double bogey!", 64, 90, 7)
        elseif shot_count - par == 3 then
            print("triple bogey!", 64, 90, 7)
        else
          print("+"..shot_count-par.."", 64, 90, 7)
        end
    end


    print("hole: "..hole_number, 1, 1, 7)
    print("par: "..hole_locations[hole_number].par, 1, 9, 7)
    print(""..shot_count, 1, 17, 7)

    --if ball_z > 0 then
    --    print("ball z: "..ball_z, 1, 25, 6)
    --else
    --    print("terrain: "..tt, 1, 25, 6)
    --end

    --- terrain
    --- get map sprite
    local tx = flr(ball_x / 8)
    local ty = flr(ball_y / 8)
    local spr_id = mget(tx, ty)

    rectfill(111, 111, 127, 127, 5)

    sspr(spr_id % 16 * 8, flr(spr_id / 16) * 8, 8, 8, 112, 112, 15, 15)
    -- put image of ball on tile
    circfill(119.5, 120, 4, 7)

    if club.name != "p" then
        -- put dot indicating shot shape
        dotx = 119.5
        doty = 120

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


    ---print("club distance: "..clubs[current_club].distance, 1, 33, 6)
    ---print(""..ball_x..","..ball_y..","..ball_z..";", 1, 41, 6)
    ---print(""..ball_dx..","..ball_dy..","..ball_dz.."", 1, 49, 6)
    ---print(""..angle.."", 1, 57, 6)
				dx	= ball_x - hole_x
				dy = ball_y - hole_y
				--local dist	= sqrt((dx*dx) + (dy*dy))
				--dist = safe_dist(ball_x, ball_y, hole_x, hole_y)
				--print("distance: "..dist.."", 1, 57, 7)
				--print(""..dx..","..dy.."", 1, 65, 7)

    if swing_mode == "camera_pan" then
      print("hole "..hole_number.."", 58, 64, 7)
    end

    -- club
    local club_x = 8 
    local club_y = 119
    circfill(club_x, club_y, 8, 7)
    circfill(club_x, club_y, 7, 9)

    local club_sprite = 66
    if current_club <= 2 then
      club_sprite = 64
    elseif current_club <= 6 then
      club_sprite = 65
    end

    spr(club_sprite, club_x - 3, club_y - 6)

    print(""..clubs[current_club].name, club_x -3, club_y +2, 7)

    if game_message_timer > 0 then
      print(game_message, 32, 100, 7)
    end
end


__gfx__
0000000033bbbb333bb33bb3bbbbbbbb33333333ffffffffcccccccc33333333b3bb33bbbb33bb3bbb3333bbbbb33bbb00000000000000000000000000000000
000000003bbbbbb3bb33bb33bbbbbbbb33333333ffffffffcccccccc33399343b33bb33bb33bb33bb33bb33b33bbbb3300000000000000000000000000000000
00700700bcbbbbcbb33bb43bbbbbbbbb33343333ffffffffcccc35cc43999933bb33bb3333bb33bb33bbbb33b33bb33b00000000000000000000000000000000
00077000bbbbbbbb33bb34bbbbbbbbbb334b3333ffffffffcccc33ac338888333bb33bb33bb33bb33bb33bb3bb3333bb00000000000000000000000000000000
00077000bbbbbbbb3bb43bb3bbbbbbbb33333333ffffffffc76667cc399999933bb33bb33bb33bb3bb3333bb3bb33bb300000000000000000000000000000000
00700700bbbbbbbbbb34bb33bbbbbbbb33333333ffffffffcc5554cc38888883bb33bb3333bb33bbb33bb33b33bbbb3300000000000000000000000000000000
000000003bbbbbb3b33bb33bbbbbbbbb33333333ffffffffcccccccc33344333b33bb33bb33bb33b33bbbb33b33bb33b00000000000000000000000000000000
0000000033bbbb3333bb33bbbbbbbbbb33333333ffffffffcccccccc34333343b3bb33bbbb33bb3bbbb33bbbbb3333bb00000000000000000000000000000000
4b535b543543345335433b5433b3bb3b3bb3b33b333bb3333fbf33fb3f4ffb3ff44ff4ff5c31c35c3b1c4c3431c6343133343b3443343b4343b3343b00000000
bb33b5334b33bb33bb33bb34bb3bbbbbb3bb3bbbbbb3bbbbfffffffffffffffffffffff3c1c13cccc1cccc1ccccc1ccc433333333b33333b33333b3300000000
533bb33bb33bb33bb33bb3343bbbbbbbbbbbbbbbbbbbbbb33fffffffffffffffffffffffc4cccccc7cccccccccccccc1b4333333333333333333333400000000
33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbbb3bbffffffffffffffffffffffbdcccccccccccccc7ccccccc643333333333333333333333300000000
3bb33bb33bb33bb33bb33bbbb3bbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff4ccccccccccccccccccccccc33333333333333b333333333400000000
bb33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbb3b3fffffffffffffffffffffffbcccccccccccccccccc71ccbb3333333333b33333333333300000000
433bb33bb33bb33bb33bb3353bbbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff3dcccccccccccccccccccccc13333b33333333333333333b300000000
33bb33bb33bb33bb33bb33b43bbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffff441cccccccccccc17cccccc13b3333333333333333333333400000000
5bb33bb33bb33bb33bb33bb53bbbbbbbbbbbbbbbbbbbbbb33fffffffffffffffffffffff5cccccccccccccccccccccc643333333333333333333333300000000
5b33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbbb3fffffffffffffffffffffff46cccccc7ccccccccccccccc333333333333333333333333400000000
bb3bb33bb33bb33bb33bb33433bbbbbbbbbbbbbbbbbbbbb3bffffffffffffffffffffffb3cccccc1cccccccccccccc1c3433333333333333333333b300000000
33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffff4c4ccccccccccccccccccccc1b3333333333333333333333300000000
5bb33bb33bb33bb33bb33bb5b3bbbbbbbbbbbbbbbbbbbb3b3fffffffffffffffffffffff1ccccccccccccccccc6ccccb33333333333333333333333b00000000
5b33bb33bb33bb33bb33bb333bbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffb53ccccccccccccccccccccc1b3333333333b33333333333300000000
b33bb33bb33bb33bb33bb335bbbbbbbbbbbbbbbbbbbbbbb34fffffffffffffffffffffff61cccccccccccccccccc1ccc33333b333b3333333333333400000000
43bb33bb33bb33bb33bb33b43bbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffff34cccccccccccccccccccccc343333333333333333333333300000000
4bb33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbb34ffffffffffffffffffffff33cccccccccccccccccccccc433333333333333333b33333300000000
5b33bb33bb33bb33bb33bb35b3bbbbbbbbbbbbbbbbbbbb3bbfffffffffffffffffffffff5cccccccccccccc6cccccc1cb3333333333333333333333300000000
433bb33bb33bb33bb33bb33b3bbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffff431cccccccccccccccc7cccc143333333333333333333333b00000000
33bb33bb33bb33bb33bb33bb3bbbbbbbbbbbbbbbbbbbbbb34ffffffffffffffffffffff31ccccccccccccccccccccccc33b33333333333333333333400000000
3bb33bb33bb33bb33bb33bb4b3bbbbbbbbbbbbbbbbbbbb3bffffffffffffffffffffffff4cccccccccccccccccccccc63b333333333333333333333300000000
bb33bb33bb33bb33bb33bb33bbbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffffbc1c71cccccccccccccccccc443333333333333333333333300000000
433bb33bb33bb33bb33bb334b3bbbbbbbbbb3bbbbbbb3bbbfffffffffffffffffff34fff57cccccccccc4cc6ccccccc63333333b3b3333333b33343300000000
54b4334553b433b4345b35bb33b3333b3bb3bb333b3b33333f3fb33343ffb3f33f3433b43135117417315c151c13b513b3b34b4b43b34b3bb33433b400000000
000000d50000000500000550000000000000000000000000000000000000000000000000000000000000000000000000cccc333bbbbbbbbbbbbbbbbbbbbb8bbb
000000550000005500000550000000000000000000000000000000000000000000000000000000000000000000000000ccc33bbbbbbbbbbbbbbbbbbbb89bbb8b
000005500000005000000550000000000000000000000000000000000000000000000000000000000000000000000000c333bbbbbbbbbbbbbbbbbbbbbbbbbbb9
0000060000000d0000000dd000000000000000000000000000000000000000000000000000000000000000000000000033bbbbbbbbbbbbbbbbbbbbbbbbbbb8bb
0550d6000000600000000600000000000000000000000000000000000000000000000000000000000000000000000000bbb33333bb7777bbb33bbbbb33333bb9
55556000776d600000000600000000000000000000000000000000000000000000000000000000000000000000000000bbb33333b777777bb33bbbbb33333bbb
d66dd0007666000055555600000000000000000000000000000000000000000000000000000000000000000000000000bbb33bbbb777777bb33bbbbb33bbbbbb
5dd500005665000057775000000000000000000000000000000000000000000000000000000000000000000000000000bbb33bbbb777777bb33bbbbb33333bbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb33b33b667777bb33bbbbb33333bbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb33333b666777bb33333bb33bbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb33333bb6667bbb33333bb33bbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb3333bbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb333333bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb333bb333bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb33bbbb33bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb33bbbb33bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb33bb33bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb333333bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbb33bb33bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb33bbbb33bbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbb33bbbb33bbbbbbbbbbbb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbbbbbbbbbb333bb333bbbbbbbbbbbb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033bbbbbbbbbbb333333bbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f33bbbbbbbbbbb3333bbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff33bbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff33bbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff33bbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff33bbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff33bbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff3bbbbbbbbbbbbbbbbbbbbbbbb
40121263817091a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
810212406370a2a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
830212217070a2a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400312122170a2a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70c1e213137092a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70c3d2d1d1d2a2a2a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070c3d210d293a3b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91a2a2a2a1a2a2a1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2618193a3a360c200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a26231b0517093c200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2623353d301214000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
93606373737302122100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7093a3a3a3a302201200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070d1d1021312122300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707040104070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1d2d2d2d1d2d1d2e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c34061834141b040e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b1c3639043804353e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2b1c3d3d3d36383d300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a260a1a3a1a3a1a3a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2b2d1d1d1a0d1e300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2a261810120618100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2b263830222628200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2a2b370700213628300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2b2c1e312126383e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2b2c303121290c1e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
12122212021212121212121212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a3a2a1c2031290c2e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
121222120212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000c4d4e4f4
70b3d1d2d2d2d2407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
121222100212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000c5d5e5f5
7070c3d2d2d2d2d27000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012121212121212121212
121222120212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000c6d6e6f6
707070c310d3d3707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7d7e7f7
__gff__
0001020408102040808080800000000002020204040410101020202008080800020202040404101010202020080808000202020404041010102020200808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007070707070707070707072a2a2a161717171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070707070707070707072d2d2d2d2d2d2d2d2a2a260b0b0b2800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07072d2d04053705050b0b0b210b2112042d2a2a2a08240b2800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07071002120521080808080821212121212d2d2a2a0a0a0a282a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
072c3002020221080808080832162108082d2d072a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
072c04202121210404042d2d2d27052424152d071c1d1d1d2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
072c2d20213204071a1a1a1b3737052408082d072c2121212d2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
072c0420222d07072a2a2a083434342408082d072c2121212d2a000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070430222d07192a2a2a0a07072e08242407072c2121212d2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707042d2d2d072a2a2a2a2a2a072e080a3507072c2101212d2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070707012d2d07392a062a2a2a07070707072a2a3c3d3d3d3e2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070707070707072a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18131415040b15282a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
280b2409090335382a2a2a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3823350424243c1d2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070a16043334352e2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07043637380a2c2e2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07041d1d10212c2e2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
073618042021222e2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07073820212121082a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07072d1e210221082a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070404212121282a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070404212121382a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707043e21211e192a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
183c3e2d213d3e2a2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
380b0b2d0407072a2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0421213d0407072a2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300003f6503b650366500087000870206502c65033650376503e65000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000800001847000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0008000017450004000f4500040004400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000f00001d1501d1501d1501d150211502115021150211501c150181501c15001100211501d150211502a1001f150001001a1501f1501b1501f150001001f1501c1001b1501b1501e15020100211502115021150
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
