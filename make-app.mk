app-build:
	docker-compose --file=docker-compose.dummy.yml build

app:
	docker-compose --file=docker-compose.dummy.yml up -d app
	docker attach mcfly_app_1

app-start:
	docker-compose --file=docker-compose.dummy.yml up -d app
	docker attach mcfly_app_1

app-stop:
	docker-compose --file=docker-compose.dummy.yml stop

app-down:
	docker-compose --file=docker-compose.dummy.yml down

app-bash:
	docker-compose --file=docker-compose.dummy.yml run --rm app bash

app-console:
	docker-compose --file=docker-compose.dummy.yml run --rm app /bin/bash -c "cd spec/dummy && bin/rails c"

app-initialise-docker:
	touch .bash_history.docker
	touch .pry_history.docker
	make app-install
	make app-db-prepare

app-install:
	docker-compose --file=docker-compose.dummy.yml run --rm app gem install bundler
	make app-install-bundle

app-install-bundle:
	docker-compose --file=docker-compose.dummy.yml run --rm app bundle

app-db-drop:
	docker-compose --file=docker-compose.dummy.yml run --rm app rake db:drop

app-db-prepare:
	cp spec/dummy/config/database.yml.example spec/dummy/config/database.yml
	docker-compose --file=docker-compose.dummy.yml run --rm app /bin/bash -c "cd spec/dummy && bundle exec rake db:create db:migrate db:seed"

app-db-seed:
	docker-compose --file=docker-compose.dummy.yml run --rm app rake db:seed

