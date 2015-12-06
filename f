local x = ...

if x == nil then
  print("USAGE: s <distance>")
  return
end

for i=1,x do
  if not turtle.forward() then
    print("Cannot advance.")
    return nil
  end
end
