#!/bin/bash

#****************************************************
#* Creates a basic framework for a Flask website in *
#* current working directory using Python 3.8.      *
#* Written by Ole Holgernes.                        *
#****************************************************

# settings
create_pipenv=1 # set to 1 to create virtual env using pipenv
create_repo=0 # set to 1 to run git init
configure_vscode=1 # set to 1 to add pipenv interpreter path to local vscode config file. Requires pipenv.
containerize=1 # set to 1 to create a Docker container serving the app w gunicorn. Requires pipenv.

echo "Creating framework for a basic flask website."
#-> initialize empty git repo
if [[ "$create_repo" -eq 1 ]]; then
    git init
    git branch -m master main
    touch .gitignore
    cat <<EOT >> .gitignore
__pycache__/
.venv/
.devcontainer/
.vsconfig/
EOT
else
    echo "Skipping git init"
fi
#-> create virtual environment
if [[ "$create_pipenv" -eq 1 ]]; then
    mkdir .venv
    python3 -m pip install pipenv
    python3 -m pipenv install --python 3.8
    python3 -m pipenv install flask
else
    echo "Skipping virtual environment"
fi
#-> configure vscode pipenv interpreter path
if [[ "$configure_vscode" -eq 1 ]]; then
    pipenv_path="$(python3 -m pipenv --venv)"
    mkdir .vscode
    cat <<EOT >> .vscode/settings.json
{
    "python.defaultInterpreterPath": "$(echo $pipenv_path)",
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/*.pyc": true,
        "**/__pycache__": true
    }
}
EOT
else
    echo "Skipping vscode config"
fi
#-> create dockerfile
if [[ "$containerize" -eq 1 ]]; then
    python3 -m pipenv install gunicorn
    touch Dockerfile .dockerignore
    mkdir .devcontainer
    touch .devcontainer/devcontainer.json
    cat <<EOT >> Dockerfile
FROM python:3.8-slim-buster AS base

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

FROM base AS python-deps

RUN pip install pipenv
RUN apt-get update && apt-get install -y --no-install-recommends

COPY Pipfile .
COPY Pipfile.lock .
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

FROM base AS runtime
#copy virtual env from python-deps stage 
#/.venv location is set by PIPENV_VENV_IN_PROJECT
COPY --from=python-deps /.venv /.venv
ENV PATH="/.venv/bin:$PATH"

# install application into container
COPY . .

WORKDIR /app/

EXPOSE 8000
ENTRYPOINT ["gunicorn", "-c", "gunicorn.conf.py", "main:app"]
EOT
#-> configure vscode devcontainer
    if [[ "$configure_vscode" -eq 1 ]]; then
        cat <<EOT >> .devcontainer/devcontainer.json
{
	"name": "Base Flask Container",
	"context": "..",
	"dockerFile": "../Dockerfile"
}
EOT
    else
        echo "Skipping vscode .devcontainer config"
    fi
else
    echo "Skipping dockerfile"
fi
#-> create basic folder structure
mkdir app
mkdir app/tests app/templates app/static
mkdir app/static/images app/static/scripts app/static/styles
#-> create empty files
touch app/main.py app/templates/base.html app/templates/index.html
touch app/static/styles/styles.css app/static/styles/init_script.js app/__init__.py
touch app/gunicorn.conf.py
#-> boilerplate code
cat <<EOT >> app/main.py
from flask import Flask, render_template
app = Flask(__name__)
@app.route("/", methods = ['GET'])
def form_view():
    return render_template('index.html')
EOT

cat <<EOT >> app/templates/base.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href = "{{ url_for('static', filename='styles/styles.css') }}">
    <!-- Bootstrap 5 import -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">
    <title>Document</title>
</head>
<body>
    <div class = "content container">
        {% block content %}
        {% endblock %}
    </div>
    <!-- local script import -->
    <script src="{{ url_for('static', filename='scripts/init_script.js') }}"></script>
</body>
</html>
EOT

cat <<EOT >> app/gunicorn.conf.py
workers = 2
bind = "0.0.0.0:8000"
EOT
