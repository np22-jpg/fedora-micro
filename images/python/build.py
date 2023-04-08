from jinja2 import Environment, FileSystemLoader, select_autoescape

def write(vars):

    vars=vars['python3_dev']

    env = Environment(
        loader=FileSystemLoader("templates/python"),
        autoescape=select_autoescape()
    )

    # Dockerfile = tempfile.NamedTemporaryFile(delete=False)
    template = env.get_template("python-build.jinja")

    with open("out/Python.Dockerfile", 'w') as temp:
        temp.write(template.render(**vars))
        
    # return temp.name
