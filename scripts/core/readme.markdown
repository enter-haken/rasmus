# core schema

The core schema provide information about

* the user
* the roles
* and the privileges

of `rasmus`.

all these entities can be defined as you like.

# role levels

You can assign role levels to users, privileges and role.

Examples:

* When you have a privilege with the `admin role level`, you can assign this privilege only to a role with the same level.
* You can't assign a user with a `user role level` to a role with an `admin role level`.

## default 

The `default` role level is the lowest one. 

## user

The user role level is meant to be for logged in users.

## admin

Every `privilege` can be assigned to the `admin` role level.

# main tables

## user\_account

When a new `user_account` is created, the `maximum_role_level` decides, which `roles` can be assigned to the `user_account`.

## privilege

Privileges can be used inside of `rasmus` applications.
A privilege can be connected with a `role`.
You can only connect a `privilege` with a `role` with at least the same `role_level`.
Every `privilege` have a `minimum_read_role_level` and a `minimum_write_role_level`.

## role

A `role` can hold multiple `privileges`.
You can define read and write permissions for every privilege of a role.

# post DDL scripts

After the tables are created

* every table have a `created_at`, `updated_at` and `deleted_at` (maybe this will be removed, greets to FB).
* every table will have a `metadata_trigger` function which will update the `updated_at` column.
* every table with a `json_view` column gets a `set_xxx_dirty` and a `set_xxx_undirty` function.
  These are convenient functions for updating the `is_dirty` field.
