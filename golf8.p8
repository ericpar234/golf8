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
      {name="sw", max_power=.7,    loft=54/360},
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
  
  hole_number = 1
 
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

	  -- check if out of	bounds
			local bb = hole_locations[hole_number].bb
			if x < bb.x1*8 or x > (bb.x2*8) + 8 or y > (bb.y1*8) + 8 or y < bb.y2*8 then
				return "ob"
			end


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
            elseif shot_terrain == "bunker" then power_scale = 0.85             end


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

           -- apply wind
           ball_dx += cos(wind_angle) * wind_speed *.0008 * ceil(ball_z/2)
           ball_dy -= sin(wind_angle) * wind_speed *.0008 * ceil(ball_z/2)


           -- apply shot shape
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

             ball_dx *= 0.8
             ball_dy *= 0.8
             ball_dz *= 0.8

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

           play_tone(ball_z + 24, 0, 5)

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


            local slope_const = .015
            if speed < .01 then
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

								local dist =	safe_dist(ball_x, ball_y, hole_x, hole_y)
        if (ball_z == 0) and (dist < hole_radius + ball_radius_ground * 0.6) then
            if speed < 0.2 then
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
						    if hole_number >= #hole_locations then
									swing_mode = "start"
									return
                end

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
							print(""..tstr..""..total.." "..ou.."", 40, 110, 7)

							if hole_number >= #hole_locations then
								print("game over press	❎ to restart", 2, 120, 7)
							else
							  print("❎ to continue", 40, 120, 7)
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
    -- draw hole
    circfill(hole_x, hole_y, hole_radius, 1)

				-- draw pin
				if safe_dist(ball_x, ball_y, hole_x, hole_y) > 16 and shot_terrain != "green" then
				  spr(67, hole_x-1, hole_y-8)
				end

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

				if wind_speed > 	0 then
      line(cx, cy, cx + cos(wind_angle)*5, cy - sin(wind_angle)*5 , 7)
				end
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



    if swing_mode == "powering" then
      print("power", 36, 117, 7)
						print("❎", 18, 117)
    elseif swing_mode == "accuracy" then
      print("accuracy", 36, 117, 7)
						print("❎", 87, 117) 
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
            print("double bogey", 64, 90, 7)
        elseif shot_count - par == 3 then
            print("triple bogey", 64, 90, 7)
        else
          print("+"..shot_count-par.."", 64, 90, 7)
        end
        
        if pl_h_sfx == 1 then

          score_sfx = 4

          if shot_count - par > 0 then
            score_sfx = 2
          end
          
          sfx(score_sfx)
          pl_h_sfx = 0
        end
    end


    print(hole_number, 9, 1, 7)
				spr(67, 1, 1)
    print("par"..hole_locations[hole_number].par, 1, 9, 7)
    print(""..shot_count, 1, 17, 7)


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
000000003bbbbbb33bb33bb3bbbbbbbb33333333ffffffffcccccccc33333333b3bb33bbbb33bb3bbb3333bbbbb33bbb50050055500500550000000000000000
00000000bbbbbbbbbb33bb33bbbbbbbb33333333ffffffffcccccccc33399343b33bb33bb33bb33bb33bb33b33bbbb3355000550550005500000000000000000
00700700bbbbbbbbb33bb43bbbbbbbbb33343333ffffffffcccc35cc43999933bb33bb3333bb33bb33bbbb33b33bb33b05505500055055000000000000000000
00077000bcbbbbcb33bb34bbbbbbbbbb334b3333ffffffffcccc33ac338888333bb33bb33bb33bb33bb33bb3bb3333bb00555005005550050000000000000000
00077000bbbbbbbb3bb43bb3bbbbbbbb33333333ffffffffc76667cc399999933bb33bb33bb33bb3bb3333bb3bb33bb350055500500555000000000000000000
00700700bbbbbbbbbb34bb33bbbbbbbb33333333ffffffffcc5554cc38888883bb33bb3333bb33bbb33bb33b33bbbb3300550550005505500000000000000000
00000000bbbbbbbbb33bb33bbbbbbbbb33333333ffffffffcccccccc33344333b33bb33bb33bb33b33bbbb33b33bb33b05500055055000550000000000000000
000000003bbbbbb333bb33bbbbbbbbbb33333333ffffffffcccccccc34333343b3bb33bbbb33bb3bbbb33bbbbb3333bb55005005550050050000000000000000
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
63830212217070a2a2a2b24040a0a0a0a0a0c1e140a2a2a2a2a24040d240d240d21111111162c3814091a1b140d2d212121212801212d26383d200003fbf33fb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff
c2d203121221d2a2a2a2b24040903030308040e240a2a2a2a2a212d2403151704002121212637383409260b240d2d21212121323a0a0d2d2d2d200003fffffff
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bfffffff
c240c1e21313d292a2a2b24040904242428070e240a2a2a2a29012129032425140021212121240704092a2b24010d2d2d2d2d270d270d270d2d20000ffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003fffffff
c2d2d2d2d1d1d2a2a260b2404090b012b080c2e24040a260a29012124033435340031313122240409170e3b340d2d2d2d2d2d2d2d2d2d2d2d2d20000ffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003fffffff
c34040c3d210d293a3a3b240e29090128080c2e24040a2a2a29012717040b040707040d2d223404093a3b34040c1404040404040404040404000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
707070707070707070707040e29090128080c2e2404040a2a2a212638312121240707010404040407040704040d2d2d270e341415161d2d2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a1a1a1a1a1a1a1a1a1a14040e29090128080c2704040404040a2a212b0b0b0d240707070704040704040404040d240d2813242425262d2d2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91a2a2a260a2a3a2c1704040e29090128080c2e2704040121240a240a2a2a2a2a2c170d1d170d1d14040704070404063833343435363d2d2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b26181b3b09360a24040e29090128080c2e270404010121240a2a2a2a2a2a2c24040401212123141415140404040a2a21212a2a2c340e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b26231b0517093a2b140e29090128080c2e27040404040404040404040a2a2c201211212123142424252704040a2a2a2a2a2a2a2a2c3e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b2623353d30121e2b240e2b0b0b0b0b0c2e27070707070404040404040a2a20112121212703342424252404040a2c1d1d10121e1a2a2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9360b26373737302127092a2a2a2a2a2a2a2a2a2617171837070d2404070407070021212121212e133434352e2a2a2a2c270121212c3e1a2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d193a3a3a3a3022012c292a2a2a2a2a3a1a3a3a1728331415180d24040d2404070021212401212c3e3111153e2a2a2a2c20212122012e3a2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c2d1d1d10213121223c39260a2b34040d24093a26331428052804040404040707002121240d270638202202240a2a2a2c2022012121221a2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c27070401040d2707070e1a3b34010404040d2a27033b0425280d240d2d2d24070021212d270c0c082a0a0d2a2a2e1a2c3031212121222a2e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070707070c240d1d1d1d3d1d1e1a2b1403343538040d2a0a0a0e27002121270c0c0c082a0a08092c140a2a2c3e3a2a2122240e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70d2d2d2d1d2d1d270b2c26181d3d3d3d3d3e292a2b0b0b0b0b04040111111e27002121270c0c0c06373838092c2d2e1a2a2a2a2e1032340e200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c34061834141b040e2b2c283314141415170e2a2a2c3407070708140022022407002121270c0c0c070a0a08092c2d2d240d240d2d24040d24000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b1c3639043804353e2b2c2e2424242424251e292a2a2b26171814070132022e27002121270c0c0c070a0a08092c2d240d2d240d2404010d24000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92b1c3d3d3d36383d3b2c2e2334343434353e2a2a2a2b26373707070b01322407002121270c0c0c070a0a08092c24070404070404070d240e300000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9260a1a3a1a3a1a3a3b2c2e2b0b0b0b0b0b0e292a2a2b24013131370d2b023e27002121270c0c0c070a0a091a24040d3e3414141404040400000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b2d1d1d1a0a0e3b270e2b0b0b0b0b0b0e392a2a2a2c3b0b0b0d3d3d3b0407002121270c0c0c0701291a2a2d2e270614242428170d2400000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2a2618101202181b2c2e2b0b0b0b0b0b040a2a2a2a2a290b0b0b0b0b080407002121270c0c0c0701292a2a240e2b16342a04283b140e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b2638302226282b2c24001111111216183a2a260a2b290011220122180d27002121270c0c0c0702092a2a24070a2b112a012a2a270e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92a2b3707002136283b2c2400220121261837092a2a2a2a290032013202380e27002121270c0c0c0407272a2a2c2a2a2a212a012a260b1e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92b2c1e312126383e1b2c24002121212627070a2a2a2a2a290b0b0b0b0b080e2700212124070c0c0402020a2a2c2a260a212a012a2a2a2e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92b2c303121290c1e2b2c240021220126383e292a260a2b211111111111111d2700212121270c070401212e1a2c2a2a2a212a012a2a260e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a3a2a1c2031290c2e2b2c240031212121221e2a2a2a2a2a202121213131323e2700212121212c070401212e2a2c260a2a212a012a2a2a2e20000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70b3d1d2d2d2d24070b270404002131312237093a2a2a2a2c2132240d3d3d3e37002121212124040011223e2a2c2a2a2a212a012a2a2a2e20000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4d4e4f4
7070c3d2d2d2d2d270b270704023d2d2d27070704040e1a2c3d3d3e3a2a2a2a270e21212121240401212c1e3a2c2a2a2b340a040a2a2b3e20000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c5d5e5f5
707070c310d3d37070b2707070c310d370707070104040a2a2a2a2a2a2c1d1e170e21212124010a2a2c3e3a2a2c240b34040104040b340400000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c6d6e6f6
70707070d2d2707070b270707070707070707070704040d1d1e1a2a2c3d3d3d370404040404040a2a2a2a2a2a240404040d2d2d2404040400000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7d7e7f7
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
0001020408102040808080800202000002020204040410101020202008080800020202040404101010202020080808000202020404041010102020200808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
0000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000070704040707192a2a2a2a2a2a2a2a2a3b1d1d1d1d1d1d1d1d1d1d1d1d1d1d0707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000002a192a2a1a2a1a2a070404040707393a2a2a2a2a2a2a2a2a0704042112040404041011120404040407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d2d1e2a2a2916171717182b04040413241516182a2a2a062a2a2a2a071021212111111111212121162718042e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d042d2d2d2d042d042d042d2d042d2d1e2a2a360b0b0b282a07041324242c27282a2a2a2a2a062a3b0721212121212121212121212627270404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2d2d04161717380b0b0b200b2112042d2a2906082409282b04332424242c27382a2a2a2a2a2a3b073e2121212121212121212121363738042e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d100212362208080808082021212112041e2a2a0a0a0a1e2b04042424242c36192a062a2a2a3b043e21211c3d202121210a0a0a212121212104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d3002020222080808080830163208082c2e2a2a2a2a2a1e2a073324242435042a2a3a3a3a3b042121221c3e2a2021210910111208212121212d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d04202121040404042d2d3e27181314152e291c1d1d1d072b042c2424242c04392a1c0707073e2121222e2a2a0721210930313208212121212e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d2d20213204071a1a1a1b3737382408082e2a2c2121212d2a042c2424350b123e2a2d081021212121222e2a2a072121210b0b0b21212121212d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d0420220407072a2a2a2d1012342408082e292c2121212d2b07132435082122082b08082021212121183e2a2a071c212121212121212121212d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d0430220407192a2a2a2d30322e0824242e2a2c2121212d2a0433350b210222082b08082021212121382a2a2a073c212121212121212121212e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
072d042d2d04072a2a2a2a2a2a072e080a353e292c2101212d2b2d0408022121223e2b080820212121323e2a2a2a2a071e2121212121212121212e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07072d01042d07392a062a2a2a07070707072a293c3d2d3d3e2a042d21210221322a2b0808202121323e2a2a2a2a2a072d1e21212121211c2d2d2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07072d2d042d2d2d2a2a2a2a2a2a2a2a2a2a2a2a2a3a2a3a3a3b040430212132042a2b08083031323e2a2a2a072a2a07042d2d1e2121212d191b04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a2a2a042a2a2a2a2a2a2d2d2d2d2d2d2d1d1414142d2a2a2a07040421322d2e2a2a2a2a1b043e2a2a2a2a2a2a2a073c2d042d2d2d2d19063b2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d2d0404071d04042a2a0404070404040704230909042a2a2a0707042d04042e392a2a2a2a2a2a2a062a2a2a2a2a2a073c2d2d012d2d393b2d2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c16130415040b15282a2a2c04040407040404242415182a2a2a040404042d2d041e392a2a2a2a2a2a2a2a2a2a2a2a2a0704040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c280b14090903353829062c0416382d020216242409282d042d04180404040407070707041d041d2a2a2a2a2a040404042d2d2d2d2a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c3823243424243c1d292b2c07362d2d02023804242d380413153638040704040707070704040413141415182a162314142521212d2a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d0a16043334352e292b2c042d21210202072d2d042d04332435210a0a2d040707070404131424242425282a262324242536182d2a2a2a2a2a2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c07042637380a2c2e292b0404042121210707042d2d2d041835073e0a0a0a080707040404232424242416282a263334342521382d2a2a2a2a2a04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d04261d10112c2e292b0404043131310404040404043638213c2111111208072c041638232424242436382a3630313131212a2a2a2d07070404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d07362c21212208292b2c07042d2d072d2d2d2d2d2d040421213e0718220804042d3621333434343511212a2a2a2a2a2a2a2a2d2d2121210704000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c042d2d2c21022208292b2c36382d0707192a3a3a2a1b040709200707282208042c0407210a0a0a0a0a21222a2a2a2a2a2a2a2d2d212121210707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c042d042c21212128292b07103d3e27272a2b0b0b292a040409203637382208042d2d102121212121213132070707072a2a2a2d21212121210404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d07040421212138292b2c202122042e292b2009292b2d0409200221212208042c10212121212121210404070707042a2a2d2d21212121182104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c072d043e21211e192a2b2c202122042e2a2b0209292a042d093031313132082d2d2121212121212107072d07072d042a2d2d2d21212136382104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26183c3e2d213d3e2a062b2c202122042e292b3009292a040409210b0b0b0b042d2c3131313121212132042d070104042d2d212121212121212104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26380b0b2d042d072a2a2b07202132042e2a2a1a1a2a2a2a2a04040404042d04042c0a0a0707212132042d2d072d2d2d2d2d072d2d2d2d2d2d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c0411113d042d072a2a2b2c303204042e29062a2a2a2a2a2a2a2a04042d040404320a0a30212121042d2d04042d072d2d2d2d2d182d2d072d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c042121361807192a2a2b2c040404012e392a2a2a2a2a2a2a2a2a2a042d0401040a0a0a0a212121042d0407042d2d2d072d2d363813152d072d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
161820210436072a2a2a2b07040704072e07392a2a2a3b2a2a2a2d0404040404040a0a0a0a162d2d04040704042d2d2d2d07210821333516182d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
03030000356603c6603d6603f6603f6603e6603b65038640376403464000600006000060000600006000060000600006000060000600006000060000600000000000000000000000000000000000000000000000
1d0800001847000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0008000017450004000f4500040004400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
6b0e00001d3541d3521d3521d352213522135221352213521c352183521c352013002135221352213522a3001f3521b3521a3521f3521f3521f3521f3521f3521c3001b3521b3521e35220300213522135221355
250c0000191501d150201502515025150251502215022150251502515025150251500010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
022000001885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
