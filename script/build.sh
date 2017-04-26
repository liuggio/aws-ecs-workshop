#!/usr/bin/env bash

export TAG=$(./script/increment-tag.sh) || echo "version $TAG already exists"
echo $TAG;

docker-compose build \
  && docker-compose push \
  && echo "aliasing latest from $TAG" \
  && docker tag liuggio/aws-ecs-workshop:$TAG liuggio/aws-ecs-workshop:latest \
  && docker push liuggio/aws-ecs-workshop:latest \
  && echo "completed."

exit $?