"""
Loader for Terra Plugins
"""

# std
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
        self, plugin_type, name, allow_failure=True, *args, **kwargs
    ):  # pragma: no cover
        """
        Run a plugin
        """
        return self.get_plugin(plugin_type, name)(LOGGER).run(
            allow_failure=allow_failure, *args, **kwargs
        )


def plugins(paths: List[str]) -> TerraPluginLoader:
    """
    Load All Plugins
    """
    return TerraPluginLoader(paths=paths)
