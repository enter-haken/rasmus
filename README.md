# rasmus

a alternative content management system approach

This is a *pre alpha* version.

## motivation

see [Alternative content management system approach](http://enter-haken.github.io/posts/2018-02-19-rasmus.html).
More progress on this work will be published on [enter-haken](http://enter-haken.github.io).

## stack

* `rasmus` uses `PostgreSQL` as a database backend.
* `elixir` is used for the application backend.

## build

### requirements

* elixir 1.5.2 with erlang >= 20
* PostgreSQL >= 9.0

The standard user `postgres` must exist to create the database for `rasmus`.

### compile

A simple 

    $ make

will create the schema `core` and `cms` for `rasmus`.
It will also compile the `elixir` backend and the documentation.

At the moment, the database will be reset on every `make` call.

## run

    $ make run

The backend is started within the `iex` shell.

## database schema

When you have successfully executed `make` for the first time you can take a look at the database schema `core`.

    $ make core_schema

This will put a `core_schema.png` file into the projects root folder.

# contact

Jan Frederik Hake, <jan_hake@gmx.de>. [@enter_haken](https://twitter.com/enter_haken) on Twitter.


