"""
Tests for ebsynth
"""
from os import listdir
from terra.loaders import plugins


def test_ebsynth():
    """
    Test ebsynth installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Ebsynth Installer')
    assert plugin is not None
    assert plugin._version_ is not None
    handler.run_plugin(
        'Ebsynth Installer',
        allow_failure=False,
        destination='/apps/ebsynth'
    )

    # test removal
    #handler.remove_plugin(name="Ebsynth Installer", destination="/apps/ebsynth")