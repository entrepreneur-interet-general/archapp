stack_tag  = archapp-stack
registry = 127.0.0.1:5000
cheap_exp_tag = $(registry)/cheap-exp:master
archapi_tag = $(registry)/archapi:master
archypoint_tag = $(registry)/archypoint:master

domain = archifiltre.io

all: build deploy

deploy:
	sudo docker stack deploy -c docker-compose.yml $(stack_tag)

build: cheapExp archapi archypoint

cheapExp:
	sudo docker build \
		--network=host \
		--tag=$(cheap_exp_tag) \
		https://github.com/jeanbaptisteassouad/cheapExp.git#master
	sudo docker push $(cheap_exp_tag)

archapi:
	sudo docker build \
		--network=host \
		--tag=$(archapi_tag) \
		https://github.com/jeanbaptisteassouad/archapi.git#alpha-api
	sudo docker push $(archapi_tag)

archypoint:
	sudo docker build \
		--network=host \
		--target=dev \
		--build-arg domain=$(domain) \
		--build-arg www_pass=www:80 \
		--build-arg api_pass=api:3000 \
		--tag=$(archypoint_tag) \
		https://github.com/entrepreneur-interet-general/archypoint.git#remove-dep
	sudo docker push $(archypoint_tag)





dev: createHost all

createHost: removeHost
	echo "127.0.0.1 "$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 www."$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 api."$(domain)" #archapp#" | sudo tee -a /etc/hosts

removeHost:
	sudo sed -i -e '/.*#archapp#.*/d' /etc/hosts

clean: removeHost
	sudo docker stack rm $(stack_tag)
	sudo docker container prune -f
