#!/usr/bin/env bash

`aws ecr get-login` || exit 1

export TAG=$(./script/increment-tag.sh) || echo "version $TAG already exists"
echo $TAG;

REGISTRY=`jq ".repository.repositoryUri" -r config/ecr_repository.json`

docker-compose build \
  && docker-compose push \
  && echo "aliasing latest from $TAG" \
  && docker tag $REGISTRY:$TAG $REGISTRY:latest \
  && docker push $REGISTRY:latest \
  && echo "completed $TAG."

exit $?