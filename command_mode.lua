package.path = package.path .. ";C:/Users/seven_000/zerobrane/OpenPrograms/?.lua"
local rs = require("robot_scripts")

print("Enter direction: ")
dir = tonumber(io.read())
print("Enter x pos: ")
x = tonumber(io.read())
print("Enter y pos: ")
y = tonumber(io.read())
rbt = rs.Robit:new{dir=dir, pos={x=x, y=y}}
while true do
  print("Awaiting command: ")
  s = io.read()
  print(s)
  if s == "patrol" then
    print("Enter patrol start pos x: ")
    x = tonumber(io.read())
    print("Enter patrol start pos y: ")
    y = tonumber(io.read())
    startpos = {x=x, y=y}
    print("Enter patrol length (x): ")
    l = tonumber(io.read())
    print("Enter patrol width (y): ")
    w = tonumber(io.read())
    area = {l=l, w=w}
    print("Mode (trees, or none)")
    mode = io.read()
    print("Enter patrol count (0 for infinite): ")
    n = tonumber(io.read())
    rbt:patrol{startpos=startpos, area=area, n=n, mode=mode}
  end
  if s == "moveto" then
    print("Enter target x: ")
    x = tonumber(io.read())
    print("Enter target y: ")
    y = tonumber(io.read())
    pos = {x=x, y=y}
    rbt:moveto(pos)
  end
  if s == "choptree" then
    print("Enter tree x: ")
    x = tonumber(io.read())
    print("Enter tree y: ")
    y = tonumber(io.read())
    rbt.treepos = {x=x, y=y}
    while rbt.treepos do
      rbt:choptree()
    end
  end
end