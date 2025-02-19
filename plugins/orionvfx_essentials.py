"""
Juno's Orion Essentials Bundle
"""

# std
import os
from http.client import HTTPException
from pathlib import Path

# 3rd
import requests
from terra import Plugin

INSTALL_URL = "http://terra:8000/plugins/install"


class OrionVFXEssentials(Plugin):
    """
    Orion VFX Essentials bundle plugin
    """

    _version_ = "1.0.0"
    _alias_ = "OrionVFX Essentials"
    icon = "https://avatars.githubusercontent.com/u/77702266?s=200&v=4"
    description = (
        "Install our OrionVFX Essentials bundle. includes Orion Essentials Bundle, Nuke, MRV2, OCIO"
    )
    category = "Bundle"
    tags = ["vfx", "nuke", "mrv2", "ocio", "render", "essential", "orion", "bundle"]
    fields = [
        Plugin.field(
            "Nuke version", "Version of Nuke to install. Defaults to Nuke15.1v1", required=False
        ),
        Plugin.field(
            "Nuke destination",
            "Destination directory for nuke. Defaults to /apps/nuke",
            required=False,
        ),
        Plugin.field(
            "Mrv2 destination",
            "Destination directory for mrv2 Defaults to /apps/mrv2",
            required=False,
        ),
        Plugin.field(
            "OCIO destination",
            "Destination directory for ocio configs. If blank, OCIO will NOT be installed",
            required=False,
        ),
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        run a preflight check
        """

        # store on instance
        self.nuke_version = kwargs.get("Nuke version", "Nuke15.1v1")
        self.nuke_destination = Path(kwargs.get("Nuke destination", "/apps/nuke")).as_posix()
        self.mrv2_destination = Path(kwargs.get("Mrv2 destination", "/apps/mrv2")).as_posix()
        self.ocio_destination = None
        ocio_destination = kwargs.get("OCIO destination")
        if ocio_destination:
            self.ocio_destination = Path(kwargs.get(ocio_destination)).as_posix()

        # validate
        if not self.nuke_destination or not self.mrv2_destination:
            raise ValueError("No destination directory provided")

        for destination in [self.nuke_destination, self.mrv2_destination, self.ocio_destination]:
            if destination:
                os.makedirs(destination, exist_ok=True)

    def install(self, *args, **kwargs) -> None:
        """
        Install all of our bundled apps
        """

        for app, data in [
            ("Orion Essentials", self.orion_essentials_data),
            ("Nuke", self.nuke_data),
            ("Mrv2", self.mrv2_data),
            ("OCIO", self.ocio_data),
        ]:
            if not data:
                self.logger.info(f"No Install data provided for {app} Skipping install")
                continue
            self.logger.info(f"Preparing Install for {app}")
            self.logger.info(data)
            response = requests.post(url=INSTALL_URL, json=data, timeout=5)
            if response.status_code != 200:
                self.logger.info(f"Preparing {data.get('install_name')} install")
                raise HTTPException(
                    f"{data.get('install_name')} Install Error {response.status_code}: {response.text}"
                )

    @property
    def orion_essentials_data(self) -> dict:
        """
        Define our orion essentials install data
        """

        return {"install_name": "Orion Essentials", "plugin_name": "Orion Essentials", "fields": {}}

    @property
    def nuke_data(self) -> dict:
        """
        Define our nuke install data
        """
        install_name = self.nuke_version.split(".")[0]

        return {
            "install_name": install_name,
            "plugin_name": "Nuke Installer",
            "fields": {
                "version": self.nuke_version,
                "destination": self.nuke_destination,
            },
        }

    @property
    def ocio_data(self) -> dict:
        """
        Define our OCIO install data
        """

        data = {}

        if self.ocio_destination:
            data.update({
                "install_name": "OCIO Configs",
                "plugin_name": "Ocio Installer",
                "fields": {
                    "destination": self.ocio_destination,
                },
            })

        return data

    @property
    def mrv2_data(self) -> dict:
        """
        Define our mrv2 install data
        """

        return {
            "install_name": "Mrv2",
            "plugin_name": "Mrv2 Installer",
            "fields": {
                "destination": self.mrv2_destination,
            },
        }

    def uninstall(self, *args, **kwargs) -> None:
        """
        Uninstall the application.
        """
        self.logger.info("Uninstalling not implemented for bundle.")
