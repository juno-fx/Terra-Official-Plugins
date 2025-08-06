"""
Handles installing PyCharm by JetBrains
"""

# std
import os
from subprocess import run
from pathlib import Path

# 3rd
from terra import Plugin


class PyCharmInstaller(Plugin):
    """
    PyCharm
    """

    _version_ = "1.0.0"
    _alias_ = "PyCharm Installer"
    icon = "https://intellij-support.jetbrains.com/hc/user_images/5l0fLOoDkFwpjU_ZKu7Ofg.png"
    description = "Python development IDE by JetBrains."
    category = "Software Development"
    tags = ["ide", "python", "development", "jetbrains"]
    fields = [
        Plugin.field("version", "Version of PyCharm to install. i.e. 2024.1.4", required=False),
        Plugin.field("destination", "Destination directory", required=True),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.version = kwargs.get("version", "2024.1.4")
        self.destination = Path(kwargs.get("destination")).as_posix()

        # validate
        if not self.destination:
            raise ValueError("No destination directory provided")

        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Download and unpack the PyCharm.
        """
        scripts_directory = os.path.abspath(f"{__file__}/../scripts")
        self.logger.info(f"Loading scripts from {scripts_directory}")
        if (
            run(
                f"bash {scripts_directory}/pycharm-installer.sh {self.version} {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install PyCharm")

    def uninstall(self, *args, **kwargs) -> None:
        """
        Uninstall the plugin.
        """
        self.logger.info(f"Removing {self._alias_}")
        self.destination = Path(kwargs.get("destination")).as_posix()
        if (
                run(
                    f"rm -rf {self.destination}",
                    shell=True,
                    check=False,
                ).returncode
                != 0
        ):
            raise RuntimeError(f"Failed to remove {self._alias_}. Please read trough the logs and try to manually remove it.")

        else:
            self.logger.info(f"Successfully removed {self._alias_} plugin.")