import cv2
import os
import sys

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
    with open(output_path, 'w') as file:
        block_height = 4
        block_width = 2

        for y in range(0, height - block_height + 1, block_height):
            for x in range(0, width - block_width + 1, block_width):
                # Извлечение блока изображения размером 4x2
                block = image[y:y + block_height, x:x + block_width]
                outputArray = []
                for line in block:
                    outputArray.append([])
                    for color in line:
                        color2 = convert_bgr_to_24bit(color[2], color[1], color[0])
                        outputArray[-1].append(color[0] > 128)
                print(make_braille(outputArray), end='')
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

    while True: pass