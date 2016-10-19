-- 0 = south
-- 1 = west
-- 2 = north
-- 3 = east

package.path = package.path .. ";C:/Users/seven_000/zerobrane/OpenPrograms/?.lua"
local robot = require("robot")
local Me = {}
local clock = os.clock

Me.Move = {
            parent,
            pos,
            children,
            endpoints,
            deadends
            }

function Me.Move:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Me.Move:addchild (child)
  self.children[#self.children+1] = child
  self:addendpoint(child.pos)
end

function Me.Move:addendpoint (endpoint)
  self.endpoints[#self.endpoints+1] = endpoint
  if self.parent then
    self.parent:addendpoint(endpoint)
  end
end

function Me.Move:hasendpoint (point)
  if not self.endpoints then
    return false
  end
  for _, p in pairs(self.endpoints) do
    if p.x == point.x and p.y == point.y then
      return true
    end
  end
  return false
end

Me.Robit = {
          pos,
          height=1,
          dir,
          startmove,
          prevmove,
          targetpos,
          treepos,
          treeheight,
          patrolpath,
          pathindex
        }

function Me.Robit:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Me.Robit:moveforward ()
  if self.dir == 0 then
    self.pos.y = self.pos.y+1
  elseif self.dir == 1 then
    self.pos.x = self.pos.x-1
  elseif self.dir == 2 then
    self.pos.y = self.pos.y-1
  else
    self.pos.x = self.pos.x+1
  end
  robot.forward()
end

function Me.Robit:moveup ()
  self.height = self.height+1
  robot.up()
end

function Me.Robit:movedown ()
  self.height = self.height-1
  robot.down()
end

function Me.Robit:turn_around ()
  self.dir = (self.dir+2)%4
  robot.turnAround()
end

function Me.Robit:turn_right ()
  self.dir = (self.dir+1)%4
  robot.turnRight()
end

function Me.Robit:turn_left ()
  self.dir = (self.dir-1)%4
  robot.turnLeft()
end

function Me.Robit:turn_todir (targetdir)
  if not (self.dir == targetdir) then
    if (self.dir+2)%4 == targetdir then
      self:turn_around()
    elseif (self.dir+1)%4 == targetdir then
      self:turn_right()
    else
      self:turn_left()
    end
  else
  end
end

function Me.Robit:turn_topos (pos)
  targetdir = getdir_topos(self.pos, pos)
  self:turn_todir(targetdir)
end

function Me.Robit:getforwardpos ()
  x = self.pos.x
  y = self.pos.y
  if self.dir == 0 then
    y = y+1
  elseif self.dir == 1 then
    x = x-1
  elseif self.dir == 2 then
    y = y-1
  else
    x = x+1
  end
  return {x=x, y=y}
end

function Me.Robit:moveto (targetpos)
  while not pointcompare(self.pos, targetpos) do
    self:navigate(targetpos)
  end
end

function Me.Robit:navigate (targetpos)
  if pointcompare(self.pos, targetpos) and self.height == 1 then
    return True
  end
  if self.height > 1 then
    self:movedown()
    return
  end
  if not pointcompare(targetpos, self.targetpos) or not self.prevmove then
    thismove = Me.Move:new{parent=self.prevmove, pos=self.pos}
    self.startmove = thismove
    self.prevmove = nil
    self.targetpos = targetpos
  else
    if pointcompare(self.pos, self.prevmove.pos) then
      thismove = self.prevmove
      self.prevmove = self.prevmove.parent
    else
      thismove = Me.Move:new{parent=self.prevmove, pos=self.pos}
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
    if not self.startmove.hasendpoint(c) then
      availchoices[#availchoices+1] = c
      choicedists[#choicedists+1] = getdist(targetpos, c)
    end
  end
  while #availchoices > 0 do
    choice = getindex(choicedists, math.min(table.unpack(choicedists)))
    self:turn_topos(availchoices[choice])
    print('choice', availchoices[choice].x, availchoices[choice].y)
    if robot.detect(availchoices[choice]) then
      table.remove(availchoices, choice)
      table.remove(choicedists, choice)
    else
      break
    end
  end
  if #availchoices == 0 then
    if self.prevmove then
      self:turn_topos(self.prevmove.pos)
      thismove = self.prevmove
    else
      return
    end
  end
  self:moveforward()
  self.prevmove = thismove
end

function Me.Robit:patrol (arg)
  local function inpatrolarea(pos)
    xrange = {startpos.x, startpos.x+l}
    yrange = {startpos.y, startpos.y+w}
    if pos.x >= min(table.unpack(xrange)) and 
    pos.x <= max(table.unpack(xrange)) then
      if pos.y >= min(table.unpack(yrange)) and
      pos.y <= max(table.unpack(yrange)) then
        return true
      else
        return false
      end
    else
      return false
    end
  end
  if self.patrolpath == nil then
    if arg.startpos == nil then
      startpos = self.pos
    else
      startpos = arg.startpos
    end
    if arg.area == nil then
      area = {l=1, w=1}
    else
      area = arg.area
    end
    self.patrolpath = self:buildpatrolpath(startpos, area)
    self.pathindex = 1
  end
  if arg.n ~= nil then
    numpatrols = 0
    maxpatrols = arg.n
  end
  while true do
    skippatrol = false
    if arg.mode == 'trees' then
      if not self.treepos then
        tree = self:checkfortrees()
        if tree then
          self.treepos = tree
        end
      end
      if self.treepos then
        self:choptree()
        skippatrol = true
      end
    end
    if not skippatrol then
      if pointcompare(self.pos, self.patrolpath[self.pathindex]) then
        if numpatrols and self.pathindex == 1 then
          if numpatrols >= maxpatrols then
            break
          end
          numpatrols = numpatrols+1
        end
        self.pathindex = (self.pathindex)%(#self.patrolpath)+1
      end
      self:navigate(self.patrolpath[self.pathindex])
    end
  end
  self.patrolpath = nil
end

function Me.Robit:buildpatrolpath (startpos, area)
  x0 = startpos.x
  y0 = startpos.y
  l = area.l
  w = area.w
  if l == 0 or w == 0 then
    return None
  end
  if l < 0 then
      grid_xrange = {min=x0+l+1, max=x0}
  else
      grid_xrange = {min=x0, max=x0+l-1}
  end
  if w < 0 then
      grid_yrange = {min=y0+w+1, max=y0}
  else
      grid_yrange = {min=y0, max=y0+w-1}
  end
  path = {}
  heading = {EW=sign(l), NS=sign(w)}
  if l >= w then
      pos = {para=x0, perp=y0+sign(w)}
      path[1] = {x=pos.para, y=pos.perp}
      patroldir = 'EW'
      gridrange_para = grid_xrange
      gridrange_perp = grid_yrange
      heading_para = heading.EW
      heading_perp = heading.NS
  else
      pos = {perp=x0+sign(l), para=y0}
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

function Me.Robit:choptree ()
  if not getdist(self.pos, self.treepos) == 1 then
    self:navigateto(closestadjacent(self.pos, self.treepos))
  elseif self.treeheight == nil then
    self:turn_topos(self.treepos)
    if self.isfacingtree() then
      if robot.detectUp() then
        robot.swingUp()
      end
      self:moveup()
    else
      self.treeheight = self.height-1
    end
  elseif self.height > self.treeheight then
    self:movedown()
  elseif self.height < self.treeheight then
    self:moveup()
  else
    self:turn_topos(self.treepos)
    if self:isfacingtree() then
      self.swing()
    end
    self.treeheight = self.treeheight-1
  end
  if self.treeheight == 0 then
    self.treeheight = nil
    self.treepos = nil
  end
end
    
function Me.Robit:isfacingtree()
  robot.select(1)
  return robot.compare()
end
        
function Me.Robit:checkfortrees ()
  if self:isfacingtree() then
    return self:getforwardpos()
  end
  for i=1,4 do
    if self.isfacingtree() then
      return self:getforwardpos()
    end
    self:turn_right()
  return nil
end

function pointcompare (p1, p2)
  if p1 == nil or p2 == nil then
    return false
  end
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
  xdist = p2.x-p1.x
  ydist = p2.y-p1.y
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

function sleep(n)
  local t0 = clock()
  while clock()-t0 <= n do end
end

return Me