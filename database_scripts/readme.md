# base database tables 

## user

The `user` holds information about a `rasmus user`.
You have to provide at least a `login` and an `email_address`.

## privilege

Privileges can be used inside of `rasmus` applications.
You have to give a privilege a unique `name`.
A privilege can be assigned to a `role`.

## role

A `role` can hold multiple `privileges`.
You can define read and write permissions for every privilege of a role.

## person

Used for storing `contacts`

## link

Storing web links.

## list

todo lists.

## appointment

single or group appointments

## graph_edge

This table stores all information neccessary to build a graph.
You can build edges over all entities (currently `person`, `link`, `list` and `appointment`).

# transfer

The `transfer` table is the entry point to the database.
It has a `state` column, which indicates the current state of the request.
The states are a first draft. They will be narrowed down to a minimum, when the development goes on.

* `pending`: This is the default state, when a request is inserted.
Pending means, that the request is not yet processed by the database.

* `processing` is a kind of lock.
The database is currently working on a request.

* When a request has `succeeded`, a NOTIFY is send to the backend.

* `succeeded_with_warning` is a successful request, but there are some hints in the response about possible errors.

* When request fails, the request is set to an `error` state.
There are additional information in the response object.

## request

The request must at least have the following structure.
It is a kind of contract or interface, made with the database backend.

    {
        "action": "add",
        "schema": "core",
        "entity": "role",
        "data": {
            "somejson": "object"
        }
    }

`ToDo`: add user specific data to request.

## response

The `response` column is filled, when the request is processed.
A succeeded request will have an `data` object, with an optional `info` and `warning` field.

    {
        "warning": [
            "the response has some issues",
            "maybe one more"
        ],
        "info": [
            "look at this info",
            "this may be also interesting"
        ],
        "data": {
            "result": "object"
        }
    }

If an `error` occurs, the data field will be empty

    {
        "error": {
            "message": "an error occured"
        },
        "data": null
    }

`ToDo`: Are the texts for warning, info and error sufficient? 
Replace with more complex objects if necessary.

# role levels

You can assign role levels to users, privileges and roles.

Examples:

* When you have a privilege with the `admin role level`, you can assign this privilege only to a role with the same level.
* You can't assign a user with a `user role level` to a role with an `admin role level`.

At the moment there are two role levels.

## user

The user role level is meant to be for logged in users.

## admin

Every `privilege` can be assigned to the `admin` role level.

# post DDL scripts

After the tables are created

* every table have a `created_at`, `updated_at` and `deleted_at` (maybe this will be removed, greets to FB).
* every table will have a `metadata_trigger` function which will update the `updated_at` column.
* every table with a `json_view` column gets a `set_xxx_dirty` and a `set_xxx_undirty` function.
  These are convenient functions for updating the `is_dirty` field.
