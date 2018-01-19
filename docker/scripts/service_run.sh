#!/bin/sh
APP_DIR="/usr/local/flask"

# run app
sudo service nginx start
sudo nohup uwsgi --ini ${APP_DIR}/uwsgi.ini &

