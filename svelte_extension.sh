#!/bin/bash

#****************************************************
#* Extends basic Flask app with Svelte frontend     *
#* Written by Ole Holgernes.                        *
#****************************************************

#-> make sure user is superuser
if [ "$EUID" -ne 0 ]
  then echo "Please run as superuser"
  exit
fi

#-> replace main.py file
rm app/main.py
touch app/main.py
cat <<EOT >> app/main.py
from flask import Flask, send_from_directory

app = Flask(__name__)

@app.route("/", methods = ['GET'])
def base():
    return send_from_directory('client/public', 'index.html')

@app.route('/<path:path>')
def home(path):
    return send_from_directory('client/public', path)
EOT

#-> install node.js and npm
apt update
apt install nodejs npm
#-> degit svelte template
cd app/
npx degit sveltejs/template client
cd client/
npm install