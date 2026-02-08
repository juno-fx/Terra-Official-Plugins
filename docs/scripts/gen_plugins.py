import mkdocs_gen_files
from glob import glob
import yaml

plugins = glob("plugins/*/terra.yaml")

def generate(plugin):
    template = f"""
```yaml linenums="1" title="{plugin}"
--8<-- "{plugin}"
```
"""
    return template

for plugin in plugins:
    nav = mkdocs_gen_files.Nav()
    with open(plugin, "r") as f:
        plugin_data = yaml.safe_load(f)
        icon = plugin_data.get("icon")
        description = plugin_data.get("description")
        category = plugin_data.get("category")

    plugin_name = plugin.split('/')[1]
    plugin_path = f"plugins/{category}/{plugin_name}.md"
    with mkdocs_gen_files.open(plugin_path, "w") as f:
        if icon or description:
            print('|Deployment|About|', file=f)
            print('|---|---|', file=f)
            print(f'| ![icon]({icon})' + '{width=100}' + f' | {description} |', file=f)
        print(generate(plugin), file=f)

    nav["Plugins", plugin_name] = plugin_path
