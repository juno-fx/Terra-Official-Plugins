"""
Installer for NukeSamurai on linux systems.
"""

# std
import os
from subprocess import run
from pathlib import Path

# 3rd
from terra import Plugin


class NukeSamuraiInstaller(Plugin):
    """
    NukeSamurai installer plugin.
    """

    _version_ = "1.0.0"
    _alias_ = "NukeSamurai Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/nukesamurai.png?raw=true"
    description = "NukeSamurai SAM2 plugin for Nuke 15. Requires GPU Instance"
    category = "Media and Entertainment"
    tags = ["NukeSamurai", "editor", "media", "editorial", "kde"]
    fields = [
        Plugin.field("destination", "Destination directory", required=True),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.destination = Path(kwargs.get("destination")).as_posix()


        # validate
        if not self.destination:
            raise ValueError("No destination directory provided")

        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Download and unpack the appimage to the destination directory.
        """
        scripts_directory = os.path.abspath(f"{__file__}/../scripts")
        self.logger.info(f"Loading scripts from {scripts_directory}")
        if (
            run(
                f"bash {scripts_directory}/nukesamurai-installer.sh  {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install NukeSamurai")

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
