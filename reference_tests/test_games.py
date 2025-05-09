"""
Tests for games
"""
from os import listdir
from terra.loaders import plugins


def test_games():
    """
    Test games installer.
    """
    handler = plugins()
    plugin = handler.get_plugin("plugin", "Games Installer")
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin(
        "Games Installer", allow_failure=False, destination="/apps/games"
    )

    handler.remove_plugin(name="Games Installer", destination="/apps/games")