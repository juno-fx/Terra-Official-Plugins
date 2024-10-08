"""
Installer for maya on linux systems.
"""

# std
import os
import time
from subprocess import run
from pathlib import Path

# 3rd
from terra import Plugin


class mayaInstaller(Plugin):
    """
    maya installer plugin.
    """

    _version_ = "1.0.0"
    _alias_ = "Maya Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/autodesk-maya.png?raw=true"
    description = "Autodesk Maya is a 3D computer graphics software used for creating interactive 3D animations, models, and simulations."
    category = "Media and Entertainment"
    tags = ["maya", "3d", "animation", "modeling", "cg"]
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
            "maya",
        )
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

        # download maya
        if (
            run(
                f"bash {scripts_directory}/maya_downloader.sh {self.download_url} {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install maya")


        # convert rpms to debs
        if (
            run(
                f"bash {scripts_directory}/maya_prep_files.sh {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install maya")

        # install maya license server

        # install maya app and make it portable


        # if (
        #     run(
        #         f"bash {scripts_directory}/maya-installer.sh {self.download_url} {self.destination}",
        #         shell=True,
        #         check=False,
        #     ).returncode
        #     != 0
        # ):
        #     raise RuntimeError("Failed to install maya")



        time.sleep(30000)