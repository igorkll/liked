local holo = ...
for ix = 1, hx do
    for iz = 1, hz do
        holo.fill(ix, iz, 1, hy, col(ix == 1 and 2 or 1))
    end
end