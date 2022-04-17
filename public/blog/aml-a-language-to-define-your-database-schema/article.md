---
title: AML, a language to define your database schema
excerpt: When you have an idea, you want to write it as fast as possible because your thoughts are much quicker than your hands. Having tools that let you do that is a must when having a discussion or brainstorming.
category: azimutt feature
tags: automation
author: loic
published: 2022-04-11
---

While Azimutt is primarily a database schema explorer allowing you to better navigate and understand big databases, I regularly get requests to extend it. Which totally makes sense when you are working on new evolutions or features. I delayed this as I had more important feature to develop such as [embed](./embed-your-database-diagram-anywhere) or [schema analysis](./improve-your-database-design-with-azimutt-analyzer), and I didn't know how to do it well, but **it is now time**.

![hello]({{base_link}}/hello.jpg)

I reviewed a lot of tools to build a [choice guide](./how-to-choose-your-entity-relationship-diagram) and could experiment many ways to define it. Most of them were quite bad with inputs for each information and a lot of buttons to add/edit/delete/move everything. Only two use a simple language to define your schema. You could write it as full text, allowing copy/paste, code generation and even versioning. The experience was incredible. It seems obvious now, as we are not writing code just for fun but because it's the most efficient way to express ourselves with various levels of strictness or abstraction. And so AML was born in my mind.

AML stands for **Azimutt Markup Language**. Its goal is clear: define a SQL database structure in the easiest and lightest way possible. It's meant to be intuitive and used without any prior learning.

## Azimutt Markup Language

This is the first iteration of this language, to [get your feedback](https://github.com/azimuttapp/azimutt/issues/84) before implementing it in Azimutt. If you want to help me, creating this simple language, take a moment and write on a notepad a basic schema in the more natural way. Then you can compare it with Azimutt and give me feedback on differences and possible improvements.

In order to limit learning but also mistakes and typing speed, AML has very little syntax and symbols, the most used parts look like just free text. Here is a typical example of a table definition:

```
users
  id uuid pk
  first_name varchar(128)
  last_name varchar(128)
  email varchar(128) nullable
```

And another one with more attributes involved:

```
credentials
  user_id pk fk users.id
  login varchar(128) unique
  password varchar(128) nullable
  role varchar(10)=guest
  created_at timestamp
```

I hope both are quite clear from the first reading. Please let me know if you have any interrogations of what something could mean, so I can improve the notation.

Now let's discover more precisely all the details of this language for Azimutt.

- [Table definition](#table-definition)
- [Column definition](#column-definition)
- [Constraint definition](#constraint-definition)
- [Relation definition](#relation-definition)
- [Metadata definition](#metadata-definition)
- [Conventions](#conventions)
- [Recap](#recap)

### Table definition

In SQL, every table is defined by its schema and name, so does in AML. A table can be defined as easy as:

```
schema_name.table_name
```

As it's very common to put table in the default schema named `public`, you can omit the schema, in this case the declaration becomes just:

```
table_name
```

The schema and table names are identifiers, they can include any character except space, dot and equal. To have them, just surround them by double quotes:

```
"schema name"."my.table.with.dots"
```

Finally, if you want a view instead of a table, add a `*` just after the name:

```
a_view*
```

That's it. Now you can define several tables very quickly:

```
public.users
"users.2"
credentials
orgas*
```

Just make sure to have them alone on the line.

### Column definition

Defining tables is nice but columns are as important. To add them, just go to the line with a two space indent:

```
users
  id
  name
```

That's it. With that, you have a `users` table with two columns `id` and `name`. Their type is set to `unknown`, but you can specify it, just after the name:

```
users
  id uuid
  name varchar
```

Same as schema and table names, column name and type are identifier, so if they contain space, dot or equal they should be surrounded by `"`.
By default, columns are considered NOT NULL as it's a good practice to limit null but of course, you can mark column as nullable with the `nullable` keyword ^^
You can also define column default value by following the type with an equal sign and the value (it's an identifier, use `"` to include special chars).

```
users
  id uuid
  name varchar nullable
  created_by timestamp=now()
```

### Constraint definition

Constraints are also really important in database design, so of course you can specify them. But as it's a database diagram and not a real database, they are a bit simplified in regard of all the options offered by the different SGBDs.

First, to define a primary key, you simply need to add the `pk` keyword on the columns being part of it (just one most of the time, multiple ones are supported):

```
users
  id uuid pk
```

For other constraints like `unique`, `index` and `check` it's very similar, just add the keyword at the end of the column definition. One notable difference though, they are not automatically grouped as composite constraints. For that, you will need to specify identical identifiers just after the keyword with an equal sign:

```
users
  id uuid pk
  first_name varchar unique=name
  last_name varchar unique=name
  age integer index
```

The `check` constraint can be followed by a predicate identifier that specify what is the performed check. In case of composite constraint, you can just specify the predicate in one of the columns. If multiple ones are defined, only the first one is kept.

Finally, *and most importantly*, you can define foreign key constraints with the `fk` keyword followed by the column reference (WHAT A SURPRISE!!!):

```
credentials
  user_id fk public.users.id
```

Of course, the schema can be omitted when it's `public`, the default one:

```
credentials
  user_id fk users.id
```

When a column has an `unknown` type and a foreign key, it inherits from the linked column type. Depending on your usage, it may be practical to leave it empty to keep them consistent without effort or define them to reflect your database state.

### Relation definition

Defining a foreign key constraint creates a relation, and it should be enough most of the time (see below). But when extending an existing one, you may need to add a relation to a table you didn't define (as it was defined in another source).

In this case, you have the standalone foreign key definition, starting with the `fk` keyword:

```
fk credentials.user_id -> users.id
```

If you have/need polymorphic relations, meaning a column (ex: item_id) referencing several tables depending on another column value (ex: item_type), you can add several foreign keys for the same columns using this standalone definition:

```
request
  id uuid
  kind varchar
  item_type varchar
  item_id integer

fk request.item_id -> users.id
fk request.item_id -> talks.id
fk request.item_id -> logins.id
```

For now, composite relations, multiple columns referencing multiple others, are not supported in Azimutt so not defined in AML. The main obstacle is the graphical representation of them so if you have any idea on this, don't hesitate to [make some suggestions]({{issues_link}}). One potential syntax for AML could be:

```
fk (logins.provider_id, logins.provider_key) -> (credentials.provider_id, credentials.provider_key)
```

### Metadata definition

Defining the schema with tables and relations is great, but sometimes you need some textual documentation. Hopefully, SQL offers comments. With AML you can add them to any entity in their line after a `|` symbol. This is true for tables, columns but also relations or even groups (see later).

```
users | Store all our users
  id uuid | Unique identifier for a user
  name varchar
```

These SQL comments are not identifiers, so you don't need any `"` escaping for space, dot or equal. The only character that will need escaping is `#`, as it defines an AML comment. Everything after will just be ignored. For example, this will produce exactly the same thing as the just above code:

```
# User table
users | Store all our users # I'm an AML comment
  id uuid | Unique identifier for a user
  name varchar # you will not see me
```

The syntax shown so far defines the database schema. But Azimutt being a diagram tool, it also has some interesting data you may want to define such as table position and color or if a column is shown or not. For that, you can use a JSON like definition with attributes as `key=value` or `property` inside `{}`:

```
users {color=red, top=10, left=100}
  id integer
  name varchar(10) {hidden}
```

Each entity has its own available properties as you can see above:

- tables have a position (top/left) and a color (in list: indigo, violet, purple, fuchsia, pink, rose, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue)
- columns have only a hidden property to hide it by default

### Conventions

Keywords such as `pk`, `fk`, `nullable` or `unique` are expected to be written in lowercase as it's easier to write (one less key!) but if you want to make them stand out from the rest you can also write them in uppercase. That's your preference.

### Recap

Explaining everything in details is quite long, but I hope everything is quite natural and the Azimutt editor will help with meaningful errors and contextual documentation and examples, so it should be really easy to use it for the first time.
At least it's the goal so if you see anything that may be confusing, [please reach out](https://github.com/azimuttapp/azimutt/issues/84). Hopefully we can fix it before the first release.

Another important thing to note about Azimutt source management: all active sources are merged to produce your browsable diagram. Your written ones but also imported ones. It could be very convenient to have several sources representing different evolutions but as they are all additive, you can't remove a table or column from another source. That's a small limitation you will have to keep in mind.

Here is an example with almost all the feature used just as a reminder and general overview:

```
emails
  email varchar
  score "double precision"

# How to define a table and it's columns
public.users {color=red, top=10, left=100} | Table description # a table with everything!
  id integer pk
  role varchar=guest {hidden}
  score "double precision"=0.0 index {hidden} | User progression # a column with almost all possible attributes
  first_name varchar(10) unique=name
  last_name varchar(10) unique=name
  email varchar nullable fk emails.email

admins* | View of `users` table with only admins
  id
  name | Computed from user first_name and last_name
  
fk admins.id -> users.id
```

Hope you liked it! I'm very excited to see it live in [Azimutt](https://azimutt.app/projects) soon.

![work]({{base_link}}/work.jpg)

Cheers!
