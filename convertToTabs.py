import os

def replace_spaces_with_tabs(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    new_content = content.replace('    ', '\t')
    
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(new_content)

def process_directory(directory):
    init_file_path = os.path.join(directory, 'init.lua')
    if os.path.isfile(init_file_path):
        replace_spaces_with_tabs(init_file_path)

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.lua'):
                file_path = os.path.join(root, file)
                replace_spaces_with_tabs(file_path)

process_directory("system")
