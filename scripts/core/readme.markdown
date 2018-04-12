# core schema

The core schema provide information about

* the user
* the roles
* and the privileges

of `rasmus`.

all these entities can be defined as you like.

# main tables

## user\_account

The `user_account` holds information about a `rasmus user`.
You have to provide at least a `login` and an `email_address`.

## privilege

Privileges can be used inside of `rasmus` applications.
You have to give a privilege a unique `name`.
A privilege can be assigned to a `role`.

## role

A `role` can hold multiple `privileges`.
You can define read and write permissions for every privilege of a role.

# transfer

TBA

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
