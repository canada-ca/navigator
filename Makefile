phony: cover dev docker install setup test

cover:
	cd valentine && mix test --cover

dev:
	cd valentine && mix phx.server

docker: 
	docker build --build-arg GIT_SHA=$(shell git rev-parse HEAD) -t valentine valentine/.

install:
	cd valentine && mix deps.get

fmt:
	cd valentine && mix format

setup: 
	cd valentine && mix deps.get && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs && cd assets && npm install

test:
	cd valentine && mix test