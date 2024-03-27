# @azimutt/serde-aml

This is a module to validate, parse and generate AML. And also provide syntax highlighter for it.

Read the full [AML documentation](./docs/README.md).

TODO:
- make the AML serde: parse AML into Database JSON structure, generate AML from Database JSON structure
- same for SQL
- same for [DBML](https://dbml.dbdiagram.io)
- same for Prisma
- adapt Azimutt & connectors to this database-model
- make standalone products to convert from one to another (pages in Azimutt site & CLI commands)

AML syntax ideas:
```aml
# define a global namespace for the definitions
# each top level is optional (valid ones: "schema", "catalog.schema", "database.catalog.schema")
# it can be overriden by each declaration if specified, ex: pg.sales.public.usrers table will not be in database.catalog.schema namespace
namespace database.catalog.schema

# properties are the default ones but can be changed in each layout
users {color: red, tags: [auth, common]}
  id uuid pk {autoincrement: true}
  name varchar
  email varchar unique
  description text nullable
  created_at timestamp=`now()`

roles
  id uuid pk
  name varchar unique
  priority int=0

user_roles
  user_id uuid pk
  role_id uuid pk

user_roles_ext
  user_id uuid pk
  role_id uuid pk
  details json

events
  id uuid pk
  item_kind varchar
  item_id uuid

books
  id uuid pk
  title varchar
  authors uuid[] >- users.id

book_details
  book_id uuid pk
  details json
    isbn varchar
    price json
      currency varchar
      value float8

# basic relation, with properties
rel user_roles(user_id) >- users(id) {delete: cascade, update: no action}

# composite relation
rel user_roles_ext(user_id, role_id) >- user_roles(user_id, role_id)

# polymorphic relation
rel events(item_id) >item_kind=User- users(id)
rel events(item_id) -item_kind=Role> roles(id)

# many-to-many relation
rel books(id) <> users(id)

# one-to-one relation
rel book_details(book_id) -- books(id)

bugs |||
  This is a multiline note fot the table
  It can be used to describe the table or the relation
|||
  id uuid |||
    a multiline note for a column
  |||
  name varchar |||
    a multiline note for a column
  |||
  status bug_status |||
    💸 1 = processing, 
    ✔️ 2 = shipped, 
    ❌ 3 = cancelled,
    😔 4 = refunded
  |||

type bug_status enum(new, in progress, done) {...props} | note # comment
```

Relationships:
- one-to-many: normal foreign keys: `rel user_roles.user_id >- users.id` or inline in column: `  user_id >- users.id`
- many-to-one: reverse foreign keys: `rel users.id -< user_roles.user_id` but not inline in column => useless, not implemented
- many-to-many: native in db, junction table or array column: `rel books.id >< users.id`, `  authors uuid[] >< users.id` or with junction table
- one-to-one: foreign key with unique constraint `fk book_details.book_id -- books.id` or inline in column: `  book_id unique -- books.id`
- zero-to-many: foreign key from nullable column
one-to-one and many-to-many relations can be "manually" specified without the schema constraints to be present (unique or junction table)
Interesting discussion: https://community.dbdiagram.io/t/tutorial-many-to-many-relationships/412

Other concepts:
- multiline notes: `|||`, remove the leading spaces of the first line, for all the lines
- custom types: `type $name $definition`, definition is optional and can be parsed more...
  - `type bug_status enum(new, in progress, done)`
  - `type bug_value range(subtype = float8, subtype_diff = float8mi)`
  - `type address {number: int, street: varchar}`
- if a fk column don't have a type, it talkes the type of the referenced column
