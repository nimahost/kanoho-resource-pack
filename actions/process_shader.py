from .action import ActionInfo, add_action, run_action
from typing import Any


# An error occoured while prossesing the shader.
class ProcessShaderError(Exception):
    ...

@add_action("process_shader")
def nothing(info: ActionInfo, values: dict[str, Any]):
    if not "shader" in values:
        raise ProcessShaderError("Process shader action requires a 'shader' input.")
    shader = run_action(info, values["shader"])
    if not isinstance(shader, str):
        raise ProcessShaderError("'shader' value must evaluate to a string.")
    
    sections = {}
    if "sections" in values:
        if not isinstance(values["sections"], dict):
            raise ProcessShaderError("'sections' value must be a JSON object.")
        for key, val in values["sections"].items():
            sections[key] = run_action(info, val)
            if not isinstance(sections[key], str):
                raise ProcessShaderError("Section values must be a string type.")
    
    output = ""
    
    uncomment_section = False
    while len(shader) > 0:
        if not "\n" in shader: break
        line, shader = shader.split("\n", 1)
        
        if line.startswith("//# "):
            _, command, *args = line.split(" ")
            match command:
                case "section":
                    if args[0] == "end": continue
                    if not args[0] == "start":
                        raise ProcessShaderError("Shader section must start with a 'section start' command.")
                    
                    # This could be optimised by stopping once deletion is decided
                    to_delete = False
                    for condition in args[1:]:
                        key, value = condition.split("=", 1)
                        if not key in sections:
                            raise ProcessShaderError(f"Shader section expected a '{key}' value but none were given.")
                        to_delete = to_delete or sections[key] != value
                    
                    if to_delete:
                        while not line.startswith("//# section end"):
                            if not "\n" in shader: raise ProcessShaderError("Section was never ended.")
                            line, shader = shader.split("\n", 1)

                case "comment_section":
                    if args[0] == "end":
                        uncomment_section = False
                        continue
                    if not args[0] == "start":
                        raise ProcessShaderError("Shader comment section must start with a 'comment_section start' command.")
                    
                    # This could be optimised by stopping once deletion is decided
                    to_delete = False
                    for condition in args[1:]:
                        key, value = condition.split("=", 1)
                        if not key in sections:
                            raise ProcessShaderError(f"Shader comment section expected a '{key}' value but none were given.")
                        to_delete = to_delete or sections[key] != value
                    
                    if to_delete:
                        while not line.startswith("//# comment_section end"):
                            if not "\n" in shader: raise ProcessShaderError("Comment section was never ended.")
                            line, shader = shader.split("\n", 1)
                    else:
                        uncomment_section = True
        else:
            if uncomment_section and line.startswith("// "):
                output += line[3:] + "\n"
            else:
                output += line + "\n"
    
    return output