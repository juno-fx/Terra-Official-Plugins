"""Description: This script will download a specific Houdini build from the SideFX website."""

import os
import sys

import hashlib
import shutil
import click
import requests
from pprint import pprint
sys.path.append(os.path.abspath(f"{__file__}/../"))

import sidefx


@click.command()
@click.option("--version", default="20.0", help="Set Houdini version, default is 20.0")
@click.option("--build", default="751", help="Set Houdini build, default is 751")
@click.option("--key", default="None", help="Sidefx client id")
@click.option("--secret", default="None", help="Sidefx client secret")
@click.option("--output", default="None", help="Temp path location")
def run_download(version=None, build=None, key=None, secret=None, output=None):
    """Download a specific Houdini build from the SideFX website."""
    target_release = {
        "version": os.environ.get("HOUDINI_VERSION", version),
        "build": os.environ.get("HOUDINI_BUILD", build),
        "release": "gold",
        "platform": "linux_x86_64_gcc11.2",
        "product": "houdini",
    }
    product = "houdini-launcher"
    service = create_service(client_id=os.environ.get("SIDEFX_CLIENT_ID", key),
                             client_secret_key=os.environ.get("SIDEFX_CLIENT_SECRET", secret))

    # Retrieve the daily builds list, if you want the latest production
    # you can skip this step
    builds = service.download.get_daily_builds_list(
        product,
        version=target_release["version"],
        platform="linux",
        only_production=False)

    download_build(service, builds[0], output)


# Return a sidefx.service object allowing access to API functions.
def create_service(client_id, client_secret_key):
    return sidefx.service(
        access_token_url="https://www.sidefx.com/oauth2/application_token",
        client_id=client_id,
        client_secret_key=client_secret_key,
        endpoint_url="https://www.sidefx.com/api/")


# Download the file specified in "build" argument and return the
# downloaded filename on success.
def download_build(service, build, output):
    local_path = os.path.join(output, "houdini-launcher.iso")
    build_info = service.download.get_daily_build_download(
        build["product"], build["version"], build["build"], "linux")
    download_file(build_info["download_url"], local_path)
    return build_info["filename"]


# Download the file hosted on "url" and name it as "filename"
def download_file(url, filename):
    with requests.get(url, stream=True) as response:
        with open(filename, "wb") as open_file:
            shutil.copyfileobj(response.raw, open_file)
    make_executable(filename)


# Add executable privilege to the file specified in "file_path"
def make_executable(file_path):
    stat_info = os.stat(file_path)
    os.chmod(file_path, stat.ST_MODE | stat.S_IEXEC | stat.S_IXUSR |
            stat.S_IXGRP | stat.S_IRUSR | stat.S_IRGRP)


if __name__ == "__main__":
    run_download()
