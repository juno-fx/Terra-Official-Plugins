import os
import re
import mkdocs_gen_files
from glob import glob
import yaml

for plugin in sorted(glob("plugins/*/terra.yaml")):
    with open(plugin) as f:
        category = yaml.safe_load(f).get("category") or "Other"

    plugin_dir = os.path.dirname(plugin)
    plugin_name = os.path.basename(plugin_dir)

    readme_path = os.path.join(plugin_dir, "README.md")
    try:
        with open(readme_path) as f:
            readme_content = f.read()
    except FileNotFoundError:
        readme_content = ""

    # Constrain first image (logo) to standard width
    readme_content = re.sub(
        r'!\[([^\]]*)\]\(([^)]+)\)',
        r'<img src="\2" alt="\1" width="200">',
        readme_content,
        count=1,
    )

    plugin_path = f"plugins/{category}/{plugin_name}.md"
    with mkdocs_gen_files.open(plugin_path, "w") as f:
        print(readme_content, file=f)
        print("---", file=f)
        print(f"""
```yaml linenums="1" title="{plugin}"
--8<-- "{plugin}"
```
""", file=f)
