import cv2
import os
import sys
import traceback

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

def convert_bgr_to_24bit(r, g, b):
    # Объединение значений B, G и R в 24-битное число
    rgb_value = (r << 16) | (g << 8) | b
    return rgb_value

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

def parse_image_pixelwise(image_path):
    # Загрузка изображения
    image = cv2.imread(image_path)

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
        file.write("\0\0\0\0\0\0\0\0")

        for y in range(0, height - block_height + 1, block_height):
            for x in range(0, width - block_width + 1, block_width):
                # Извлечение блока изображения размером 4x2
                block = image[y:y + block_height, x:x + block_width]
                outputArray = []
                for line in block:
                    outputArray.append([])
                    for color in line:
                        formattedColor = convert_bgr_to_24bit(color[2], color[1], color[0])
                        outputArray[-1].append(color[0] > 128)
                # print(make_braille(outputArray), end='')

                dominant_colors = find_dominant_colors(block)
                back, fore = find_closest_color(convert_bgr_to_24bit(dominant_colors[0]), colors), find_closest_color(convert_bgr_to_24bit(dominant_colors[1]), colors)
                char = make_braille(outputArray)
                print(back, fore, char)

            print("")

if __name__ == "__main__":
    try:
        image_path = False
        if len(sys.argv) < 2:
            image_path = "D:\\Users\\user\\Documents\\GitHub\liked\\tools\\settings.png"
        else:
            image_path = sys.argv[1]
        parse_image_pixelwise(image_path)

    except Exception as e:
        # Обработка исключения и вывод сообщения
        print(f"Произошла ошибка: {e}")
        traceback.print_exc()

    while True: pass