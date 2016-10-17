Move = {
        parent,
        pos,
        children,
        endpoints,
        deadends
        }

function Move:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Move:addchild (child)
  self.children[#self.children+1] = child
  self:addendpoint(child.pos)
end

function Move:addendpoint (endpoint)
  self.endpoints[#self.endpoints+1] = endpoint
  if self.parent then
    self.parent:addendpoint(endpoint)
  end
end

function Move:hasendpoint (point)
  for _, p in pairs(self.endpoints) do
    if p.x == point.x and p.y == point.y then
      return true
    end
  end
  return false
end

Robit = {
          pos,
          height=1,
          direction,
          startmove,
          prevmove,
          targetpos,
          treefound,
          treeheight,
          patrolpath,
          pathindex
        }

function Robit:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Robit:moveforward ()
  if self.direction == 0 then
    self.pos.y = self.pos.y+1
  elseif self.direction == 1 then
    self.pos.x = self.pos.x-1
  elseif self.direction == 2 then
    self.pos.y = self.pos.y-1
  else
    self.pos.x = self.pos.x+1
  end
  robot.forward()
end

function Robit:moveup ()
  self.height = self.height+1
  robot.up()
end

function Robit:movedown ()
  self.height = self.height-1
  robot.down()
end

function Robit:turn_around ()
  self.direction = (self.direction+2)%4
  robot.turnAround()
end

function Robit:turn_right ()
  self.direction = (self.direction+1)%4
  robot.turnRight()
end

function Robit:turn_left ()
  self.direction = (self.direction-1)%4
  robot.turnLeft()
end

function Robit:turn_todir (targetdir)
  if not self.direction == targetdir then
    if (self.direction+2)%4 == targetdir then
      self:turn_around()
    elseif (self.direction+1)%4 == targetdir then
      self:turn_right()
    else
      self:turn_left()
    end
  end
end

function Robit:turn_topos (pos)
  targetdir = getdir_topos(self.pos, pos)
  self:turn_todir(targetdir)
end

function Robit:getforwardpos ()
  x = self.pos.x
  y = self.pos.y
  if self.direction == 0 then
    y = y+1
  elseif self.direction == 1 then
    x = x-1
  elseif self.direction == 2 then
    y = y-1
  else
    x = x+1
  end
  return {x=x, y=y}
end

function Robit:navigate(targetpos)
  if self.pos == targetpos and self.height == 1 then
    return True
  end
  if self.height > 1 then
    self:movedown()
    return
  end
  if not targetpos == self.targetpos or not self.prevmove then
    thismove = Move:new{parent=self.prevmove, pos=self.pos}
    self.startmove = thismove
    self.prevmove = nil
    self.targetpos = targetpos
  else
    if self.pos == self.prevmove.pos then
      thismove = self.prevmove
      self.prevmove = self.prevmove.parent
    else
      thismove = Move:new{parent=self.prevmove, pos=self.pos}
      self.prevmove:addchild(thismove)
    end
  end
  choices = {
              addpos(self.pos, {x=1, y=0}),
              addpos(self.pos, {x=-1, y=0}),
              addpos(self.pos, {x=0, y=1}),
              addpos(self.pos, {x=0, y=-1})
              }
  availchoices = {}
  choicedists = {}
  for i, c in pairs(choices) do
    if self.startmove.hasendpoint(c) then
      availchoices[#availchoices+1] = c
      choicedist[#choicedist] = getdist(targetpos, c)
    end
  end
  while #availchoices > 0 do
    choice = getindex(choicedist, math.min(choicedist))
    self:turntopoint(availchoices[choice])
    if robot.detect() then
      availchoices[choice] = nil
      choicedist[choice] = nil
    else
      break
    end
  end
  if #availchoices == 0 then
    self:turntopoint(self.prevmove.pos)
    thismove = self.prevmove
  end
  self:moveforward()
  self.prevmove = thismove
end

function Robit:patrol (arg)
  if self.patrolpath == nil then
    if arg.startpos == nil then
      startpos = self.pos
    end
    if arg.area == nil then
      area = {w=1, h=1}
    end
    self.patrolpath = self:buildpatrolpath(startpos, area)
    self.pathindex = 1
  end
  while true do
    if pointcompare(self.pos, self.patrolpath[1]) then
      self.pathindex = (self.pathindex)%(#self.patrolpath)+1
    end
    self:navigate(self.patrolpath[self.pathindex])
  end
end

function Robit:buildpatrolpath (startpos, area)
  x0 = startpos.x
  y0 = startpos.y
  w = area.w
  h = area.h
  if w == 0 or h == 0 then
    return None
  end
  if w < 0 then
      grid_xrange = {min=x0+w+1, max=x0}
  else
      grid_xrange = {min=x0, max=x0+w-1}
  end
  if h < 0 then
      grid_yrange = {min=y0+h+1, max=y0}
  else
      grid_yrange = {min=y0, max=y0+h-1}
  end
  path = {}
  heading = {EW=sign(w), NS=sign(h)}
  if w >= h then
      pos = {para=x0, perp=y0+sign(h)}
      path[1] = {x=pos.para, y=pos.perp}
      patroldir = 'EW'
      gridrange_para = grid_xrange
      gridrange_perp = grid_yrange
      heading_para = heading.EW
      heading_perp = heading.NS
  else
      pos = {perp=x0+sign(w), para=y0}
      path[1] = {x=pos.perp, y=pos.para}
      patroldir = 'NS'
      gridrange_para = grid_yrange
      gridrange_perp = grid_xrange
      heading_para = heading.NS
      heading_perp = heading.EW
  end
  while true do
    if (pos.para+heading_para > gridrange_para.max) or 
    (pos.para+heading_para < gridrange_para.min) then
      heading_para = heading_para*(-1)
      if (pos.perp+heading_perp <= gridrange_perp.min) or
      (pos.perp+heading_perp >= gridrange_perp.max) then
        heading_perp = heading_perp*(-1)
      end
      for i=1, 3 do
        if (pos.perp+heading_perp <= gridrange_perp.min) or
        (pos.perp+heading_perp >= gridrange_perp.max) then
          break
        else
          pos.perp = pos.perp+heading_perp
          if patroldir == 'EW' then
            path[#path+1] = {x=pos.para, y=pos.perp}
          else
            path[#path+1] = {x=pos.perp, y=pos.para}
          end
        end
      end
    else
      pos.para = pos.para+heading_para
      if patroldir == 'EW' then
        path[#path+1] = {x=pos.para, y=pos.perp}
      else
        path[#path+1] = {x=pos.perp, y=pos.para}
      end
    end
    if pointcompare(path[#path], path[1]) then
      if #path > 1 then
        path[#path] = nil
      end
      break
    end
  end
  return path
end

function pointcompare (p1, p2)
  return (p1.x == p2.x) and (p1.y == p2.y)
end

function addpos (p1, p2)
  return {x=p1.x+p2.x, y=p1.y+p2.y}
end

function getdist (p1, p2)
  return ((p2.x-p1.x)^2 + (p2.y-p1.y)^2)^0.5
end

function sign (n)
  if n < 0 then
    return -1
  elseif n > 0 then
    return 1
  else
    return 0
  end
end

function switch (val, choices, results)
  for i, v in pairs(choices) do
    if val == v then
      return results[i]
    end
  end
  error('val not in choices')
end

function getindex (t, val)
  for i, v in pairs(t) do
    if val == v then
      return i
    end
  end
  error('Value not found in table.')
end

function getdir_topos (p1, p2)
  xdist = p2[1]-p1[1]
  ydist = p2[2]-p1[2]
  if xdist == 0 and ydist == 0 then
    return false
  end
  if math.abs(xdist) > math.abs(ydist) then
    if xdist > 0 then
      return 3
    else
      return 1
    end
  else
    if ydist > 0 then
      return 0
    else
      return 2
    end
  end
end
