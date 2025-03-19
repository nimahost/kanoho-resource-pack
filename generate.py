import json
from typing import Any
import os.path
from os import walk


import actions
import actions.action


def print_action_exeption(e, action_file) -> None:
    print(f"Error while processing actions in '{action_file}', error trace:")

    indent = 0
    while True:
        print("    " * indent, type(e))

        if len(e.args) == 0:
            break
        
        if not isinstance(e.args[0], Exception):
            for arg in e.args:
                print("    " * indent, arg)
            break
        else:
            for arg in e.args[1:]:
                print("    " * indent, arg)
            e = e.args[0]
            indent += 1
    raise e

def run_file_actions(config: dict[str, Any], run_dir: str, source_file: str, destination_file: str) -> None:
    action_file = os.path.join(run_dir, os.path.basename(source_file) + ".json")
    
    file: dict = {"action": "read_binary"}
    if os.path.isfile(action_file):  
        with open(action_file, "r") as f:
            file = json.load(f)
    
    info = actions.action.ActionInfo(config, run_dir, source_file)

    action_result = None

    try:
        action_result = actions.action.run_action(info, file)
    except Exception as e:
        print_action_exeption(e, action_file)


    if isinstance(action_result, str):
        with open(destination_file, "w") as f:
            f.write(action_result)

    elif isinstance(action_result, bytes):
        with open(destination_file, "wb") as f:
            f.write(action_result)

    elif action_result is None:
        print(f"File {action_file} returned None so no data was written.")
    else:
        raise Exception(f"{action_file} returned an invalid type of {type(action_result)}.")

CONFIG_FILE_PATH = "presets.json"

def get_config(name: str | None) -> dict[str, Any]:
    presets = json.load(CONFIG_FILE_PATH)
    
    if not "default" in presets:
        raise Exception("Presets file needs a 'default' object.")
    
    config = presets["default"]
    
    if name is None:
        return config
    
    if not name in presets:
        raise Exception(f"Preset named '{name}' requested but does not exist in preset file.")
    
    preset = presets[name]
    if not isinstance(presets, dict):
        return preset
    
    # Apply preset overides
    raise Exception("Complex preset overides are not yet supported.")

GENERATOR_FOLDER_NAME = "_actions"
PACK_INPUT_DIR = "pack"
PACK_OUTPUT_DIR = "output"

def add_subdirectories(in_path: str, out_path) -> None:
    for folder in os.listdir(in_path):
        in_folder = os.path.join(in_path, folder)
        if not os.path.isdir(in_folder): # Filter files
            continue
        if folder == GENERATOR_FOLDER_NAME: # Filter generator folders
            continue
        
        # Create folder if it does not exist
        out_folder = os.path.join(out_path, folder)
        if not os.path.isdir(out_folder):
            os.mkdir(out_folder)

        # Create folders for subdirectories
        add_subdirectories(in_folder, out_folder)

def generate_pack(pack_input_dir: str, pack_output_dir: str):
    # Generate folders
    if not os.path.isdir(pack_output_dir):
        os.mkdir(pack_output_dir)
        add_subdirectories(pack_input_dir, pack_output_dir)
    else:
        print("Output pack already exists.")
        exit()
    
    # Generate files
    for (dirpath, dirnames, filenames) in walk(pack_input_dir):
        if dirpath.endswith(GENERATOR_FOLDER_NAME): # This might cause problems
            continue

        for file in filenames:
            source_file = os.path.join(dirpath, file)
            print(f"Processing {source_file}")

            rel_file = os.path.relpath(source_file, pack_input_dir)
            destination_file = os.path.join(pack_output_dir, rel_file)
            
            run_dir = os.path.join(dirpath, GENERATOR_FOLDER_NAME)

            run_file_actions({"skybox": {"quality": "normal"}}, run_dir, source_file, destination_file)


if __name__ == "__main__":
    generate_pack(PACK_INPUT_DIR, PACK_OUTPUT_DIR)
