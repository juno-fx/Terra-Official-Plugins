"""
Tests for gitloader
"""
from os import listdir
from terra.loaders import plugins


def test_gitloader():
    """
    Verify that we can even use this endpoint
    """
    handler = plugins()
    plugin = handler.get_plugin('plugin', 'Git Loader')
    assert plugin is not None
    handler.run_plugin(
        'plugin',
        'Git Loader',
        allow_failure=False,
        url='https://github.com/juno-fx/Terra-Official-Plugins.git',
        ref='main',
        destination='/tmp/terra'
    )
    assert 'README.md' in listdir('/tmp/terra')
