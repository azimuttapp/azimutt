# AML - Azimutt Markup Language

[back to home](./README.md)


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

Entities can contain [attributes](#attribute) (corresponding to **columns** or **fields** in most databases). They are defined one per line with two spaces indentation:

```aml
users
  id
  name
```

[Attributes may have options](#attribute) such as [type](#attribute-type), [nullability](#not-null), [indexes, constraints](#index-and-constraint) and more. Here are some examples:

```aml
users
  id uuid pk
  name varchar
  email varchar(256) unique
  bio text nullable
  role user_role(admin, guest)=guest index
```


### Metadata

Entities can also have [custom properties](./properties.md) and [documentation](./documentation.md) (as well as [attributes](#attribute)):

```aml
users {color: red, tags: [pii, sensitive], deprecated} | storing all users
  id int pk {autoIncrement} | the user id
  name
```


### Alias

Finally, they can be **aliased** to simplify their references, entity aliases are also [identifiers](./identifier.md):

```aml
db1.referential.identity.accounts as users
  id
  name

posts
  id
  author -> users(id) # refers to `db1.referential.identity.accounts` entity
```


### Attribute

Attributes define possible values inside an entity, such as **columns** in relational databases and **fields** in document ones.

They are defined with 2 space indentation under the entity they belong to, but they can also have [several nesting levels](#nested-attribute).

The only required thing is their name, which is an [identifier](./identifier.md). After they have several options for the [type](#attribute-type), [nullable](#not-null), [indexes and constraints](#index-and-constraint).

Here is an example:

```aml
users
  id # only the name
  name varchar # the name and the type
  email varchar unique # the name, type and unique constraint
  bio nullable # the name and allowing null (by default not null constraint is applied)
  profile_id -> profiles(id) # the name and relation
```


#### Attribute type

The attribute type should come just after the attribute name, if there is space or special character inside the type, surround it with `"`, here are some examples:

```aml
events
  id uuid
  name varchar(50)
  age int
  rating decimal(5, 2)
  details json
  tags "varchar[]"
  created_at "timestamp with time zone"
```

You can define the default attribute value with the `=` symbol:

```aml
users
  id uuid
  name varchar(50)=John
  age int=0
  rating decimal(5, 2)=0.0
  details json="{}"
  tags "varchar[]"="[]"
  admin boolean=false
  created_at "timestamp with time zone"=`now()`
```

Known types are automatically inferred:

- boolean for `true` and `false`
- number when only numbers and one dot (at most)
- object when starting with `{`
- array when starting with `[`
- function when starting by backticks (`)
- string otherwise, use `"` for multi-word string

[Custom types](./type.md) can be defined in standalone and used for an attribute:

```aml
type post_status (draft, publiched, archived)

posts
  id uuid
  status post_status=draft
```

But enums can also be defined inline with the attribute:

```aml
posts
  id uuid
  status post_status(draft, publiched, archived)=draft
  code post_code(0, 1, 2)=2
```

In this case, they inherit the [namespace](./namespace.md) of the entity, and of course, they can be reused elsewhere (but in this case it's best to define them standalone).


#### Not null

Contrary to SQL, in AML the attributes come with the NOT NULL constraint **by default**.

To remove it, you can mark the attribute as `nullable`. This "not constraint" should come after the attribute name and type (if present).

Here are some examples:

```aml
profiles
  id uuid
  user_id uuid -> users(id)
  company nullable
  company_size int nullable
```


#### Index and constraint

Entity attributes may have constraints and AML allows defining them, though not as detailed as SQL.

They come in this order: primary key, unique, index, check and relation, but most of the time you will have just one per attribute ^^

Here is an example:

```aml
users
  id uuid pk # define a primary key constraint
  email varchar unique # define a unique constraint on email attribute
  name varchar index # define an index for the name attribute
  age int check # define a check constraint for the age attribute
  profile_id uuid -> profiles(id) # define a relation for the profile_id attribute
```

Constraints can be named using the `=` symbol, except for check and relations, here is how:

```aml
users
  id uuid pk=users_pk
  email varchar unique=users_email_uniq
  name varchar index=users_name_idx
  age int check=`age >= 0`
  profile_id uuid -> profiles(id)
```

If you want to define a single constraint on several attributes (like uniqueness of `first_name` and `last_name`), you can apply it to the needed attributes with the same name, they will be put together.
The primary key doesn't need this as there is only one per an entity:

```aml
users # unique constraint on first_name AND last_name
  id uuid pk
  first_name varchar unique=users_name_uniq
  last_name varchar unique=users_name_uniq

user_roles # composite primary key on user_id and role_id
  user_id uuid pk -> users(id)
  role_id uuid pk -> roles(id)
```

The `check` predicate can be defined using backticks:

```aml
users
  id uuid pk
  first_name varchar unique=users_name_uniq
  last_name varchar unique=users_name_uniq check=`LEN(CONCAT(first_name, last_name)) > 5`
  age int check=`age > 0`
```

> This constraint part is the same as AMLv1 and it "works" but may be improved to support the index kind, condition (for partial indexes) and other properties.
> We didn't find a nice syntax to do it inline, but if you have ideas, feel free to shoot!
> Also we are considering creating standalone index & constraint definitions, but not trivial to make them obvious, and it could come later easily.


#### Nested attribute

Attributes may have nested attributes, this is especially useful to define the schema of complex objects like `json`.

Nested attributes are just like other attributes, just with an additional indentation level under the attribute they belong to. Here is how they look:

```aml
users
  id uuid pk
  name varchar
  details json
    github_url varchar nullable unique
    twitter_url varchar nullable unique
    company json nullable
      id uuid -> companies(id)
      name varchar index=users_company_name_idx
      size number
      job varchar
    address json nullable
      no number
      street varchar
      city varchar
      zipcode number
      country varchar
    gender varchar nullable
    age number nullable
```
