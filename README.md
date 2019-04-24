# quick-fastapi-server-setup

* This (admittedly rickety) script sets up an environment that will run FastAPI with gunicorn and nginx in Ubuntu 18.04

* It was modeled for a DigitalOcean droplet, but uses the standard tools.

* It's very "opinionated" (a fashionable word): assumes or creates an username `apiserver` and creates a Python virtualenv `apiserver`. Also assumes your app code is in github, gitlab or similar.

## How to use

1) Edit `apiserver_setup.sh` to reflect your repository and ip address
2) Run, as root (not sudo; this is meant for a clean new machine) `./root_setup.sh`. This file will set up the "apiserver" user and run `apiserver_setup` automatically.
  * Enter a password (any password; this is just for sudo, remote login is disabled) for the user apiserver when prompted.
  * This password may be asked a second time to run the rest of the setup as user apiserver
  * A private/public key pair will be generated, and the screen will pause so  you can copy/paste a new public key for the github/gitlab repository.
