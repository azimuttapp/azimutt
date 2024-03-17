# AMLv2: Azimutt Markup Language

This is the *Work In Progress* specification for AML v2, not implemented yet.

If you want to use AML, please look at the [current specification](../../../docs/aml/README.md), you can use in [Azimutt](https://azimutt.app) today ;)

## Introduction

**AML goal is to be the fastest and most intuitive DSL to define a database schema.**

Here is how it looks:

```aml
users | store every user
  id uuid pk
  email varchar unique
  role user_role(guest, member, admin)=guest

posts # AML comment
  id uuid pk
  title varchar(100)
  content text
  tags varchar[] nullable
  author -> users(id)
  created_at timestamp=`now()`
```

This page will give you an overview of how to use it, follow links for the exhaustive specification.

One last things, AML [comments](./comment.md) are single line and start with `#`, so you know them as they are in many places 😉


## Entities

[Entities](./entity.md) can be used to model data objects from databases, such as **tables** or **collections** in databases.

Defining one in AML can't be simpler, just type its name:

```aml
posts
```

Entities can have attributes with several options like a type, nullability, indexes, constraints and relations.

Here is how they look:

```aml
posts
  id uuid pk
  slug varchar(256) unique
  title varchar index
  status post_status(draft, published, archived)=draft index
  content text nullable
  tags varchar[]
  props json
    needs_review bool
    reviewed_by -> users(id)
  created_by -> users(id)
  created_at "timestamp with time zone"=`now()`
```

You can define them inside a [namespace](./namespace.md) and give them an [alias](./entity.md#alias) name for easier referencing:

```aml
core.public.users as u
  id uuid pk
  name varchar

core.public.posts as p
  id uuid pk
  title varchar
  created_by -> u(id)
```

And you can document them both with structured [properties](./properties.md) or unstructured [documentations](./documentation.md):

```aml
events {color: yellow, scope: tracking} | store all user events
  id uuid pk
  name varchar index | should be structured with `context__object__action` format
  item_kind varchar {values: [users, posts, projects]} | polymorphic relation
  item_id uuid
```


## Relations

[Relations](./relation.md) can model references, like foreign keys, or source for lineage, depending how you want to use them.

They mostly use the `->` symbol in entity definition (like used above) but can also be defined standalone with the `rel` keyword and use other cardinality with `--` for [one-to-one](./relation.md#one-to-one) and `<>` for [many-to-many](./relation.md#many-to-many).

```aml
users
  id uuid pk

profiles
  id uuid pk
  user_id uuid -- users(id)

projects
  id uuid pk <> users(id)
  created_by -> users(id)

events
  id uuid pk
  created_by uuid

rel events(created_by) -> users(id)
```

For fasted definition, you can omit the target attribute when the target table has a primary key with a single attribute. As well as the attribute type, it will be inherited from the target attribute:

```aml
users
  id uuid pk

events
  id uuid pk
  created_by -> users
```

AML supports [polymorphic](./relation.md#polymorphic-relation) relations by adding the kind attribute key and value inside the relation symbol:

```aml
users
  id uuid pk

projects
  id uuid pk

events
  id uuid pk
  item_kind event_items(users, projects)
  item_id
  created_by -> users

rel events(item_id) -item_kind=users> users
rel events(item_id) -item_kind=projects> projects
```

It also supports [composite](./relation.md#composite-relation) relations by listing the used attributes in the parenthesis:

```aml
credentials
  provider_key varchar pk
  provider_uid varchar pk
  user_id -> users

credential_details
  provider_key varchar pk
  provider_uid varchar pk
  provider_data json

rel credential_details(provider_key, provider_uid) -> credentials(provider_key, provider_uid)
```


## Types

You can also create [custom types](./type.md) for better semantics, consistency or re-usability.

They can be defined inline in the entity attribute definition when not re-used, on standalone:

```aml
type name # just a named type for better semantics
type id_type uuid # here is a type alias
type bug_status enum(draft, in progress, done) # enums are quite useful and explicit
type position {x: int, y: int} # even structs can be defined
```


## Migration from v1

AMLv2 is coming 2 years after AMLv1 ([post](https://azimutt.app/blog/aml-a-language-to-define-your-database-schema) & [PR](https://github.com/azimuttapp/azimutt/pull/98) ^^).
During this time we discovered a lot of new use cases and some shortcomings (such as composite foreign keys).

This new iteration fix a few issues, improve consistency and add nice features such as [namespace](./namespace.md) and [properties](./properties.md).

We made it retro-compatible so you only have to fix the issued warnings but if you want to look at what needs to be adapted, look at the [migration doc](./migration.md).


## Full example

Let's write a meaningful AML example to have an idea of how it looks like to design your database schema with AML. This example won't use every available feature on AML but give you a good idea of the kind of code you will write using AML.

Let's define a theorical e-commerce shop:

![e-commerce schema defined using AML](../../../docs/aml/e-commerce-using-aml.png)

```aml
#
# Identity domain
#

users
  id uuid pk
  slug varchar unique | user identifier in urls
  role user_role(customer, staff, admin)
  name varchar
  avatar url
  email varchar unique
  email_validated timestamp nullable
  phone varchar unique
  phone_validated timestamp nullable
  bio text nullable
  company varchar nullable
  locale locale(en, fr)
  created_at timestamp
  updated_at timestamp
  last_login timestamp

credentials
  provider_id provider(google, facebook, twitter, email) pk
  provider_key varchar pk | user id in provider system
  hasher hash_method(md5, sha1, sha256)
  password_hash varchar
  password_salt varchar
  user_id uuid -> users(id)

social_profiles
  user_id uuid -> users(id)
  platform social_platform(facebook, twitter, instagram, slack, github)
  platform_user varchar
  created_at timestamp

#
# Catalog domain
#

categories
  id uuid pk
  slug varchar unique | category identifier in urls
  name varchar
  description text
  tags varchar[]
  parent_category uuid -> categories(id)
  created_at timestamp
  updated_at timestamp

products
  id uuid pk
  category_id uuid nullable -> categories(id)
  title varchar
  picture varchar
  summary text
  description text
  price number | in Euro
  discount_type discount_type(none, percent, amount)
  discount_value number
  tags varchar[]
  created_at timestamp
  updated_at timestamp

reviews
  id uuid pk
  user_id uuid -> users(id)
  product_id uuid -> products(id)
  rating int index | between 1 and 5
  comment text
  created_at timestamp

#
# Cart domain
#

carts
  id uuid pk
  status cart_status(active, ordered, abandonned)
  created_at timestamp=`now()`
  created_by uuid -> users(id)
  updated_at timestamp

cart_items
  cart_id uuid pk -> carts(id)
  product_id uuid pk -> products(id)
  price number
  quantity int check=`quantity > 0` | should be > 0
  created_at timestamp

#
# Order domain
#

orders
  id uuid pk
  user_id uuid -> users(id)
  created_at timestamp

order_lines
  id uuid pk
  order_id uuid -> orders(id)
  product_id uuid -> products(id) | used as reference and for re-order by copy data at order time as they should not change
  price number | in Euro
  quantity int check=`quantity > 0` | should be > 0
```

Hope you enjoyed AML, happy hacking on [Azimutt](https://azimutt.app)!
