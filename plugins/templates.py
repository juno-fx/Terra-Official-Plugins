"""
Installer for templates on linux systems.
"""

# std
import os
from subprocess import run
from pathlib import Path

# 3rd
from terra import Plugin


class TemplatesInstaller(Plugin):
    """
    templates installer plugin.
    """

    _version_ = "1.0.0"
    _alias_ = "Templates Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/missing.png?raw=true"
    description = "Document User Templates. Provides right click context menu for creating new documents from templates."
    category = "User templates"
    tags = ["templates"]
    fields = []

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.destination = "/apps/templates"
        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Download and unpack the appimage to the destination directory.
        """
        scripts_directory = os.path.abspath(f"{__file__}/../scripts")
        self.logger.info(f"Loading scripts from {scripts_directory}")
        if (
            run(
                f"bash {scripts_directory}/templates-installer.sh {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install templates")

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