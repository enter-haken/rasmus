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
