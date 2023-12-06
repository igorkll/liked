import cv2
import os
import sys
import traceback
import math
from collections import Counter
import random

"""
colors = [
    0xffffff,
    0xffcc33,
    0xcc66cc,
    0x6699ff,
    0xffff33,
    0x33cc33,
    0xff6699,
    0x333333,
    0xcccccc,
    0x336699,
    0x9933cc,
    0x333399,
    0x663300,
    0x336600,
    0xff3333,
    0x000000
]
"""

colors = [
    0xffffff,
    0xF2B233,
    0xE57FD8,
    0x99B2F2,
    0xDEDE6C,
    0x7FCC19,
    0xF2B2CC,
    0x4C4C4C,
    0x999999,
    0x4C99B2,
    0xB266E5,
    0x3366CC,
    0x7F664C,
    0x57A64E,
    0xCC4C4C,
    0x000000
]

colors3t = [0x000000, 0x000040, 0x000080, 0x0000BF, 0x0000FF, 0x002400, 0x002440, 0x002480, 0x0024BF, 0x0024FF, 0x004900, 0x004940, 0x004980, 0x0049BF, 0x0049FF, 0x006D00, 0x006D40, 0x006D80, 0x006DBF, 0x006DFF, 0x009200, 0x009240, 0x009280, 0x0092BF, 0x0092FF, 0x00B600, 0x00B640, 0x00B680, 0x00B6BF, 0x00B6FF, 0x00DB00, 0x00DB40, 0x00DB80, 0x00DBBF, 0x00DBFF, 0x00FF00, 0x00FF40, 0x00FF80, 0x00FFBF, 0x00FFFF, 0x0F0F0F, 0x1E1E1E, 0x2D2D2D, 0x330000, 0x330040, 0x330080, 0x3300BF, 0x3300FF, 0x332400, 0x332440, 0x332480, 0x3324BF, 0x3324FF, 0x334900, 0x334940, 0x334980, 0x3349BF, 0x3349FF, 0x336D00, 0x336D40, 0x336D80, 0x336DBF, 0x336DFF, 0x339200, 0x339240, 0x339280, 0x3392BF, 0x3392FF, 0x33B600, 0x33B640, 0x33B680, 0x33B6BF, 0x33B6FF, 0x33DB00, 0x33DB40, 0x33DB80, 0x33DBBF, 0x33DBFF, 0x33FF00, 0x33FF40, 0x33FF80, 0x33FFBF, 0x33FFFF, 0x3C3C3C, 0x4B4B4B, 0x5A5A5A, 0x660000, 0x660040, 0x660080, 0x6600BF, 0x6600FF, 0x662400, 0x662440, 0x662480, 0x6624BF, 0x6624FF, 0x664900, 0x664940, 0x664980, 0x6649BF, 0x6649FF, 0x666D00, 0x666D40, 0x666D80, 0x666DBF, 0x666DFF, 0x669200, 0x669240, 0x669280, 0x6692BF, 0x6692FF, 0x66B600, 0x66B640, 0x66B680, 0x66B6BF, 0x66B6FF, 0x66DB00, 0x66DB40, 0x66DB80, 0x66DBBF, 0x66DBFF, 0x66FF00, 0x66FF40, 0x66FF80, 0x66FFBF, 0x66FFFF, 0x696969, 0x787878, 0x878787, 0x969696, 0x990000, 0x990040, 0x990080, 0x9900BF, 0x9900FF, 0x992400, 0x992440, 0x992480, 0x9924BF, 0x9924FF, 0x994900, 0x994940, 0x994980, 0x9949BF, 0x9949FF, 0x996D00, 0x996D40, 0x996D80, 0x996DBF, 0x996DFF, 0x999200, 0x999240, 0x999280, 0x9992BF, 0x9992FF, 0x99B600, 0x99B640, 0x99B680, 0x99B6BF, 0x99B6FF, 0x99DB00, 0x99DB40, 0x99DB80, 0x99DBBF, 0x99DBFF, 0x99FF00, 0x99FF40, 0x99FF80, 0x99FFBF, 0x99FFFF, 0xA5A5A5, 0xB4B4B4, 0xC3C3C3, 0xCC0000, 0xCC0040, 0xCC0080, 0xCC00BF, 0xCC00FF, 0xCC2400, 0xCC2440, 0xCC2480, 0xCC24BF, 0xCC24FF, 0xCC4900, 0xCC4940, 0xCC4980, 0xCC49BF, 0xCC49FF, 0xCC6D00, 0xCC6D40, 0xCC6D80, 0xCC6DBF, 0xCC6DFF, 0xCC9200, 0xCC9240, 0xCC9280, 0xCC92BF, 0xCC92FF, 0xCCB600, 0xCCB640, 0xCCB680, 0xCCB6BF, 0xCCB6FF, 0xCCDB00, 0xCCDB40, 0xCCDB80, 0xCCDBBF, 0xCCDBFF, 0xCCFF00, 0xCCFF40, 0xCCFF80, 0xCCFFBF, 0xCCFFFF, 0xD2D2D2, 0xE1E1E1, 0xF0F0F0, 0xFF0000, 0xFF0040, 0xFF0080, 0xFF00BF, 0xFF00FF, 0xFF2400, 0xFF2440, 0xFF2480, 0xFF24BF, 0xFF24FF, 0xFF4900, 0xFF4940, 0xFF4980, 0xFF49BF, 0xFF49FF, 0xFF6D00, 0xFF6D40, 0xFF6D80, 0xFF6DBF, 0xFF6DFF, 0xFF9200, 0xFF9240, 0xFF9280, 0xFF92BF, 0xFF92FF, 0xFFB600, 0xFFB640, 0xFFB680, 0xFFB6BF, 0xFFB6FF, 0xFFDB00, 0xFFDB40, 0xFFDB80, 0xFFDBBF, 0xFFDBFF, 0xFFFF00, 0xFFFF40, 0xFFFF80, 0xFFFFBF, 0xFFFFFF]

def convert_rgb_to_24bit(r, g, b):
    # Объединение значений B, G и R в 24-битное число
    rgb_value = (r << 16) | (g << 8) | b
    return rgb_value

def convert_to_24bit(col):
    return convert_rgb_to_24bit(col[2], col[1], col[0])

def make_braille(tbl):
    a, b, c, d, e, f, g, h = tbl[0][0], tbl[1][0], tbl[2][0], tbl[3][0], tbl[0][1], tbl[1][1], tbl[2][1], tbl[3][1]
    return chr(10240 + 128*h + 64*d + 32*g + 16*f + 8*e + 4*c + 2*b + a)

def find_closest_color(target_color, color_array):
    # Извлечение компонент цвета цели (R, G, B)
    target_r = (target_color >> 16) & 0xFF
    target_g = (target_color >> 8) & 0xFF
    target_b = target_color & 0xFF

    closest_index = None
    closest_distance = float('inf')

    # Перебор всех цветов в массиве
    for i, color in enumerate(color_array):
        # Извлечение компонент цвета из массива (R, G, B)
        array_r = (color >> 16) & 0xFF
        array_g = (color >> 8) & 0xFF
        array_b = color & 0xFF

        # Вычисление евклидова расстояния между цветами
        distance = ((target_r - array_r) ** 2 +
                    (target_g - array_g) ** 2 +
                    (target_b - array_b) ** 2) ** 0.5

        # Обновление ближайшего цвета, если найден более близкий
        if distance < closest_distance:
            closest_distance = distance
            closest_index = i

    return closest_index

def find_dominant_colors(color_matrix):
    # Вытягиваем все цвета из матрицы и конвертируем их в кортежи (B, G, R)
    colors = [tuple(color) for row in color_matrix for color in row]

    # Подсчет частоты каждого цвета
    color_counter = Counter(colors)

    # Находим два самых преобладающих цвета
    dominant_colors = color_counter.most_common(2)

    return dominant_colors

def packNums(num1, num2):
    # Проверка, что числа находятся в диапазоне от 0 до 15
    if not (0 <= num1 <= 15) or not (0 <= num2 <= 15):
        raise ValueError("Числа должны быть в диапазоне от 0 до 15")

    # Упаковка двух чисел в один байт
    return (num1 << 4) | num2

def color_similarity(color1, color2, target_color):
    def euclidean_distance(c1, c2):
        return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))

    distance1 = euclidean_distance(color1, target_color)
    distance2 = euclidean_distance(color2, target_color)

    total_distance = distance1 + distance2

    # Предотвращение деления на ноль
    if total_distance == 0:
        return 0.5

    coefficient = 1 - (distance1 / total_distance)
    return coefficient

def hex_to_rgb(hex_color):
    # Получаем отдельные компоненты цвета
    red = (hex_color >> 16) & 0xFF
    green = (hex_color >> 8) & 0xFF
    blue = hex_color & 0xFF

    return red, green, blue

def color_similarity2(color1, color2):
    # Извлекаем компоненты цвета
    r1, g1, b1 = color1
    r2, g2, b2 = color2

    # Вычисляем евклидово расстояние между компонентами цвета
    distance = math.sqrt((r1 - r2)**2 + (g1 - g2)**2 + (b1 - b2)**2)

    # Нормализуем расстояние к диапазону [0, 1]
    normalized_distance = distance / math.sqrt(255**2 + 255**2 + 255**2)

    # Чем меньше нормализованное расстояние, тем более похожи цвета
    similarity = 1 - normalized_distance
    return similarity

def parse_image_pixelwise(image_path):
    # Загрузка изображения
    image = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)

    # Проверка на успешную загрузку изображения
    if image is None:
        print(f"Не удалось загрузить изображение: {image_path}")
        return

    # Получение размеров изображения
    height, width, channels = image.shape

    # Генерация выходного пути на основе входного с изменением расширения на "t2p"
    output_path, _ = os.path.splitext(image_path)
    output_path += ".t2p"

    # Попиксельный обход и обработка изображения
    with open(output_path, 'wb') as file:
        block_width = 2
        block_height = 4

        file.write((width // block_width).to_bytes(1, 'little'))
        file.write((height // block_height).to_bytes(1, 'little'))
        file.write(b"3\0\0\0\0\0\0\0")

        for y in range(0, height - block_height + 1, block_height):
            for x in range(0, width - block_width + 1, block_width):
                # Извлечение блока изображения размером 4x2
                block = image[y:y + block_height, x:x + block_width]
                # print(make_braille(outputArray), end='')

                dominant_colors = find_dominant_colors(block)

                print(dominant_colors)
                back, backcol, backnonused = find_closest_color(convert_to_24bit(dominant_colors[0][0]), colors), dominant_colors[0][0], False
                fore, forecol, forenonused = 0, (0, 0, 0, 255), False
                if len(dominant_colors) > 1:
                    fore = find_closest_color(convert_to_24bit(dominant_colors[1][0]), colors)
                    forecol = dominant_colors[1][0]
                else:
                    fore = back
                    forecol = backcol

                bindColors = False

                if backcol[3] < 200:
                    backnonused = True
                    back = 3

                if forecol[3] < 200:
                    forenonused = True
                    fore = 3

                if backnonused and forenonused:
                    back = 0
                    fore = 0
                elif back == 0 and fore == 0:
                    fore = 15

                fullBack = find_closest_color(convert_to_24bit(backcol), colors3t)
                fullFore = find_closest_color(convert_to_24bit(forecol), colors3t)
                if fullBack == fullFore:
                    bindColors = True
                    fullFore = 55

                outputArray = []
                for line in block:
                    outputArray.append([])
                    for color in line:
                        # formattedColor = convert_rgb_to_24bit(color[2], color[1], color[0])
                        if bindColors:
                            outputArray[-1].append(False)
                        elif forenonused and backnonused:
                            outputArray[-1].append(False)
                        elif forenonused:
                            # outputArray[-1].append(color_similarity2((hex_to_rgb(colors[back])), (color[2], color[1], color[0])) > 0.5)
                            outputArray[-1].append(color[3] >= 200)
                        elif backnonused:
                            # outputArray[-1].append(color_similarity2((hex_to_rgb(colors[fore])), (color[2], color[1], color[0])) > 0.5)
                            outputArray[-1].append(color[3] < 200)
                        else:
                            outputArray[-1].append(color_similarity((hex_to_rgb(colors[back])), (hex_to_rgb(colors[fore])), (color[2], color[1], color[0])) > 0.5)

                char = make_braille(outputArray)
                print(back, fore, char)
                file.write(bytes([packNums(back, fore)]))
                file.write(bytes([fullBack]))
                file.write(bytes([fullFore]))
                file.write(bytes([len(char.encode('utf-8'))]))
                file.write(char.encode('utf-8'))
            # print("")

if __name__ == "__main__":
    try:
        image_path = False
        if len(sys.argv) < 2:
            # image_path = "D:\\Users\\user\\Documents\\GitHub\liked\\tools\\test.png"
            pass
        else:
            image_path = sys.argv[1]
        parse_image_pixelwise(image_path)

    except Exception as e:
        # Обработка исключения и вывод сообщения
        print(f"Произошла ошибка: {e}")
        traceback.print_exc()
        while True: pass