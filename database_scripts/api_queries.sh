#!/bin/bash

API_URL="http://localhost:8080/api"

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"dashboard", "description": "show dashboard", "minimum_read_role_level":"user"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"news", "description": "show news feed", "minimum_read_role_level":"user"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"user_management", "description": "work with systemwide user management"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"role_management", "description": "work with systemwide role management"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"privilege_management", "description": "work with systemwide privilege management"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"role", "data": {"name":"admin", "description": "the admin can do everything within the instance"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"role", "data": {"name":"user", "description": "this is the standard user role"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"user", "data" : {"first_name":"Jan Frederik", "last_name": "Hake", "email_address": "jan_hake@gmx.de", "login": "jan_hake"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"privilege"}' $API_URL

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"privilege", "data": { "name" : "dash"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"role"}' $API_URL

# wait two seconds, until the user is persisted. async operation. this is only for testing.
sleep 2 

USER_ID=`psql -U postgres -d rasmus -c "select id from rasmus.user" | sed -e '1,2d' -e '4,5d' -e 's/^ //'`
ADMIN_ROLE_ID=`psql -U postgres -d rasmus -c "select id from rasmus.role where name = 'admin'" | sed -e '1,2d' -e '4,5d' -e 's/^ //'`

curl -H "Content-Type: application/json" -d '{"action":"update","entity":"user", "data" : { "id" : "'"$USER_ID"'", "first_name" : "Jan"}}' $API_URL

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"user"}' $API_URL

# example links / nodes describing rasmus itself

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "otp tree",
      "description": "process configuration",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/rasmus_app.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "router",
      "description": "cowboy router",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/web/router.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "counter",
      "description": "listen to notifications\nfrom database",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/core/counter.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "inbound",
      "description": "send requests towards\nthe database",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/core/inbound.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "manager",
      "description": "execute the\ndatabase manager",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/core/manager.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "client",
      "description": "react / visjs app",
      "url": "https://github.com/enter-haken/rasmus/blob/master/lib/core/manager.ex"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "configuration",
      "description": "database configuration",
      "url": "https://github.com/enter-haken/rasmus/tree/master/config"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "database",
      "url": "https://github.com/enter-haken/rasmus/tree/master/database_scripts"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "transfer",
      "description": "interface table",
      "url": "https://github.com/enter-haken/rasmus/blob/master/database_scripts/transfer.sql"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "postcreate",
      "description": "table manipulation\nafter DDL",
      "url": "https://github.com/enter-haken/rasmus/blob/master/database_scripts/postcreate.sql"
    }
}
BODY

curl -H "Content-Type: application/json" -X POST $API_URL -d @- <<BODY
{
  "action": "add",
    "entity": "link",
    "data": {
      "id_owner": "$USER_ID",
      "name": "crud",
      "description": "generic CREATE, READ\nUPDATE, DELETE\nfunctions",
      "url": "https: //github.com/enter-haken/rasmus/blob/master/database_scripts/crud.sql"
    }
}
BODY

curl -H "Content-Type: application/json" -d '{"action" : "get", "entity":"graph", "data" : { "id_owner":"'"$USER_ID"'"  }}' $API_URL
