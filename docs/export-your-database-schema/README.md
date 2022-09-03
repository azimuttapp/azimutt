# How to get your database schema

There is a lot of ways to get your database schema and depending on your setup they are more or less convenient.  
Look at the table of content to choose the best one for you 😉

- [Databases](#databases)
  - [PostgreSQL](#postgresql)
- [Tools](#tools)
  - [phpMyAdmin](#phpmyadmin)
  - [DataGrip](#datagrip)
  - [DBeaver](#dbeaver)
- [Frameworks](#frameworks)
  - [Rails](#rails)
  - [Phoenix](#phoenix)

## Databases
### PostgreSQL

```shell
# https://www.postgresql.org/docs/current/app-pgdump.html
pg_dump --dbname=postgres://postgres:postgres@localhost:5432/my_db --table='public.*' --schema-only > my_db-$(date +%d-%m-%y).sql
```

## Tools
### phpMyAdmin
### DataGrip
### DBeaver

## Frameworks
### Rails / Active Record
### Symfony / Doctrine
### Phoenix / Ecto
