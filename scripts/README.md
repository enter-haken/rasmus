# rasmus database

These scripts bootstrapes the `rasmus` database.
The `rasmus` database consists of multiple schemas.

## schema

### core

The `core` contains relations for

* user management
* role management
* data transfer management

### cms

The `cms` contains relations for 

* articles
* categories
* attachments

## build

    $ make

will drop the schema `core` and `cms`, create tables and stored procedures and add some seed data.
Currently only 'play data' is inserted.

    $ make clean

will drop the schema `core` and `cms`.
