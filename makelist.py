import os
import pathlib

def recursive_file_paths(folder_path):
    file_paths = []
    for dirpath, _, filenames in os.walk(folder_path):
        for filename in filenames:
            file_paths.append(os.path.join(dirpath, filename))
    return file_paths

def recursive_file_paths_without_folder(folder_path):
    file_paths = []
    for dirpath, _, filenames in os.walk(folder_path):
        for filename in filenames:
            p = os.path.join(dirpath, filename)
            p = p[len(folder_path) + 1:len(p)]
            file_paths.append(p)
    return file_paths

def write_paths_to_file(file_paths, output_file):
    with open(output_file, 'w') as f:
        lpaths = [os.path.relpath(path).replace("\\", "/") for path in file_paths]
        formatted_paths = [f'/{lpath}' for lpath in lpaths]
        f.write('\n'.join(formatted_paths))

if __name__ == "__main__":
    current_directory = os.path.dirname(os.path.abspath(__file__))
    system_directory = os.path.join(current_directory, 'system')
    cc_directory = os.path.join(current_directory, 'computercraft')

    write_paths_to_file(recursive_file_paths(system_directory), os.path.join(current_directory, 'installer/filelist.txt'))
    write_paths_to_file(recursive_file_paths_without_folder(cc_directory), os.path.join(current_directory, 'installer/cc_filelist.txt'))
