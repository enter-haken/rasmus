#!/bin/bash
curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"dashboard", "description": "show dashboard", "minimum_read_role_level":"user"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"news", "description": "show news feed", "minimum_read_role_level":"user"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"user_management", "description": "work with systemwide user management"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"role_management", "description": "work with systemwide role management"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"privilege", "data": {"name":"privilege_management", "description": "work with systemwide privilege management"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"role", "data": {"name":"admin", "description": "the admin can do everything within the instance"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"role", "data": {"name":"user", "description": "this is the standard user role"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"user", "data" : {"first_name":"Jan Frederik", "last_name": "Hake", "email_address": "jan_hake@gmx.de", "login": "jan_hake"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"privilege"}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"privilege", "data": { "name" : "dash"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"role"}' http://localhost:8080/api

# wait two seconds, until the user is persisted. async operation. this is only for testing.
sleep 2 

userid=`psql -U postgres -d rasmus -c "select id from rasmus.user" | sed -e '1,2d' -e '4,5d' -e 's/^ //'`
admin_role_id=`psql -U postgres -d rasmus -c "select id from rasmus.role where name = 'admin'" | sed -e '1,2d' -e '4,5d' -e 's/^ //'`

curl -H "Content-Type: application/json" -d '{"action":"update","entity":"user", "data" : { "id" : "'"$userid"'", "first_name" : "Jan"}}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action":"get","entity":"user"}' http://localhost:8080/api

# example links / nodes describing rasmus itself

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "otp tree", "description" : "process configuration", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/rasmus_app.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "router", "description" : "cowboy router", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/web/router.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "counter", "description" : "listen to notifications\nfrom database", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/core/counter.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "inbound", "description" : "send requests towards\nthe database", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/core/inbound.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "manager", "description" : "execute the\ndatabase manager", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/core/manager.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "client", "description" : "react / visjs app", "url" : "https://github.com/enter-haken/rasmus/blob/master/lib/core/manager.ex" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "configuration", "description" : "database configuration", "url" : "https://github.com/enter-haken/rasmus/tree/master/config" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "database", "url" : "https://github.com/enter-haken/rasmus/tree/master/database_scripts" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "transfer", "description" : "interface table", "url" : "https://github.com/enter-haken/rasmus/blob/master/database_scripts/transfer.sql" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "postcreate", "description" : "table manipulation\nafter DDL", "url" : "https://github.com/enter-haken/rasmus/blob/master/database_scripts/postcreate.sql" }}' http://localhost:8080/api

curl -H "Content-Type: application/json" -d '{"action" : "add", "entity":"link", "data" : { "id_owner":"'"$userid"'", "name": "crud", "description" : "generic CREATE, READ\nUPDATE, DELETE\nfunctions", "url" : ""https://github.com/enter-haken/rasmus/blob/master/database_scripts/crud.sql" }}' http://localhost:8080/api
