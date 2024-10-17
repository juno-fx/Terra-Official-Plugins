"""
Loader for Terra Plugins
"""

# std
from glob import glob
from typing import Dict, List

# 3rd
from pluginlib import PluginLoader

# local
from .plugin import Plugin
from .logger import LOGGER


class TerraPluginLoader(PluginLoader):
    """
    Terra Plugin Loader
    """

    def __init__(self, *args, **kwargs) -> None:
        """
        Initialize the Terra Plugin Loader
        """
        super().__init__(*args, **kwargs)
        self.logger = LOGGER

    def get_plugin(self, *args, **kwargs) -> Plugin:  # pragma: no cover
        """
        Get a plugin
        """
        return super().get_plugin(*args, **kwargs)

    def plugins(self) -> Dict[str, Plugin]:
        """
        Get the plugins
        """
        return super().plugins

    def run_plugin(
        self, name, allow_failure=True, *args, **kwargs
    ):  # pragma: no cover
        """
        Run a plugin
        """
        target = self.get_plugin('plugin', name)
        if not target:
            target = self.get_plugin('workflow', name)
        return target(LOGGER).run(
            allow_failure=allow_failure, *args, **kwargs
        )


def plugins(paths: List[str] = None) -> TerraPluginLoader:
    """
    Load All Plugins
    """
    if not paths:
        paths = ["/app/Terra-Official-Plugins/plugins/", "/app/Terra-Official-Plugins/workflows/"]
        for path in glob("/opt/*/plugins/"):
            paths.append(path)
        for path in glob("/opt/*/workflows/"):
            paths.append(path)

    return TerraPluginLoader(paths=paths)
