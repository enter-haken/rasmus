# core schema

The core schema provide information about

* the user
* the roles
* and the privileges

of rasmus.

all these entities can be defined as you like.

# role levels

To prevent making normal users to admin, or giving normal users privileges, only admins should have, there are system wide `role_levels`.
They can be attached to `roles` and to `privileges`.

## default 

The `guest` role level is the lowest one. 

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
You can only connect a `privilege' with a `role` with at least the same `role_level`.
Every `privilege` have a `minimum_read_role_level` and a `minimum_write_role_level`.

## role

A `role` can hold multiple `privileges`

# post DDL scripts

After the tables are created

* every table have a `created_at`, `updated_at` and `deleted_at` (maybe this will be removed, greets to FB).
* every table will have a `metadata_trigger` function which will update the `updated_at` column.
* every table with a `json_view` column gets a `set_xxx_dirty` and a `set_xxx_undirty` function.
  These are convenient functions for updating the `is_dirty` field.
