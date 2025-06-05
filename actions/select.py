from .action import ActionInfo, add_action, run_action
from typing import Any

# The config path provided is invalid.
class SelectArgumentError(Exception):
    ...

@add_action("select")
def select(info: ActionInfo, values: dict[str, Any]):
    require_match = False
    if "require_match" in values:
        require_match = run_action(info, values["require_match"])
        
        if not isinstance(require_match, bool):
            raise SelectArgumentError("'require_match' argument must be a boolean.")
        
        
    if not "value" in values:
        raise SelectArgumentError("Select action must contain a 'value' argument.")
    
    value = values["value"]
    value = run_action(info, value)


    if not "cases" in values:
        raise SelectArgumentError("Select action must contain a 'cases' argument.")
    
    cases = values["cases"]
    if not isinstance(cases, list):
        raise SelectArgumentError("'cases' argument must be a list.")

    for i, c in enumerate(cases):
        if not isinstance(c, dict):
            raise SelectArgumentError(f"Cases must be a JSON object (case {i + 1}).")
        
        if not "when" in c:
            raise SelectArgumentError(f"Cases must contain a 'when' value (case {i + 1}).")

        if not "action" in c:
            raise SelectArgumentError(f"Cases must contain an 'action' value (case {i + 1}).")
        
        when = []
        if isinstance(c["when"], list):
            when = [run_action(info, v) for v in c["when"]]
        else:
            when = [run_action(info, c["when"])]
        
        if value in when:
            return run_action(info, c["action"])
    
    if require_match:
        raise SelectArgumentError("No case matched in select action with 'require_match' set to true.")
    
    return None