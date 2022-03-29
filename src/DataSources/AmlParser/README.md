# Azimutt Markup Language

Azimutt Markup Language is a language able to represent a database schema in a much simpler way than SQL.
Its goal is to be simple and concise to you can learn it on the fly and write it fluently to speed your diagram definition.

## Spec

### Tables

In its simplest form a table is just represented by its name without indentation:

```
users
```

It should not contain any space or dot character like all identifiers, but if it does, just surround it with `"`.
You could also add a schema in front of any table declaration like:

```
public.users
```

Views are just like regular tables, but they should have a `*` just after their name:

```
users_view*
```

Columns follow the table definition with an indentation of two spaces:

```
users
  id
  name
```

Defined like this the type will be `unknown` but you can add it just after. If it has spaces in it, surround it with `"`:

```
users
  id integer
  name "varchar (10)"
```

If the column has a default value, you can specify it with the `=` sign just after the type, again, surrounded by `"` if there is spaces:

```
users
  id integer
  name varchar(10)=John
```

By default, columns are considered not nullable but if they are, just add the `nullable` keyword after the type:

```
users
  id integer
  name varchar(10) nullable
```

### Constraints

To define a primary key, just add `pk` at the after the column declaration:

```
users
  id integer pk
  name varchar
```

For a composite primary key, just add `pk` keyword after multiple columns.
Similarly, for `unique`, `index` and `check` constrains, just add the keyword after the column, but they won't be automatically grouped, for that, you need to add a name:

```
users
  id integer pk
  first_name varchar unique=name
  last_name varchar unique=name
```

### Relations

Relations can be either defined as table foreign keys using the `fk` keyword:

```
talks
  id integer pk
  created_by fk users.id
```

If type is not defined, it will get the type of the referenced column.

They can also be declared as standalone instruction:

```
fk talks.created_by -> users.id
```

You can name a relation using `=` after the `fk` keyword:

```
talks
  id integer pk
  created_by fk=talks_created_by users.id

fk=talks_created_by talks.created_by -> users.id
```

Polymorphic relations are not fully supported yet in Azimutt, but for now, you can just ignore the kind column and define multiple relations starting from the id column:

```
request
  id uuid
  kind varchar
  target_type varchar
  target_id integer

fk request.target_id -> users.id
fk request.target_id -> talks.id
fk request.target_id -> logins.id
```

Composite relations are not supported yet in Azimutt but AML syntax could look like:

```
fk (logins.provider_id, logins.provider_key) -> (credentials.provider_id, credentials.provider_key)
```


### Layout

You can specify some layout attributes after an entity declaration (table or column) to initialize them, either as `key=value` or just `property`:

```
users {color=red, left=100, top=10}
  id integer
  name varchar(10) {hidden}
```

### Other

You can add descriptions in any entity (table, column or relation) using the `|` operator at the end of the line:

```
users | "Store all our users"
  id integer | "Unique identifier for a user"
  name varchar(10)
```

AML supports line comments starting with `#`, everything that is after will not be taken into account:

```
# How to define a table and it's columns
users | "Store all our users" # description example for table
  id integer | "Unique identifier for a user" # description example for column
  name varchar(10)

fk talks.created_by -> users.id # How to define a relation
```

## Recap

Here is some example with all the possibilities

```
# How to define a table and it's columns
users {left=100, top=10, color=red} # description example for table
  id integer pk # description example for column
  role varchar=guest {hidden=true}
  first_name varchar(10) unique=name
  laft_name varchar(10) unique=name
  email varchar nullable
  
public.admins* | "View of `users` table with only admins"
  id fk users.id
  name | "Computed from user first_name and laft_name"
  
fk admins.id -> users.id
```

## Credits

Inspired by https://www.dbml.org/docs and https://www.quickdatabasediagrams.com

Open questions:
- multiline descriptions: use """ ?
- table groups (future Azimutt feature): `group=name users, talks {color=green} | "A description for the group" # some comment`
