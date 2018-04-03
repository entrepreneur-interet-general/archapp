stack_tag  = archapp-stack
registry = 127.0.0.1:5000
cheap_exp_tag = $(registry)/cheap-exp:master
archapi_tag = $(registry)/archapi:master
archypoint_tag = $(registry)/archypoint:master

domain = archifiltre.io
certPath = ../archifiltre.io

all: update


start: secrets initStack build deploy
update: build deploy
stop: removeStack cleanDev removeSecrets
restart: stop start


secrets:
	dd if=/dev/urandom bs=1 count=64 2>/dev/null \
		| base64 -w 0 \
		| rev \
		| cut -b 2- \
		| rev \
		| sudo docker secret create archapiJwt -
	cat $(certPath)/private.key | sudo docker secret create privkey.pem -
	cat $(certPath)/certificate.crt | sudo docker secret create cert.pem -
	cat $(certPath)/ca_bundle.crt | sudo docker secret create fullchain.pem -


removeSecrets:
	sudo docker secret ls --quiet | xargs -r -n1 sudo docker secret rm


initStack:
	sudo docker stack deploy -c init.yml $(stack_tag)

removeStack:
	sudo docker stack rm $(stack_tag)
	sudo docker container prune -f


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
		--build-arg domain=$(domain) \
		--build-arg www_pass=www:80 \
		--build-arg api_pass=api:3000 \
		--tag=$(archypoint_tag) \
		https://github.com/entrepreneur-interet-general/archypoint.git#remove-dep
	sudo docker push $(archypoint_tag)


deploy:
	sudo docker stack deploy -c main.yml $(stack_tag)




hosts: removeHosts
	echo "127.0.0.1 "$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 www."$(domain)" #archapp#" | sudo tee -a /etc/hosts
	echo "127.0.0.1 api."$(domain)" #archapp#" | sudo tee -a /etc/hosts

removeHosts:
	sudo sed -i -e '/.*#archapp#.*/d' /etc/hosts

selfCert:
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/CN="$(domain) \
	  -keyout /tmp/privkey.pem \
	  -out /tmp/cert.pem
	cp /tmp/cert.pem /tmp/fullchain.pem

dev: hosts start

cleanDev: removeHosts
