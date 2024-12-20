"""
Tests for firefox
"""
from os import listdir
from terra.loaders import plugins


def test_firefox():
    """
    Test firefox installer.
    """
    handler = plugins()
    plugin = handler.get_plugin("plugin", "Firefox Browser")
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin("Firefox Browser", allow_failure=False)
