STEP 2: Arrival of Envoy 
=============================================

Step 1 was all about getting Docker, Postgres, and Flask to work together. In Step 2, we're going to stick Envoy in front of everything, so it can manage scaling the front end. 

We're still going to keep it simple, but note that "simple" involves _two_ layers of Envoy:

1. First, there's an Envoy running in a separate container. This is the inbound edge proxy for the rest of the world.
2. Second, the edge envoy talks to an Envoy running along the Flask app, in the Flask app's container. The edge envoy and the application envoy(s) form a mesh and share routing information amongst themselves.

Once again, we'll use `docker-compose` to get everything rolling.


The Database
------------

We don't need to change anything in the database for this step.

The Flask App
-------------

In the Flask app, we'll make two small but important changes:

1. We'll switch back to listening only on localhost, so that we _know_ that all traffic is going only through the application envoy(s).

2. We'll have all the calls return the hostname and IP address of their Flask container, so that we can verify what's going on when multiple containers are running.

The Composition File
--------------------

In step 2, we change `docker-compose.yml`:

   - service `edge-envoy` is new. We use a simple Dockerfile to set up the configuration for the edge envoy on top of the `lyft/envoy` image.

   - service `postgres` is the same as last time.

   - service `usersvc` is mostly the same as last time: we change its Dockerfile to copy in the application envoy's configuration, and we change its `entrypoint.sh` to start envoy too. Also, we no longer map port 5000 -- instead we map port 80, where the envoy is listening.

   - network `appmesh` is the same.

Once again, get it all going with

```docker-compose up --build -d```

and doublecheck with

```docker-compose ps```

to see three running containers.

Testing the App
---------------

Once the application is running, the first test is just to make sure its health check says it's OK -- *note well* that the edge envoy is listening on port 8000, not 5000 like Flask is!

```
$ curl $(docker-machine ip esteps):8000/user/health
{
  "hostname": "8351b0efb04c",
  "msg": "user health check OK",
  "ok": true,
  "resolvedname": "172.19.0.2"
}
```

Creating Some Users
-------------------

OK, we need to recreate users, since we dropped the world after Step 1:

```
$ curl -X PUT \
       -H "Content-Type: application/json" \
       -d '{ "fullname": "Alice", "password": "alicerules" }' \
       $(docker-machine ip esteps):8000/user/alice
```

```
$ curl -X PUT \
       -H "Content-Type: application/json" \
       -d '{ "fullname": "Bob", "password": "bobrules" }' \
       $(docker-machine ip esteps):8000/user/bob
```

Once that's done we can verify that our users are really there:

```
$ curl $(docker-machine ip esteps):8000/user/alice
{
  "fullname": "Alice",
  "hostname": "8351b0efb04c",
  "ok": true,
  "resolvedname": "172.19.0.2",
  "uuid": "2B199DE4DE694BD5BF944842D6F28426"
}

$ curl $(docker-machine ip esteps):8000/user/bob
{
  "fullname": "Bob",
  "hostname": "8351b0efb04c",
  "ok": true,
  "resolvedname": "172.19.0.2",
  "uuid": "F71CD56313E04806853D7CA2251928A0"
}
```

Scaling the Flask App
=====================

One of the promises of Envoy is helping with scaling applications. Let's see how well it handles that by scaling up to multiple instances of our Flask app.

```docker-compose scale usersvc=3```

Once that's done, `docker-compose ps` should show 5 containers running, not three. We should then be able to see `curl` getting routed to multiple hosts, e.g.:

```
$ curl $(docker-machine ip esteps):8000/user/health
{
  "hostname": "384645637ea4",
  "msg": "user health check OK",
  "ok": true,
  "resolvedname": "172.19.0.6"
}

$ curl $(docker-machine ip esteps):8000/user/health
{
  "hostname": "79a80cafa7c8",
  "msg": "user health check OK",
  "ok": true,
  "resolvedname": "172.19.0.5"
}
```

But, of course, asking for the details of user `alice` should always give the same results, no matter which host does the database lookup:

```
$ curl $(docker-machine ip esteps):8000/user/alice
{
  "fullname": "Alice",
  "hostname": "79a80cafa7c8",
  "ok": true,
  "resolvedname": "172.19.0.5",
  "uuid": "2B199DE4DE694BD5BF944842D6F28426"
}

$ curl $(docker-machine ip esteps):8000/user/alice
{
  "fullname": "Alice",
  "hostname": "573b8d10e9d6",
  "ok": true,
  "resolvedname": "172.19.0.2",
  "uuid": "2B199DE4DE694BD5BF944842D6F28426"
}
```

Up Next
=======

We have everything working _including_ using Envoy to handle round-robining traffic between our several Flask apps. With `docker-compose scale`, we can easily change the number of instances of Flask apps we're running.

Next up, we'll start digging into the various ways Envoy can do load balancing: there are a lot of options.

And, as before, we sadly need to tear everything down before moving on to Step 2, because of how docker-compose works:

```docker-compose down```

After that, it's off to Step 3.
