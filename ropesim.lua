-- Lua implementation of Sebastian Lague's rope simulation algorithm --

local iterations = 500
local gravity = -1

local function npoint(x, y)
  return {pos = {x or 0, y or 0}, ppos = {x or 0, y or 0}, locked = false}
end

local function nstick(pa, pb, length)
  return {pa = pa, pb = pb, length = length}
end

local points = { }
local sticks = { }

local function normalize(x, y)
  local length = math.sqrt(x^2 + y^2)
  if length == 1 then return x, y end
  if length > 1e-05 then return x / length, y / length end
  return 0, 0
end

-- randomize stick order
local order = {}

local function shuffle(tbl)
  for i=1, #sticks, 1 do order[i] = i end

  local left = #tbl

  while left > 1 do
    local ridx = math.random(1, left)
    local chosen = order[ridx]

    left = left - 1
    order[ridx], order[left] = order[left], order[ridx]
  end
end

local simtime = 1/20
local function simulate()
  shuffle(order)
  for i=1, #points, 1 do
    local p = points[i]
    if not p.locked then
      local ox, oy = p.pos[1], p.pos[2]
      p.pos[1] = p.pos[1] + p.pos[1] - p.ppos[1]
      p.pos[2] = p.pos[2] + p.pos[2] - p.ppos[2]
      p.pos[2] = p.pos[2] - gravity * simtime^2
      p.ppos[1], p.ppos[2] = ox, oy
    end
  end

  for i=1, iterations, 1 do
    for i=1, #sticks, 1 do
      local s = sticks[order[i]]
      local scenter = {
        (s.pa.pos[1] + s.pb.pos[1]) / 2,
        (s.pa.pos[2] + s.pb.pos[2]) / 2
      }
      local sdx, sdy = normalize(
        s.pa.pos[1] - s.pb.pos[1],
        s.pa.pos[2] - s.pb.pos[2]
      )
  
      if not s.pa.locked then
        s.pa.pos[1] = scenter[1] + sdx * s.length / 2
        s.pa.pos[2] = scenter[2] + sdy * s.length / 2
      end
      
      if not s.pb.locked then
        s.pb.pos[1] = scenter[1] - sdx * s.length / 2
        s.pb.pos[2] = scenter[2] - sdy * s.length / 2
      end
    end
  end
end

local sel = 0
local sim, lcsel = false, false
local function draw()
  term.setFrozen(true)
  term.clear()
  for i=1, #sticks, 1 do
    local l = sticks[i]
    local p = l.pa
    local pp = l.pb
    paintutils.drawLine(p.pos[1], p.pos[2], pp.pos[1], pp.pos[2],
      colors.white)
  end
  for i=1, #points, 1 do
    local p = points[i]
    if p.locked then
      term.drawPixels(p.pos[1]-2, p.pos[2]-2, colors.red, 4, 4)
    else
      term.drawPixels(p.pos[1]-2, p.pos[2]-2,
        lcsel and i == sel and colors.lime or colors.white, 4, 4)
    end
  end
  term.setFrozen(false)
end

term.setGraphicsMode(true)
term.clear()
local selpt = points[#points]
while true do
  draw()
  if sim then
    simulate()
    os.sleep(0)
  else
    term.drawPixels(1, 1, colors.red, 10, 10)
    local sig = table.pack(os.pullEvent())
    if sig[1] == "mouse_click" then
      local b, x, y = sig[2], sig[3], sig[4]
      if x < 12 and y < 12 then
        sim = true
      else
        local found = false
        for i=1, #points, 1 do
          local p = points[i]
          if x >= p.pos[1]-2 and x <= p.pos[1]+2
         and y >= p.pos[2]-2 and y <= p.pos[2]+2 then
            found = true
            if b == 2 then
              p.locked = not p.locked
            elseif i ~= sel and lcsel then
              lcsel = false
              local ospt = selpt
              selpt = p
              local lp, np = ospt, selpt
              sticks[#sticks+1] = nstick(ospt, selpt,
                math.floor(
                  math.sqrt(
                    math.abs(lp.pos[1]-np.pos[1])^2 +
                    math.abs(lp.pos[2]-np.pos[2])^2)
                  )
                )
              sel = 0
            else
              lcsel = true
              selpt = p
              sel = i
            end
            break
          end
        end
        if not found then
          local lp = selpt or points[#points]
          points[#points+1] = npoint(x,y)
          local np = points[#points]
          if lcsel and lp then
            sticks[#sticks+1] = nstick(lp, np,
              math.floor(
                math.sqrt(
                  math.abs(lp.pos[1]-np.pos[1])^2 +
                  math.abs(lp.pos[2]-np.pos[2])^2)
                )
              )
            lcsel = false
          else
            selpt = np
          end
        end
      end
    end
  end
end
