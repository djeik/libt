local direction = ...
local d = {
  l = turtle.turnLeft,
  r = turtle.turnRight,
  a = function()
    turtle.turnRight()
    turtle.turnRight()
  end
}
d[direction]()
  