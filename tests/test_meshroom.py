"""
Tests for meshroom
"""
from os import listdir
from terra.loaders import plugins


def test_meshroom():
    """
    Test meshroom installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Meshroom Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Meshroom Installer',
        allow_failure=False,
        destination='/apps/meshroom'
    )