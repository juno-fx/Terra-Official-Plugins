"""
Plugin Loader for the service module
"""
# std
from traceback import format_exc
from logging import Logger

# 3rd
import pluginlib


@pluginlib.Parent("plugin")
class Plugin:
    """
    Base class for extensions
    """

    _skipload_: bool = True
    icon: str = ""
    description: str = ""
    fields: dict = {}

    def __init__(self, logger: Logger):
        """
        Initialize the Plugin
        """
        self.logger = logger
        name = self.__class__._alias_
        if not name:
            name = self.__class__.__name__
        self.logger.info(f"Initializing {name} Plugin")

    def run(self, allow_failure=True, *args, **kwargs) -> None:
        """
        Initialize the Plugin
        """
        try:
            preflight = self.preflight(*args, **kwargs)
            if preflight or preflight is None:
                self.install(*args, **kwargs)
        except Exception as error:
            self.logger.error(f"Error: {error}")
            self.logger.error(format_exc())
            if not allow_failure:
                raise error

    def preflight(self, *args, **kwargs) -> bool:
        """
        Run preflight
        """
        self.logger.info("No custom preflight provided.")
        return True

    @pluginlib.abstractmethod
    def install(self, *args, **kwargs) -> None:
        """
        Run install process
        """
        self.logger.info("No custom installer provided.")
