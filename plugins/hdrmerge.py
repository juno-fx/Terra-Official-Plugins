"""
Installer for hdrmerge on linux systems.
"""

# std
import os
from subprocess import run

# 3rd
from terra import Plugin


class HdrmergeInstaller(Plugin):
    """
    Hdrmerge installer plugin.
    """

    _alias_ = "Hdrmerge Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/hdrmerge.png?raw=true"
    description = "HDRMerge creates raw images with an extended dynamic range."
    category = "Media and Entertainment"
    tags = ["hdrmerge", "editor", "media", "editorial", "kde"]
    fields = [
        Plugin.field("url", "Download URL", required=False),
        Plugin.field("destination", "Destination directory", required=True),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.download_url = kwargs.get(
            "url",
            "https://github.com/jcelaya/hdrmerge/releases/download/nightly/hdrmerge_release-v0.6_continuous-71-gd7d8041_20191220.AppImage",
        )
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
        if (
            run(
                f"bash {scripts_directory}/kdenlive-installer.sh {self.download_url} {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install hdrmerge")