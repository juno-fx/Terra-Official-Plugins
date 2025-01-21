"""
Installer for vlc on linux systems.
"""

# std
import os
from subprocess import run
from pathlib import Path

# 3rd
from terra import Plugin


class VlcInstaller(Plugin):
    """
    vlc installer plugin.
    """

    _version_ = "1.0.0"
    _alias_ = "Vlc Installer"
    _custom_metadata_ = {}
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/vlc.png?raw=true"
    description = "VideoLanClient aka VLC The Great Media Player"
    category = "Applications"
    tags = ["vlc", "video", "player", "animation"]
    fields = [
        Plugin.field("destination", "Destination directory", required=True),
        Plugin.field("environment", "Environment variables", required=False),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists and validate the arguments passed.
        """
        # store on instance
        self.download_url = kwargs.get(
            "url",
            "https://github.com/ivan-hc/VLC-appimage/releases/download/3.0.19/VLC_media_player-3.0.19-20230721-with-plugins-x86_64.AppImage",
        )

        self.destination = Path(kwargs.get("destination")).as_posix()
        self.environment = kwargs.get("environment") or "env data"
        self.executable = Path(self.destination).joinpath("vlc.sh").as_posix()

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
                f"bash {scripts_directory}/vlc-installer.sh {self.download_url} {self.destination}",
                shell=True,
                check=False,
            ).returncode
            != 0
        ):
            raise RuntimeError("Failed to install vlc")

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