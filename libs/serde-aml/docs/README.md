# AMLv2: Azimutt Markup Language

This is the *Work In Progress* specification for AML v2, not implemented yet.

If you want to use AML, please look at the [current specification](../../../docs/aml/README.md), you can use in [Azimutt](https://azimutt.app) today ;)

## Introduction

**AML goal is to be the fastest and most intuitive DSL to define a database schema.**

Here is how it look:

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

This page will give you an overview of how to use it, follow links for precise specification.


## Entities

[Entities](./entity.md) are used to model data objects from databases, such as **tables** in relational databases or **collections** in document ones.

Defining one in AML can't be simpler, just type its name:

```aml
posts
```

Entities can have fields, indexes, relations and more, but let's dive a bit more into its definition.

There is 3 levels of hierarchy for each entity, they are optional and defined from the lowest to highest.
These levels are, from top to bottom: "database", "catalog" and "schema".
Here are a few examples:

- `posts` defines an entity without specifying the namespace
- `analytics.web.core.events` defines the `events` entity in the `core` schema, inside the `web` catalog of the `analytics` database
- `public.users` defines the `users` entity in the `public` schema, without specifying the catalog nor the database

The names should not contain space or dot characters, if you really need them, you can use the `"` character to escape the name.
For example: `"my db"."a.catalog".schema."special table"`.

As long names may be cumbersome, you can define an alias for the entity, using the `as` keyword:

```aml
"my db"."a.catalog".schema."special table" as special_table
```

## Columns



## Relations

## Types

## Properties

They are key/value pairs defined in curly braces `{}`, separated by a comma `,`:

```aml
users {color: red, size: 12, flag}
```

The value can be omited, in which case it will be considered as `true`.

You can define them on entities, columns, relations and types:

```aml
my_table {key: value}
  id int pk {auto_increment}

rel posts(author) -> users(id) {on_delete: cascade}
type post_status enum(published, draft, deleted) {deprecated}
```

Some properties are "standard" and will have an effect in Azimutt, the others are just for you or your tools.

On entities you can use:

- `color` with values from [Tailwind](https://tailwindcss.com/docs/customizing-colors) (red, orange, amber, yellow, lime, green, emerald, team, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose, grey)


## Notes

They are a piece of documentation you can attach on most elements.
They are defined at the end of the line using the `|` symbol.
The only thing which can come after is the AML comment, so except if you use the `#` symbol in it, you don't need to escape them.

```aml
users | store all users
  id int pk | to get users easily

rel posts(author) -> users(id) | link post author
type post_status enum(published, draft, deleted) | status of the post
```

For longer documentation you can write multiline notes using the `|||` symbol:

```aml
users |||
  store all users
|||
  id int pk |||
    to get users easily
  |||

rel posts(author) -> users(id) |||
  link post author
|||
type post_status enum(published, draft, deleted) |||
  status of the post
|||
```

The spaces before the first line will be removed on all the lines as well for a good indentation.

Finally, you can write standalone notes:

```aml
note users | store all users
note users(id) | user id
```

## Comments

If you need to write things for yourself, or other AML authors, but not present in the final schema, you can use comments.
There is only line comments, starting with the `#` symbol, everything after will not be taken into account.

```aml
# this is a comment

#
# You can use them as visual separator in your AML
#

users
  id int # or leaving TODOs as we all do (add primary key here)
  status enum(active, inactive)=active index | some documentation... # or to explain a bit more about a column
```

The only place they are not supported is in multiline notes.


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
