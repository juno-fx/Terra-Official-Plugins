"""
Tests for LiquiGen
"""
from os import listdir
from terra.loaders import plugins


def test_liquigen():
    """
    Test liquigen installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'LiquiGen Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'LiquiGen Installer',
        allow_failure=False,
        destination='/apps/liquigen'
    )