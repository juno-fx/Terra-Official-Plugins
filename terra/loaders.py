"""
Loader for Terra Plugins
"""
# std
from typing import Dict

# 3rd
from pluginlib import PluginLoader

# local
from .plugin import Plugin
from .constants import SEARCH_PATHS
from .logger import LOGGER


class TerraPluginLoader(PluginLoader):
    """
    Terra Plugin Loader
    """

    def __init__(self, *args, **kwargs) -> None:
        """
        Initialize the Terra Plugin Loader
        """
        super().__init__(paths=SEARCH_PATHS, *args, **kwargs)
        self.logger = LOGGER

    def get_plugin(self, *args, **kwargs) -> Plugin:
        """
        Get a plugin
        """
        return super().get_plugin(*args, **kwargs)

    def plugins(self) -> Dict[str, Plugin]:
        """
        Get the plugins
        """
        return super().plugins

    def run_plugin(self, plugin_type, name, allow_failure=True, *args, **kwargs):
        """
        Run a plugin
        """
        return self.get_plugin(plugin_type, name)(LOGGER).run(
            allow_failure=allow_failure, *args, **kwargs
        )


def plugins() -> TerraPluginLoader:
    """
    Load All Plugins
    """
    return TerraPluginLoader()
