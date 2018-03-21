stack_tag  = archapp-stack
registry = 127.0.0.1:5000
cheap_exp_tag = $(registry)/cheap-exp:master


all: build deploy

deploy:
	sudo docker stack deploy -c docker-compose.yml $(stack_tag)

build: cheapExp

cheapExp:
	sudo docker build \
		--network=host \
		--tag=$(cheap_exp_tag) \
		https://github.com/jeanbaptisteassouad/cheapExp.git#master
	sudo docker push $(cheap_exp_tag)

clean:
	sudo docker stack rm $(stack_tag)
	sudo docker container prune -f
