Envoy Step By Step
==================

This is a simple example of how one can use Envoy to create scalable Flask apps.

The Tools
---------

Tools we'll be using:

1. [docker](https://www.docker.com/)
2. [docker-compose](https://docs.docker.com/compose/)
3. [envoy](https://lyft.github.io/envoy/)

You'll need to get `docker` and `docker-compose` installed (Mac users, see below). You do _not_ need to install `envoy` though! It will magically Just Happen as we build containers out.

MAC USERS TAKE NOTE
-------------------

If (like me) you're on a Mac, the Docker driver matters. I've been using the `xhyve` driver because I don't feel like installing VirtualBox on my Mac, but there's an issue with this: the `xhyve` driver doesn't do the right thing with mounting host files in the container. 

In the Official Envoy Examples, the `envoy` config files are mounted in containers, just to make things easier when tweaking `envoy` configs. We don't do that in this walkthrough, because it doesn't work on my Mac.

The Process
-----------

We're going to work with a very, very simple application. We've broken the process up into steps -- to follow along, you'll go through each step by looking at the `README.md` in that step's directory.

So let's get started!

Step 0: The Docker Machine
==========================

We'll use a `docker-machine` called "esteps" for this example, so let's get that set up. On my Mac, that's

```
docker-machine create --driver xhyve esteps
eval $(docker-machine env esteps)
```

The `xhyve` driver is specific to the Mac; Linux users should drop the `--driver` parameter.

Step 1: Postgres and Docker and Flask, oh my!
=============================================

We'll start by using `docker-compose` to create an application with a Flask front end to a Postgres database. Check it out in `STEP-1/README.md`.

