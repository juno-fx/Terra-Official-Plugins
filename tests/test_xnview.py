"""
Tests for xnview
"""
from os import listdir
from terra.loaders import plugins


def test_xnview():
    """
    Test xnview installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Xnview Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Xnview Installer',
        allow_failure=False,
        destination='/apps/xnview'
    )