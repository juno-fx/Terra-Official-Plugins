"""
Tests for maya
"""
from os import listdir
from terra.loaders import plugins


def test_maya():
    """
    Test maya installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Maya Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Maya Installer',
        allow_failure=False,
        destination='/apps/maya'
    )
