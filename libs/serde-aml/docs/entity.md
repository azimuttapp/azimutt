# AML: Azimutt Markup Language

## Entity

Entities are nodes in [Entity-Relationship model](https://wikipedia.org/wiki/Entity%E2%80%93relationship_model), they are often used to model **tables** or **collections** in databases.

Here is the simplest entity definition, just its name:

```aml
users
```

The name is an [identifier](./identifier.md) and can be prefixed with a [namespace](./namespace.md):

```aml
core.public."user list"
```

Entities can contain [attributes](./entity-attribute.md) (corresponding to **columns** or **fields** in databases), define each on one line prefixed by two spaces:

```aml
users
  id
  name
```

[Attributes may hold several characteristics](./entity-attribute.md) such as **type**, **nullability**, **indexes** or **constraints** and more, here are some examples:

```aml
users
  id uuid pk
  name varchar
  email "varchar(256)" unique
  bio text nullable
  role user_role(admin, guest)=guest index
```

Entities can also have [custom properties](./properties.md) and [documentation](./documentation.md) (as well as attributes):

```aml
users {color: red, tags: [pii, sensitive], deprecated} | storing all users
  id int pk {auto_increment}
  name
```

Finally, they can be **aliased** to simplify their references, entity aliases are also [identifiers](./identifier.md):

```aml
db1.referential.identity.accounts as users
  id
  name

posts
  id
  author -> users(id) # refers to `db1.referential.identity.accounts` entity
```
