"""
Start up script.
"""
# std
from logging import getLogger, basicConfig, INFO

# local
from .header import header

basicConfig(level=INFO)

LOGGER = getLogger("terra-plugins")
header(LOGGER, "rolling", "Terra Plugins")
