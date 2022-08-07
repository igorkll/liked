local posX, posY, sizeX, sizeY, cx, cy = ...
while (posX + sizeX) - 1 > cx do posX = posX - 1 end
while (posY + sizeY) - 1 > cy do posY = posY - 1 end
return posX, posY