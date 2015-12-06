local x = ...

if x == nil then
  print("USAGE: s <distance>")
  return
end

for i=1,x do
  while turtle.detect() do
    turtle.dig()
  end
  turtle.digDown()
  if not turtle.forward() then
    print("Insufficient fuel. Stopping.")
    return nil
  end
end