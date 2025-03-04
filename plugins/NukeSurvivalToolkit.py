"""
Nuke Survival Toolkit v2.1.1
"""

# std
import os
import shutil
from subprocess import run

# 3rd
from terra import Plugin
from terra.loaders import plugins


class NukeSurvivalToolkit_v211(Plugin):
    """
    Git Nuke Survival Toolkit v2.1.1
    """

    _version_ = "1.0.0"
    _alias_ = "Nuke Survival Toolkit v2.1.1"
    icon = "https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/assets/nukesurvivaltoolkit.png?raw=true"
    description = "The Nuke Survival Toolkit is a portable tool menu for the Foundry’s Nuke with a hand-picked selection of nuke gizmos collected from all over the web, organized into 1 easy to install toolbar."
    category = "Plugins"
    tags = [
        "vfx",
        "pipeline",
        "nuke survival toolkit",
        "visual effects",
        "plugins",
        "gizmos",
    ]

    def install(self, *args, **kwargs) -> None:
        """
        Run git pull and install to the target directory
        """
        destination = kwargs.get("destination")
        os.makedirs(destination, exist_ok=True)

        handler = plugins()
        handler.run_plugin(
            "plugin",
            "Downloader",
            allow_failure=False,
            url="https://codeload.github.com/CreativeLyons/NukeSurvivalToolkit_publicRelease/zip/refs/tags/v2.1.1",
            destination=destination,
        )

        run(f"unzip {destination}/v2.1.1 -d {destination}", shell=True, check=True)
        shutil.move(
            f"{destination}/NukeSurvivalToolkit_publicRelease-2.1.1/NukeSurvivalToolkit",
            f"{destination}/",
        )
        os.unlink(f"{destination}/v2.1.1")
        shutil.rmtree(f"{destination}/NukeSurvivalToolkit_publicRelease-2.1.1")

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
