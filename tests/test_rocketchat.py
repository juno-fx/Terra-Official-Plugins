"""
Tests for RocketChat
"""
from os import listdir
from terra.loaders import plugins


def test_rocketchat():
    """
    Test RocketChat installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'RocketChat Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'RocketChat Installer',
        allow_failure=False,
        destination='/apps/rocketchat'
    )
