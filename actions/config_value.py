from .action import ActionInfo, add_action, run_action
from typing import Any
import os.path


# The config path provided is invalid.
class ConfigPathError(Exception):
    ...

@add_action("config_value")
def config_value(info: ActionInfo, values: dict[str, Any]):    
    if not ("path" in values):
        raise ConfigPathError("Config value action must have a 'path' argument.")
    
    path = values["path"]
    path = run_action(info, path)
    
    if not isinstance(path, str):
        raise ConfigPathError("Config value path must be of type string.")
    
    path = values["path"].split(".")
    config = info.config
    
    for i in range(len(path)):
        if not isinstance(config, dict):
            raise ConfigPathError("Unable to get sub values from non-object item.")
        if path[i] not in config:
            raise ConfigPathError(f"Unable to find '{".".join(path[:i + 1])}' in config values.")
        
        config = config[path[i]]
    
    return config