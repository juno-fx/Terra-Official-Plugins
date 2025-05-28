"""Description: This script will download a specific Houdini build from the SideFX website."""

import os
import sys

import hashlib
import shutil
import click
import requests

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
        "version": os.environ.get("HOUDINI_VERSION", str(version)),
        "build": os.environ.get("HOUDINI_BUILD", str(build)),
        "release": "gold",
        "platform": "linux_x86_64_gcc9.3",
        "product": "houdini",
    }

    # This service object retrieve a token using your Application ID and secret
    service = sidefx.service(
        access_token_url="https://www.sidefx.com/oauth2/application_token",
        client_id=os.environ.get("SIDEFX_CLIENT_ID", key),
        client_secret_key=os.environ.get("SIDEFX_CLIENT_SECRET", secret),
        endpoint_url="https://www.sidefx.com/api/",
    )

    # Retrieve the daily builds list, if you want the latest production
    # you can skip this step
    releases_list = service.download.get_daily_builds_list(
        product=target_release["product"],
        version=target_release["version"],
        platform="linux",
    )

    for _got_version in releases_list:
        if _got_version["platform"]:
            if (
                _got_version["platform"] == target_release["platform"]
                and _got_version["release"] == target_release["release"]
            ):
                if _got_version["build"] == target_release["build"]:
                    print(_got_version)
                    _download_release = _got_version

    # Retrieve the latest daily build available
    _download_release = service.download.get_daily_build_download(
        product=target_release["product"],
        version=target_release["version"],
        build=target_release["build"],
        platform="linux",
    )

    # Download the file
    local_filename = os.path.join(output, "houdini.tar.gz")
    r = requests.get(_download_release["download_url"], stream=True, timeout=90)
    if r.status_code == 200:
        with open(local_filename, "wb") as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
    else:
        raise InterruptedError("Error downloading file!")

    # Verify the file checksum is matching
    file_hash = hashlib.md5()
    with open(local_filename, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            file_hash.update(chunk)
    if file_hash.hexdigest() != _download_release["hash"]:
        raise ValueError("Checksum does not match!")


if __name__ == "__main__":
    run_download()
