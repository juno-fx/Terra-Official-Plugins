"""
Installer for RocketChat on linux systems.
"""

# std
import os
import time
from subprocess import run

import requests

# 3rd
from terra import Plugin


class RocketChatInstaller(Plugin):
    """
    RocketChat installer plugin.
    """

    _alias_ = "RocketChat Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/rocketchatapp.png?raw=true"
    description = "RocketChat app and service installer"
    category = "Media and Entertainment"
    tags = ["rocketchat", "chat", "messaging", "communication"]
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
            "rocketchat",
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
                f"bash {scripts_directory}/rocketchat-installer.sh {self.download_url} {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install RocketChat")

        time.sleep(60)
        print(requests.request("GET", "http://localhost:3000").status_code)
        print(requests.request("GET", "http://localhost:3000").content)
