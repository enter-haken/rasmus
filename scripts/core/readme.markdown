# core schema

The core schema provide informations about

* the user
* the roles
* and the privileges

of rasmus.

all these entities can be defined as you like.

# role leveles

To prevent making normal users to admin, or giving normal users privileges, only admins should have, there are system wide `role_levels`.
They can be attached to `roles` and to `privileges`.

## guest

The `guest` role level is the lowest one. 

## user

The user role level is meant to be for logged in users.

## admin

Roles and privileges  
