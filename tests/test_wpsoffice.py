"""
Tests for wpsoffice
"""
from os import listdir
from terra.loaders import plugins


def test_wpsoffice():
    """
    Test Wpsoffice installer.
    """
    handler = plugins()
    plugin = handler.get_plugin("plugin", "Wpsoffice Installer")
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin(
        "Wpsoffice Installer",
        allow_failure=False,
        destination="/apps/wpsoffice",
    )
    handler.remove_plugin(name="Wpsoffice Installer", destination="/apps/wpsoffice")