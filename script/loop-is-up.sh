#!/usr/bin/env bash

while true;
do
    curl -sL -w "%{http_code}\n" ${HTTP_LB-"http://ecs-demo-lb5-72464861.us-east-1.elb.amazonaws.com"} || echo "========FAILED=========";
done