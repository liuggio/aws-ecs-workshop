#!/usr/bin/env bash

`aws ecr get-login` || exit 1

export TAG=$(./script/increment-tag.sh) || echo "version $TAG already exists"
echo $TAG;

REGISTRY=831650818513.dkr.ecr.us-east-1.amazonaws.com/xpeppers/aws-ecs-workshop

docker-compose build \
  && docker-compose push \
  && echo "aliasing latest from $TAG" \
  && docker tag $REGISTRY:$TAG $REGISTRY:latest \
  && docker push $REGISTRY:latest \
  && echo "completed."

exit $?