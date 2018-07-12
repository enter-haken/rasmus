#!/bin/bash

for i in `seq 5000`;
do
  post_privilege="{\"action\" : \"add\", \"entity\":\"privilege\", \"data\": {\"name\":\"$i\", \"description\": \"show dashboard\", \"minimum_read_role_level\":\"user\"}}";
  curl -H "Content-Type: application/json" -d "$post_privilege" http://localhost:8080/api

done

