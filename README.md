<br />
<p align="center">
    <img src="static/terra.png"/>
    <h3 align="center">Luna</h3>
    <p align="center">
        Production tracking API
    </p>
</p>

## Summary

Luna is a horizontally scalable microservice that provides an API for tracking production data. It is built using the
FastAPI framework and is designed to be deployed in a Kubernetes cluster. The default backend is a MongoDB database, but
it does have the ability to use other data sources such as ShotGrid or FTrack.

## Development

> **IMPORTANT:** You **MUST** use a Linux environment for development.

Following the standard Juno micro service structure, Luna is built using the following technologies

- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [skaffold](https://skaffold.dev/) - Kubernetes development tool

To launch the development environment, you only need to run the following command:

```bash
make dev
```

This will launch the Luna microservice in a local Kubernetes cluster using kind. You can then access the service at
[http://localhost:8000/luna/docs](http://localhost:8000/luna/docs).

To stop the development environment, first press `ctrl + c` and then run the following command:

```bash
make down
```

This will shutdown the local Kubernetes cluster and remove all resources.
