"""
Handles installing Houdini by SideFX
"""

# std
import os
from subprocess import run

# 3rd
from terra import Plugin


class HoudiniInstaller(Plugin):
    """
    Nuke
    """

    _alias_ = "Houdini Installer"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/houdini.png?raw=true"
    description = "Install Houdini to a target directory."
    category = "Media and Entertainment"
    tags = ["houdini", "sidefx", "media", "vfx", "visual effects"]
    fields = [
        Plugin.field("version", "Version of Houdini to install. i.e. 20.5.278", required=True),
        Plugin.field("destination", "Destination directory", required=True),
        Plugin.field("client_id", "SideFX Cliend ID", required=True),
        Plugin.field("client_secret", "SIdeFX Client secret", required=True),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.version = kwargs.get("version")
        self.destination = kwargs.get("destination")
        self.client_id = kwargs.get("client_id")
        self.client_secret = kwargs.get("client_secret")

        assert self.client_secret
        assert self.client_id
        assert self.version

        self.build = self.version.split(".")[2]
        self.version = self.version.split(".")[0] + "." + self.version.split(".")[1]

        assert self.version
        assert self.build

        # validate
        if not self.destination:
            raise ValueError("No destination directory provided")

        if not self.destination.endswith("/"):
            self.destination += "/"

        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Download and unpack the Nuke.
        """
        scripts_directory = os.path.abspath(f"{__file__}/../scripts")
        self.logger.info(f"Loading scripts from {scripts_directory}")
        if (
                run(
                    f"bash {scripts_directory}/houdini-install.sh {self.version} {self.build} {self.destination} {self.client_id} {self.client_secret}",
                    shell=True,
                    check=False,
                ).returncode
                != 0
        ):
            raise RuntimeError("Failed to install Houdini")