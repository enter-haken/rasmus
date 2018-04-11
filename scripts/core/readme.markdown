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

# user\_account

When a new `user_account` is created, the `maximum_role_level` decides, which `roles` can be assigned to the `user_account`.
