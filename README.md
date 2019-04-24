# quick-fastapi-server-setup

* This (admittedly rickety) script sets up an environment that will run FastAPI with gunicorn and nginx in Ubuntu 18.04

* It was modeled for a DigitalOcean droplet, but uses the standard tools.

* It's very "opinionated" (a fashionable word): assumes or creates an username `apiserver` and creates a Python virtualenv `apiserver`. Also assumes your app code is in github, gitlab or similar.
