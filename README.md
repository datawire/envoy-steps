Envoy Step By Step
==================

This is a simple example of how one can use Envoy to create scalable Flask apps.

The Tools
---------

Tools we'll be using:

1. [minikube](https://github.com/kubernetes/minikube)
2. [envoy](https://lyft.github.io/envoy/)

You'll need to get Minikube installed before starting. You do _not_ need to install `envoy` though! It will magically Just Happen as we build containers out.

The Process
-----------

We're going to work with a very, very simple application: a simple Flask app that allows creating users, then reading them back.

Step 0: Minikube
================

First we need to start Minikube. On a Mac for your first startup, you need to decide if you're going to use the VirtualBox driver for Minikube, or the `xhyve` driver. I use `xhyve`:

```minikube start --vm-driver xhyve```

Once minikube is started, run

```eval $(minikube docker-env)```

to get hooked up to the Minikube Docker daemon (which we'll be using when we build Docker images later).

Step 1: Basic Flask App
=======================

Start the Postgres and `usersvc` containers:

```
sh postgres/up.sh
sh usersvc/up.sh
```

and then you should be able to check things out:

```
curl $(minikube service --url usersvc)/user/health
```

should show you something like

```
{ 
  "hostname": "usersvc-1941676296-zlrt2",
  "msg": "user health check OK",
  "ok": true,
  "resolvedname": "172.17.0.10" 
}
```

Next up we can try saving and retrieving a user:

```
curl -X PUT \
     -H "Content-Type: application/json" \
     -d '{ "fullname": "Alice", "password": "alicerules" }' \
     $(minikube service --url usersvc)/user/alice
```

This should give us a user record for Alice, including her UUID but not her password:

```
{
  "fullname": "Alice",
  "hostname": "usersvc-1941676296-zlrt2",
  "ok": true,
  "resolvedname": "172.17.0.10",
  "uuid": "44FD5687B15B4AF78753E33E6A2B033B" 
}
```

and we should be able to read the user back (sans password again) with

```
curl $(minikube service --url usersvc)/user/alice
```

Step 2: Enter Envoy
===================

Start the `edge-envoy` container:

```
sh edge-envoy/up.sh
```

then drop the `usersvc` container and replace it with the `usersvc2` container:

```
sh usersvc/down.sh
sh usersvc2/up.sh
```

and now going through Envoy should work:

```
curl $(minikube service --url edge-envoy)/user/health
curl $(minikube service --url edge-envoy)/user/alice
```

Step 3: Scaling the App
=======================

We can scale the app pretty simply:

```
kubectl scale --replicas=3 deployment/usersvc
```

but that will reveal that the DNS discovery we've been using so far won't work. We need to bring Envoy's Service Discovery Service into play:

```
sh usersvc-sds/up.sh
sh edge-envoy/down.sh
sh edge-envoy2/up.sh
```

and once that's done, you'll be able to see requests cycling through all the `usersvc` endpoints.

