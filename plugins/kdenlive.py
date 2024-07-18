"""
Installer for kdenlive on linux systems.
"""

# std
import os
from subprocess import run

# 3rd
from terra import Plugin


class KdenliveInstaller(Plugin):
    """
    Kdenlive installer plugin.
    """

    _alias_ = "Kdenlive Installer"
    icon = "https://kdenlive.org/wp-content/uploads/2022/01/kdenlive-logo-blank-500px.png"
    description = "Kdenlive is an acronym for KDE Non-Linear Video Editor. It works on GNU/Linux, Windows and BSD."
    fields = [
        Plugin.field("url", "Download URL", required=False),
        Plugin.field("destination", "Destination directory", required=True)
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.download_url = kwargs.get("url", "https://download.kde.org/stable/kdenlive/24.05/linux/kdenlive-24.05.2-x86_64.AppImage")
        self.destination = kwargs.get("destination")

        # validate
        if not self.destination:
            raise ValueError("No destination directory provided")

        if not self.destination.endswith("/"):
            self.destination += "/"

        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Download and unpack the appimage to the destination directory.
        """
        scripts_directory = os.path.abspath(f"{__file__}/../scripts")
        self.logger.info(f"Loading scripts from {scripts_directory}")
        if run(
            f"bash {scripts_directory}/kdenlive-installer.sh {self.download_url} {self.destination}",
            shell=True
        ).returncode != 0:
            raise RuntimeError("Failed to install kdenlive")
