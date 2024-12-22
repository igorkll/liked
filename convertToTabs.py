import os

def replace_spaces_with_tabs(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    new_lines = []
    for line in lines:
        while line.startswith('    '):
            line = '\t' + line[4:]
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