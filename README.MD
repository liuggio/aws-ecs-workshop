# ECS and Docker Demo

## Setting up the environment

1. install `awscli` http://docs.aws.amazon.com/cli/latest/userguide/installing.html
2. install `ecs-cli` http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

## On dev - work with your app in the dev

The app folder contains the sourcecode, the Dockerfile is a flask app with an health-check.

1. `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build`.
2. Open `http://localhost:8080`
3. Modify the string in `app/app.py:12` then you will see modification immediately.

## Test if it works

`curl -sL -w "%{http_code}\n"  http://0.0.0.0:8080/`

> Hello! I am tiny service on <br> Hostname:"255edaace911"<br> Color:"green"<br> Version:"latest"<br> Visit count:171 times.
> 200

`[[ $(curl -sL -w "%{http_code}\n"  http://0.0.0.0:8080/ | tail -n 1) == "200" ]]; echo $?`

## On stage - build && push

### Manually

The file `.env` contain the default tag, but in the real world app, we need to increase the value.

1. `chmod +x /script/increment-tag.sh && ./script/increment-tag.sh`

   > ➜ 0.0.2
   
2. `export TAG=$(./script/increment-tag.sh) || echo "version $TAG already exists"`

Our new tag is on $TAG variable

3. docker-compose build && docker-compose push

   > ➜  aws-ecs-workshop git:(master) ✗ docker-compose push                                                               
     Pushing web (liuggio/aws-ecs-workshop:0.0.2)...

4. tag and push latest.

### Automatically lunch the script.

`./script/build.sh`

## Create the Image repository

`aws ecr create-repository --repository-name xpeppers/aws-ecs-workshop > config/ecr_repository.json`

``` json
{
    "repository": {
        "registryId": "831650818513",
        "repositoryName": "xpeppers/aws-ecs-workshop",
        "repositoryArn": "arn:aws:ecr:us-east-1:831650818513:repository/xpeppers/aws-ecs-workshop",
        "createdAt": 1493209368.0,
        "repositoryUri": "831650818513.dkr.ecr.us-east-1.amazonaws.com/xpeppers/aws-ecs-workshop"
    }
}
```

then:

```
jq ".repository.repositoryUri" -r config/ecr_repository.json
```

> 831650818513.dkr.ecr.us-east-1.amazonaws.com/xpeppers/aws-ecs-workshop

### Show all the images

```
aws ecr list-images --repository-name `jq ".repository.repositoryName" -r config/ecr_repository.json`

```

``` json
{
    "imageIds": [
        {
            "imageTag": "v1", 
            "imageDigest": "sha256:ccf3adf9fedb0bbc1460d133768e2cffba33e598677ff9373734ecb5d096d882"
        }, 
        {
            "imageTag": "latest", 
            "imageDigest": "sha256:ccf3adf9fedb0bbc1460d133768e2cffba33e598677ff9373734ecb5d096d882"
        }
    ]
}
```














## Create the Computation stack

```
aws cloudformation create-stack --stack-name aws-ecs-workshop --template-body file://./infrastructure-ecs/ecs.json --parameters file://./infrastructure-ecs/parameters.json
```





## Propedeutical Tasks

#### Launch Monitoring application

```
npm -d install
npm start
```

#### Create Infrastructure (ECS Cluster and ALB)

```
aws cloudformation create-stack --stack-name UniRoma2-ECS --template-body file://./infrastructure-ecs/ecs.json --parameters file://./infrastructure-ecs/parameters.json

aws cloudformation create-stack --stack-name UniRoma2-ALB-Blue --template-body file://./infrastructure-alb/alb.json --parameters file://./infrastructure-alb/parameters.json
```

#### Build, Test and Run a Container

Build and push Microservices ONE

```
docker-compose -f python-microservice-one/docker-compose.yml build
docker-compose -f python-microservice-one/docker-compose.yml push
```

Build and push Microservices TWO

```
docker-compose -f python-microservice-two/docker-compose.yml build
docker-compose -f python-microservice-two/docker-compose.yml push
```

Up&Running the Microservices ONE and TWO in local

```
docker-compose -f python-microservice-one/docker-compose.yml up
docker-compose -f python-microservice-two/docker-compose.yml up
```

## Pattern 1: Use ecs compose CLI

#### Register cluster

```
ecs-cli configure --cluster UniRoma2-ECSCluster-1JYA72NORCX8
```

#### Launch services

```
ecs-cli compose -f python-microservice1/docker-compose.yml service up
ecs-cli compose -f python-microservice2/docker-compose.yml service up
```

#### Scale services

```
ecs-cli compose -f python-microservice1/docker-compose.yml service scale 2
ecs-cli compose -f python-microservice2/docker-compose.yml service scale 2
```

#### Scale cluster

```
aws autoscaling set-desired-capacity --auto-scaling-group-name UniRoma2-ECSAutoScalingGroup-K76B7PJC
483 --desired-capacity 6 --honor-cooldown
```
#### Resume
PRO: porting from compose to ecs
CONTRO: no possible to attach service to ALB/ELB

## Pattern 2: Use ecs compose CLI and standard CLI

#### Create Task

Creates an ECS task definition from your compose file.
```
ecs-cli compose -f python-microservice-one/docker-compose.yml create
ecs-cli compose -f python-microservice-two/docker-compose.yml create
```

#### Create Service and attach to ELB
aws ecs create-service --service-name "UniRoma2-MicroserviceOne" --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --task-definition "ecscompose-python-microservice-one" --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:831650818513:targetgroup/Microservices-one/cca50273455ba775,containerName=web,containerPort=8080" --desired-count 2 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50" --role ECS-TestRole

aws ecs create-service --service-name "UniRoma2-MicroserviceTwo" --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --task-definition "ecscompose-python-microservice-two" --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:831650818513:targetgroup/Microservices-two/b08b98b4bce484ec,containerName=web,containerPort=8080" --desired-count 2 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50" --role ECS-TestRole

#### Update Service and attach to ELB
aws ecs update-service --service UniRoma2-MicroserviceOne --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --task-definition "ecscompose-python-microservice-two" --desired-count 2 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100"

aws ecs create-service --service-name "UniRoma2-MicroserviceOne" --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --task-definition "ecscompose-python-microservice-one" --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:831650818513:targetgroup/Microservices-one/cca50273455ba775,containerName=web,containerPort=8080" --desired-count 2 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50" --role ECS-TestRole

aws ecs create-service --service-name "UniRoma2-MicroserviceTwo" --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --task-definition "ecscompose-python-microservice-two" --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:831650818513:targetgroup/Microservices-two/b08b98b4bce484ec,containerName=web,containerPort=8080" --desired-count 2 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50" --role ECS-TestRole


#### Scale task associated to services

```
aws ecs list-services --cluster UniRoma2-ECSCluster-1JYA72NORCX8
aws ecs update-service --service UniRoma2-MicroserviceOne --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --desired-count 2
aws ecs update-service --service UniRoma2-MicroserviceTwo --cluster UniRoma2-ECSCluster-1JYA72NORCX8 --desired-count 2
```

#### Scale cluster

```
aws autoscaling set-desired-capacity --auto-scaling-group-name UniRoma2-ECSAutoScalingGroup-K76B7PJC
483 --desired-capacity 6 --honor-cooldown
```

## BLUE/GREEN Deployment

aws cloudformation create-stack --stack-name UniRoma2-ALB-Green --template-body file://./infrastructure-alb/alb.json --parameters file://./infrastructure-alb/parameters.json

Pattern One: DNS Swap
- Create new task definition
- Create new service
- Create new ElasticLoadBalancing
- Attach new service to new LoadBalancer
- Update Route53 to new service
- CleanUP Blue Environment

Pattern Two: Service Swap
- Create new task definition
- Create new service
- Attach new service to existing LoadBalancer
- ScaleUP Green Service
- SCaleDOWN Blue Service

Pattern Three: Service Update
- Create new task definition
- Update the service
