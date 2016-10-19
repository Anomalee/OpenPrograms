package.path = package.path .. ";C:/Users/seven_000/zerobrane/OpenPrograms/?.lua"
local rs = require("robot_scripts")

print("Enter direction: ")
dir = io.read("*n")
print("Enter x pos: ")
x = io.read("*n")
print("Enter y pos: ")
y = io.read("*n")
rbt = rs.Robit:new{dir=dir, pos={x=x, y=y}}
while true do
  print("Awaiting command: ")
  s = io.read()
  if s == "patrol" then
    print("Enter patrol start pos x: ")
    x = io.read("*n")
    print("Enter patrol start pos y: ")
    y = io.read("*n")
    print("Enter patrol length (x): ")
    l = io.read("*n")
    print("Enter patrol width (y): ")
    w = io.read("*n")
    area = {l=l, w=w}
    print("Enter patrol count (0 for infinite): ")
    n = io.read("*n")
    rbt:patrol{area=area, n=n}
  end
end