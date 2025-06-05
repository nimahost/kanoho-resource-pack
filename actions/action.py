from typing import Callable, Any


# Info needed for an action to run.
class ActionInfo:
    def __init__(self, config: dict[str, Any], run_dir: str, source_file: str):
        # The values set in the config file.
        self.config: dict[str, Any] = config
        # The directory where the actions that are being run is stored, should be used for relitive file paths.
        self.run_dir: str = run_dir
        # The file that the action should use as an input
        self.source_file: str = source_file

type Action = Callable[[ActionInfo, dict[str, Any]], Any]


# Action format is invalid.
class ActionFormatError(Exception):
    ...
# Action name is invalid.
class ActionNameError(Exception):
    ...
# Action not found error.
class ActionError(Exception):
    ...
# Error while running action.
class ActionRunError(Exception):
    ...

actions: dict[str, Action] = {}

# Add the action to be used in action processing.
def add_action(action_name: str) -> Callable[[Action], Action]:
    def decorator(action: Action) -> Action:
        actions[action_name] = action
        return action
    return decorator

# Run the action from dictionary form.
def run_action(info: ActionInfo, action: dict[str, Any] | str) -> Any:
    # Literal string
    if isinstance(action, str):
        return action

    # Literal bool
    if isinstance(action, bool):
        return action
    
    # Action
    if isinstance(action, dict):
        if not "action" in action:
            raise ActionFormatError("Action must have an 'action' value.", action)
        
        action_name = action["action"]
        if isinstance(action_name, dict):
            action_name = run_action(info, action_name)

        if not isinstance(action_name, str):
            raise ActionNameError("Action must evaluate to a string.", action)

        if not action_name in actions:
            raise ActionError(f"No action found called '{action_name}'.", action)

        action["action"] = action_name

        try:
            return actions[action_name](info, action)
        except Exception as e:
            raise ActionRunError(e, action)
    
    # Unknown
    raise ActionFormatError("Action format is invalid.")
