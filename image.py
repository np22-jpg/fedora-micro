#!/usr/bin/env python3
import json
from jinja2 import Environment, FileSystemLoader, select_autoescape
import tempfile

with open("versions.json", 'r') as j:
    buildvars = json.loads(j.read())

env = Environment(
    loader=FileSystemLoader("templates"),
    autoescape=select_autoescape()
)

vars = buildvars['python3_dev']
template = env.get_template("python-build.jinja")


tmp = tempfile.NamedTemporaryFile(delete=False)
with open(tmp.name, 'w') as tempfile:
    tempfile.write(template.render(**vars))
    print(tempfile.name)