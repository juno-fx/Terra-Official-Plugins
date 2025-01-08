"""
Tests for kdenlive
"""
from os import listdir
from terra.loaders import plugins


def test_kdenlive():
    """
    Test kdenlive installer.
    """
    handler = plugins()
    plugin = handler.get_plugin("plugin", "Kdenlive Installer")
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin(
        "Kdenlive Installer",
        allow_failure=False,
        destination="/apps/kdenlive",
    )

    handler.remove_plugin(name="Kdenlive Installer", destination="/apps/kdenlive")