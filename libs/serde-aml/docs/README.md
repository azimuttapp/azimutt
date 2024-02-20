# AML: Azimutt Markup Language

## WIP

This library is a rework for AML. You can still see the [previous documentation](../../../docs/aml/README.md), still used in Azimutt today.

Pending questions:
- AML relations: `->` vs `>-`? and `<>` vs `><`?
- tables vs entities?

## Introduction

**AML goal is to be the fastest and intuitive DSL to define database schema, as well as feature complete.**

Here is how it look:

```aml
users | store every user
  id uuid pk
  email varchar unique
  role user_role(guest, member, admin)=guest

posts
  id uuid pk
  title varchar(100)
  content text
  tags varchar[] nullable
  author >- users(id)
  created timestamp=`now()`
```

## Namespace

AML, and Azimutt, handle 3 levels of hierarchy to defines entities, in order: database, catalog and schema.

They are optional and can be defined before elements like entities or types, from the lowest to highest level.

To avoid too much repetition, a global namespace can be defined at the beginning of the file:

```aml
namespace analytics.web.core
```

It will be used as the default namespace for all the entities defined in the file, if not overriden.

## Entities

Defining an entity is the very first step you will do with AML. And it's as simple as typing its name:

```aml
posts
```

This entity can have columns, indexes, relations and more, but let's dive a bit more into its definition.

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
{color: red, size: 12, flag}
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


## Migration guide

Coming from the previous version, the mindset is the same: the most clean, easy and quick DSL for database schema.
There is some additions, but also some changes.
Here are the breaking changes:
- inline relations use the `->` symbol instead of `fk` (closer to the standalone definition and allow other kind of relations as well as polymorphic ones)
- standalone relations use the `rel` symbol instead of `fk` (`fk`, for foreign key was too close to relational db and was not right sometimes, some relations exist without being a foreign key)
- the `table.column` reference is replaced by `table(column)` (it's closer to SQL and allow to mix namespace and column path (like `public.table1(details.name)`), and get rid of the `:` separator for column path. It also allow support for composite relations: `table(user_id, role_id)`)
