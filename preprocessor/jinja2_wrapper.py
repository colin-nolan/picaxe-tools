#!/usr/bin/env python3

from jinja2 import Environment, BaseLoader, FileSystemLoader
import sys
import os


# TODO: Could use to gather import information
class MyLoader(FileSystemLoader):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def get_source(self, environment, template):
        return super().get_source(environment, template)
        # path = join(self.path, template)
        # if not exists(path):
        #     raise TemplateNotFound(template)
        # mtime = getmtime(path)
        # with file(path) as f:
        #     source = f.read().decode('utf-8')
        # return source, path, lambda: mtime == getmtime(path)


def render(file_location: str):
    with open(file_location) as file:
        contents = file.read()
        # TODO: loder location
        template = Environment(loader=MyLoader(os.getcwd(), followlinks=True)).from_string(contents)
        print(template.render())


if __name__ == "__main__":
    render(sys.argv[1])
