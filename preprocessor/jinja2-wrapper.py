#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader, FunctionLoader
import sys
import os


class AnyFileSystemLoader(FileSystemLoader):
    """ Loader able to handle any file path. """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if len(self.searchpath) != 1:
            raise ValueError("searchpath can only include a single path")

    def get_source(self, environment, template):
        if not os.path.isabs(template):
            template = os.path.join(self.searchpath[0], template)

        original_searchpath = self.searchpath[0]
        try:
            self.searchpath[0] = os.path.dirname(template)
            filename = os.path.basename(template)
            return super().get_source(environment, filename)
        finally:
            self.searchpath[0] = original_searchpath


def render(file_location: str, context: str):
    with open(file_location) as file:
        contents = file.read()
        template = Environment(loader=AnyFileSystemLoader(context, followlinks=True)).from_string(contents)
        print(template.render())


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2])
