"""
Tests for clarisse
"""
from os import listdir
from terra.loaders import plugins


def test_clarisse():
    """
    Test clarisse installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'clarisse Installer')
    assert plugin is not None
    handler.run_plugin(
        'clarisse Installer',
        allow_failure=False,
        destination='/apps/clarisse'
    )
    #handler.remove_plugin(name="clarisse Installer", destination="/apps/clarisse")