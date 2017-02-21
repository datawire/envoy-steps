#!/usr/bin/env python

import logging
import os
import socket
import time
import uuid

import pg8000
from flask import Flask, jsonify, request

pg8000.paramstyle = 'named'

logPath = "/tmp/flasklog"

MyHostName = socket.gethostname()
MyResolvedName = socket.gethostbyname(socket.gethostname())

logging.basicConfig(
    filename=logPath,
    level=logging.DEBUG, # if appDebug else logging.INFO,
    format="%(asctime)s esteps-user 0.0.1 %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

logging.info("esteps-user initializing on %s (resolved %s)" % (MyHostName, MyResolvedName))

app = Flask(__name__)

USER_TABLE_SQL = '''
CREATE TABLE IF NOT EXISTS users (
    uuid VARCHAR(64) NOT NULL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    fullname VARCHAR(2048) NOT NULL,
    password VARCHAR(256) NOT NULL
)
'''

class RichStatus (object):
    def __init__(self, ok, **kwargs):
        self.ok = ok
        self.info = kwargs
        self.info['hostname'] = MyHostName
        self.info['resolvedname'] = MyResolvedName

    # Remember that __getattr__ is called only as a last resort if the key
    # isn't a normal attr.
    def __getattr__(self, key):
        return self.info.get(key)

    def __nonzero__(self):
        return self.ok

    def __str__(self):
        attrs = ["%=%s" % (key, self.info[key]) for key in sorted(self.info.keys())]
        astr = " ".join(attrs)

        if astr:
            astr = " " + astr

        return "<RichStatus %s%s>" % ("OK" if self else "BAD", astr)

    def toDict(self):
        d = { 'ok': self.ok }

        for key in self.info.keys():
            d[key] = self.info[key]

        return d

    @classmethod
    def fromError(self, error, **kwargs):
        kwargs['error'] = error
        return RichStatus(False, **kwargs)

    @classmethod
    def OK(self, **kwargs):
        return RichStatus(True, **kwargs)

def get_db(database):
    db_host = "postgres"
    db_port = 5432

    if "USER_DB_RESOURCE_HOST" in os.environ:
        db_host = os.environ["USER_DB_RESOURCE_HOST"]

    if "USER_DB_RESOURCE_PORT" in os.environ:
        db_port = int(os.environ["USER_DB_RESOURCE_PORT"])

    return pg8000.connect(user="postgres", password="postgres",
                          database=database, host=db_host, port=db_port)

def setup():
    try:
        conn = get_db("postgres")
        conn.autocommit = True

        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = 'users'")
        results = cursor.fetchall()

        if not results:
            cursor.execute("CREATE DATABASE users")

        conn.close()
    except pg8000.Error as e:
        return RichStatus.fromError("no user database in setup: %s" % e)

    try:
        conn = get_db("users")
        cursor = conn.cursor()
        cursor.execute(USER_TABLE_SQL)
        conn.commit()
        conn.close()
    except pg8000.Error as e:
        return RichStatus.fromError("no user table in setup: %s" % e)

    return RichStatus.OK()

def getIncomingJSON(req, *needed):
    try:
        incoming = req.get_json()
    except Exception as e:
        return RichStatus.fromError("invalid JSON: %s" % e)

    logging.debug("getIncomingJSON: %s" % incoming)

    if not incoming:
        incoming = {}

    missing = []

    for key in needed:
        if key not in incoming:
            missing.append(key)

    if missing:
        return RichStatus.fromError("Required fields missing: %s" % " ".join(missing))
    else:
        return RichStatus.OK(**incoming)

########
# USER CRUD

def handle_user_get(req, username):
    try:
        conn = get_db("users")
        cursor = conn.cursor()

        cursor.execute("SELECT uuid, fullname FROM users WHERE username = :username", locals())
        [ useruuid, fullname ] = cursor.fetchone()

        return RichStatus.OK(uuid=useruuid, fullname=fullname)
    except pg8000.Error as e:
        return RichStatus.fromError("%s: could not fetch info: %s" % (username, e))

def handle_user_put(req, username):
    try:
        rc = getIncomingJSON(req, 'fullname', 'password')

        logging.debug("handle_user_put %s: got args %s" % (username, rc.toDict()))

        if not rc:
            return rc

        fullname = rc.fullname
        password = rc.password

        useruuid = uuid.uuid4().hex.upper();

        logging.debug("handle_user_put %s: useruuid %s" % (username, useruuid))

        conn = get_db("users")
        cursor = conn.cursor()

        cursor.execute('INSERT INTO users VALUES(:useruuid, :username, :fullname, :password)', locals())
        conn.commit()

        return RichStatus.OK(uuid=useruuid, fullname=fullname)
    except pg8000.Error as e:
        return RichStatus.fromError("%s: could not save info: %s" % (username, e))

@app.route('/user/<username>', methods=[ 'PUT', 'GET' ])
def handle_user(username):
    rc = RichStatus.fromError("impossible error")
    logging.debug("handle_user %s: method %s" % (username, request.method))
    
    try:
        rc = setup()

        if rc:
            if request.method == 'PUT':
                rc = handle_user_put(request, username)
            else:
                rc = handle_user_get(request, username)
    except Exception as e:
        rc = RichStatus.fromError("%s: %s failed: %s" % (username, request.method, e))

    return jsonify(rc.toDict())

@app.route('/user/health')
def root():
    rc = RichStatus.OK(msg="user health check OK")

    return jsonify(rc.toDict())

def main():
    app.run(host='0.0.0.0', port=5000, debug=True)

if __name__ == '__main__':
    setup()
    main()
