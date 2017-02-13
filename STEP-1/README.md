STEP 1: Docker and Postgres and Flask, oh my!
=============================================

Step 1 is all about getting Docker, Postgres, and Flask to work together. You'll note that Envoy is _not_ mentioned above: walk, then run. 

We're going to work with a very, very simple application that will start out only being able to create users, delete users, and process simple logins. Obviously this isn't very interesting by itself! but:

1. It requires persistent storage, so we'll have to tackle that early.
2. It will let us explore scaling the different pieces of the application.
3. It will let us explore Envoy at the edge, where the user's client talks to our application, and
4. It will let us explore Envoy internally, brokering communications between the Flask part of the app and the database.

We'll start by using `docker-compose` to create an application with a Flask front end to a Postgres database. 

The Database
------------

The database part of our world is really simple -- it has exactly one table:

```
CREATE TABLE IF NOT EXISTS users (
    uuid VARCHAR(64) NOT NULL PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    fullname VARCHAR(2048) NOT NULL,
    password VARCHAR(256) NOT NULL
)
```

where, hopefully, the columns are all self-explanatory (though it's worth noting that while usernames must be unique, we use the UUID as the primary key to make it easier for users to change their usernames later).

The Flask App
-------------

The Flask app lives in `user-service/service.py` and is hopefully fairly easy to follow. The main complication is that, when the Flask app starts, the database may not exist!

At present, the Flask app simply creates the database if it's not present, relying on Postgres to make sure that there can be no more than one instance of the database itself. This is guaranteed to work right now because we have exactly one instance of the `postgres` container -- more on this front as we work on scaling the database, later.

One important note: by default, Flask will listen _only_ on the loopback address. That will prevent connecting from the host running `docker-compose`, even given a `ports` directive that exposes the port, so our Flask app explicitly listens on `0.0.0.0`.

The Composition File
--------------------

`docker-compose.yml` specifies the definition of our application. We get started with just two services and one network:

   - service `postgres` is the database. Since we don't have to customize it, we don't use a Dockerfile to build it; we just pull down the `postgres:9.6` image and run it.

   - service `usersvc` is the Flash app. This one we do need a custom build for, and `user-service/Dockerfile` defines that. Note that we go ahead and base this on the `lyft/envoy` image -- we know we're going to be doing Envoy later, so we'll get that bit rolling early.

   The rest of the Dockerfile is basically about getting `pip` and `flask` set up, and launching our Flask app. We use an `entrypoint` script for that because we'll have to start Envoy later, too.

   - network `appmesh` is just the network the pieces talk on.

Get it all going with

```docker-compose up --build -d```

Once that's done, you should be able to use

```docker-compose ps```

and see two running containers.

Testing the App
---------------

Once the application is running, the first test is just to make sure its health check says it's OK:

```
$ curl $(docker-machine ip esteps):5000/user/health
{
  "msg": "user health check OK",
  "ok": true
}
```

A Note on Debugging and Updates
-------------------------------

We'll get much more into debugging later, but one useful thing to know: obviously, when debugging the Flask app, you can always make modifications and then

```docker-compose up --build -d```

to reinitialize everything. However, since we're running Flask in debug mode, there's a quicker way: just copy the new Flask app into place in the `usersvc` container and let it restart.

```
docker cp user-service/service.py \
       $(docker-compose ps -q usersvc):/application/service.py
```

Creating Some Users
-------------------

OK, let's go ahead and create two test users. This will both vet the database connection and get us set up for later steps.

```
$ curl -X PUT \
       -H "Content-Type: application/json" \
       -d '{ "fullname": "Alice", "password": "alicerules" }' \
       $(docker-machine ip esteps):5000/user/alice
```

```
$ curl -X PUT \
       -H "Content-Type: application/json" \
       -d '{ "fullname": "Bob", "password": "bobrules" }' \
       $(docker-machine ip esteps):5000/user/bob
```

Once that's done we can verify that our users are really there:

```
$ curl $(docker-machine ip esteps):5000/user/alice
{
  "fullname": "Alice",
  "ok": true,
  "uuid": "5D8B3490C1A64F4AB06DE0C0B8AF815E"
}

$ curl $(docker-machine ip esteps):5000/user/bob
{
  "fullname": "Bob",
  "ok": true,
  "uuid": "3AEDE558635944CEA09C2CA5A7289413"
}

```

Up Next
=======

We have everything working without Envoy, with just one instance of our Flask app. Next we'll work on bringing Envoy into the fold. Sadly, we need to tear everything down before moving on to Step 2, because of how docker-compose works:

```docker-compose down```

After that, it's off to Step 2.


