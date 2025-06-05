from .action import ActionInfo, add_action, run_action
from typing import Any


@add_action("nothing")
def nothing(info: ActionInfo, values: dict[str, Any]):
    return run_action(info, values["from"])