from .action import ActionInfo, add_action, run_action
from typing import Any
import os.path

@add_action("read")
@add_action("read_binary")
def read(info: ActionInfo, values: dict[str, Any]):
    path = info.source_file
    if "file" in values:
        path = os.path.join(info.run_dir, run_action(info, values["file"]))
    
    mode = "r" if values["action"] == "read" else "rb"
    
    with open(path, mode) as f:
        return f.read()
    return run_action(values["from"])