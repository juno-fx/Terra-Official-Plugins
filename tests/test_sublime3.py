"""
Tests for sublime3
"""
from terra.loaders import plugins


def test_nuke():
    """
    Test sublime3 installer.
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Sublime3 Installer')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Sublime3 Installer',
        allow_failure=False,
        destination='/apps/sublime3',
        version='3211'
    )