local maintable, newtable = ...
for k, v in pairs(maintable) do
    maintable[k] = nil
end
for k, v in pairs(newtable) do
    maintable[k] = v
end