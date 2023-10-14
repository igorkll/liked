local holo = ...
for ix = 1, hx do
    for iz = 1, hz do
        holo.fill(ix, iz, 1, hy, ix == 1 and 1 or 0)
    end
end