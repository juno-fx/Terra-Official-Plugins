"""
Tests for NukeSamurai
"""
from os import listdir
from terra.loaders import plugins


def test_NukeSamurai():
    """
    Test NukeSamurai installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'NukeSamurai Installer')
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin(
        'NukeSamurai Installer',
        destination='/apps/nukesamurai'
    )

    # test removal
    # handler.remove_plugin(name="NukeSamurai Installer", destination="/apps/nukesamurai")