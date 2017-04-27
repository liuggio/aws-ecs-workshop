#!/usr/bin/env bash

while true;
do
    curl -sL -w "%{http_code}\n" http://ecs-demo-lb-1311122183.us-east-1.elb.amazonaws.com || echo "========FAILED=========";
done