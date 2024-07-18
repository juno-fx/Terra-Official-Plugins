"""
Cloning down a repository from a Git Source to a target directory.
"""

# std
import os

# 3rd
from git import Repo
from terra import Plugin


class GitLoader(Plugin):
    """
    Git Loader
    """

    _alias_ = "Git Loader"
    icon = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
    description = "Clone down a repository from a Git Source"
    fields = [
        Plugin.field("url", "Git URL", required=True),
        Plugin.field("ref", "Git Ref", required=True),
        Plugin.field("destination", "Destination directory", required=True)
    ]

    def preflight(self, *args, **kwargs) -> bool:
        """
        Check if the target directory exists
        """
        # store on instance
        self.url = kwargs.get("url")
        self.ref = kwargs.get("ref")
        self.destination = kwargs.get("destination")

        # validate
        if not self.url:
            raise ValueError("No git url provided")

        if not self.ref:
            raise ValueError("No git ref provided")

        if not self.destination:
            raise ValueError("No destination directory provided")

        if not self.destination.endswith("/"):
            self.destination += "/"

    def install(self, *args, **kwargs) -> None:
        """
        Run git pull and install to the target directory
        """
        self.logger.info(f"Cloning {self.url} to {self.destination}")
        if not os.path.exists(self.destination):
            Repo.clone_from(self.url, self.destination)
        self.logger.info(f"Checking out {self.ref}")
        repo = Repo(self.destination)
        repo.git.checkout(self.ref)
