stack_tag  = archapp-stack
registry = 127.0.0.1:5000
cheap_exp_tag = $(registry)/cheap-exp:master
archapi_tag = $(registry)/archapi:master
archypoint_tag = $(registry)/archypoint:master

domain = archifiltre.io

all: update


start: secrets initStack build deploy
update: build deploy
stop: removeStack removeSecrets removeHosts clean
restart: stop start


secrets:
	dd if=/dev/urandom bs=1 count=64 2>/dev/null \
		| base64 -w 0 \
		| rev \
		| cut -b 2- \
		| rev \
		| sudo docker secret create archapiJwt -

removeSecrets:
	sudo docker secret rm archapiJwt



initStack:
	sudo docker stack deploy -c init.yml $(stack_tag)

removeStack:
	sudo docker stack rm $(stack_tag)



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


deploy:
	sudo docker stack deploy -c main.yml $(stack_tag)


clean:
	sudo docker container prune -f




hosts: removeHosts
	echo "127.0.0.1 "$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 www."$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 api."$(domain)" #archapp#" | sudo tee -a /etc/hosts

removeHosts:
	sudo sed -i -e '/.*#archapp#.*/d' /etc/hosts

dev: hosts all

