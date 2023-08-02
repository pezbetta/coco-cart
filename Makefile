build-backend:
	docker-compose build backend

migrate:
	docker-compose run backend alembic upgrade head

create-db:
	docker-compose exec postgres createdb apptest -U postgres

test:
	docker-compose run backend pytest --cov --cov-report term-missing

up:
	docker-compose up

down:
	docker-compose down