"""
Tests for demofiles
"""
from os import listdir
from terra.loaders import plugins


def test_demofiles():
    """
    Test Demofiles installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Demofiles Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Demofiles Installer',
        allow_failure=False,
        destination='/apps/demofiles'
    )