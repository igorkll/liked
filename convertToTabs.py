import os

def count_leading_spaces(line):
    count = 0
    for char in line:
        if char == ' ' or char == '\t':
            count += 1
        else:
            break
    return count

def replace_spaces_with_tabs(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    new_lines = []
    for line in lines:
        spaceCount = count_leading_spaces(line)
        if spaceCount > 0:
            line = ('\t' * (spaceCount // 4)) + line[spaceCount:]
        new_lines.append(line)
    
    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(new_lines)

def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.lua'):
                file_path = os.path.join(root, file)
                replace_spaces_with_tabs(file_path)

if os.path.isfile('init.lua'):
    replace_spaces_with_tabs('init.lua')

process_directory("system")
process_directory("market")
process_directory("installer")