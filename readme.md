# rasmus

show how information is connected within a graph 

This is a *pre alpha* version.

![][rasmusFrontend]

## motivation

As I worked on an [alternative content management system approach](http://enter-haken.github.io/posts/2018-02-19-rasmus.html),
I came up with an idea to show browser links in an alternative way.
In a first step, I will visualize browser links in a graph like visualisation.

More progress on this work will be published on [enter-haken](http://enter-haken.github.io).

## stack

* `rasmus` uses `PostgreSQL` as a database backend.
* `elixir` is used for the application backend.

## build

### requirements

For the backend

* elixir 1.5.2 with erlang >= 20
* PostgreSQL >= 9.0

The standard user `postgres` must exist to create the database for `rasmus`.

For the `frontend`

* nodejs >= 8.11
* yarn >= 1.6.0

For the `landing page`  

* yarn >= 1.6.0
* gulp >= 3.9.1

### compile

A simple 

    $ make

will create the schema `core` for `rasmus`.
At the moment, the database will be reset on every `make` call.

It will also compile the `elixir` backend, the documentation, the frontend and the landing page.

When you need an update for either the `frontend` or the `landing_page` you need to

    $ make deploy

the projects.


### run

    $ make run

The backend is started within the `iex` shell.

## database schema

When you have successfully executed `make` for the first time you can take a look at the database schema `core`.

    $ make core_schema

This will put a `core_schema.png` file into the projects root folder.

# contact

Jan Frederik Hake, <jan_hake@gmx.de>. [@enter_haken](https://twitter.com/enter_haken) on Twitter.

[rasmusFrontend]: readme_images/rasmus_frontend.png
