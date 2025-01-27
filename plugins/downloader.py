"""
Download a file from a URL
"""

# std
import os

# 3rd
from subprocess import run
from terra import Plugin


class Downloader(Plugin):
    """
    Git Loader
    """

    _version_ = "1.0.0"
    _alias_ = "Downloader"
    icon = "https://freeiconshop.com/wp-content/uploads/edd/download-flat.png"
    description = "Clone down a repository from a Git Source"
    category = "Utility"
    tags = ["download"]
    fields = [
        Plugin.field("url", "Download URL", required=True),
        Plugin.field("destination", "Destination directory", required=True),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists
        """
        # store on instance
        self.url = kwargs.get("url")
        self.destination = kwargs.get("destination")

        # validate
        if not self.url:
            raise ValueError("No url provided")

        if not self.destination:
            raise ValueError("No destination directory provided")

        if not self.destination.endswith("/"):
            self.destination += "/"

        os.makedirs(self.destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Run git pull and install to the target directory
        """
        if (
            run(
                f"wget -P {self.destination} {self.url}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to download file")

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
