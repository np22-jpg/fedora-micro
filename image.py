#!/usr/bin/env python
import argparse
import re
import requests
# import jinja2
# import json

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--node", help="Path to the input file")
    parser.add_argument("--python", help="Path to the output file")
    parser.add_argument("--image", help="Use a fedora base image", \
        default="registry.fedoraproject.org/fedora:latest")

    args = parser.parse_args()

    # print(args)

    node_version = args.node
    python_version = args.python
    base_image = re.split(':|/', args.image)

    if len(base_image) >= 3:
        image = {
            "Remote": base_image[0],
            "Image": base_image[-2],
            "Version": base_image[-1]
        }
    else:
        print("Version not supplied, defaulting to latest")
        image = {
            "Remote": base_image[0],
            "Image": base_image[-1],
            "Version": "latest"
        }

    if python_version is None and node_version is None:
        print(f"Creating micro with {image['Image']}:{image['Version']}")
    elif python_version is None and node_version is str:
        print(f"Creating image node {node_version} {image['Image']}:{image['Version']}")
    elif node_version is None and python_version is str:
        print(f"Creating image python {python_version} {image['Image']}:{image['Version']}")  # noqa: E501
    else: 
        raise Exception("Variables not properly set") 

    return image, node_version, python_version
    
def get_fedora_versions():
    response = requests.get('https://quay.io/api/v1/repository/fedora/tag/')

# Parse the JSON response to extract the tag names
    tags = [tag['name'] for tag in response.json()['tags']]

# Print the list of tags
    print(f"Tags for fedora: {tags}")

    # return versions

def create_template(template, file):
    with open(file, encoding="utf-8", mode="a"):
        pass

if __name__ == '__main__':
    # image, node_version, python_version = parse_args()
    # create_template()
    get_fedora_versions()