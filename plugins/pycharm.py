"""
Handles installing PyCharm by JetBrains
"""

# std
import os
from subprocess import run

# 3rd
from terra import Plugin


class PyCharmInstaller(Plugin):
    """
    PyCharm
    """

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
        self.destination = kwargs.get("destination")

        # validate
        if not self.destination:
            raise ValueError("No destination directory provided")

        if not self.destination.endswith("/"):
            self.destination += "/"

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
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install PyCharm")