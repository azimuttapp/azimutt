---
title: The best language to design databases, just upgraded 🤯
banner: "{{base_link}}/landing.png"
excerpt: Want to design a database without all the SQL ceremony? AML got you covered, being fast to learn and write, yet flexible and with convertors to other dialects (SQL, JSON, Markdown, Mermaid...).
category: azimutt
tags: [AML]
author: loic
---

If you already know [AML](/aml), you know how easy it makes database design.

If you don't, now is your chance to learn about it and improve your database tooling.

*And if you think the title is too much, let us know better ones, we can't find any ^^*

## Previously on AML

AML, or Azimutt Markup Language, is a very simple DSL made to design database schemas.
Its first goal is allowing you to write your thoughts as fast as possible in a structured way. So, almost no keyword or special characters:

```aml
users
  id
  name
  email
  created_at

posts
  id
  status
  title
  content
  author -> users(id)
```

Of course, you may want to add more details afterwards, and you can:

```aml
users {color: blue}
  id int pk {autoIncrement}
  name varchar(50) index
  email varchar(100) unique check(`email LIKE '%@%'`) {tags: [pii]}
  created_at timestamp=`now()` {hidden}

posts {owner: teamCMS}
  id uuid pk
  status post_status(draft, published, archived)=draft index
  title varchar index
  content text | supports markdown formatting
  author int -> users(id)
```

The [initial version](./aml-a-language-to-define-your-database-schema) was published more than 2 years ago, and aged quite well.
The main goal of this new iteration was to migrate from Elm to TypeScript to provide better tooling, and improve a few things (see below).

## What's new in AML?

First, it has its own [home page](/aml) 😎

[![AML landing page]({{base_link}}/landing.png)](/aml)

Then, in the language, not much changed. Look at the [migration guide](https://azimutt.app/docs/aml/migration) but in short:

- relation keyword changed from `fk` to `ref`
- attribute ref changed from `table.column` to `table(column)`
- nested fields changed from `column:nested` to `column.nested`

This brings more consistency to the language. The biggest improvements were addition enabling new use cases and more flexibility:

- [relation cardinality](https://azimutt.app/docs/aml/relations#many-to-one)
  - `rel posts(author) -> users(id)` (many-to-one)
  - `rel profiles(id) -- users(id)` (one-to-one)
  - `rel projects(id) <> users(id)` (many-to-many)
- [composite relations](https://azimutt.app/docs/aml/relations#composite-relation)
  - `rel member_rights(user_id, org_id) -> members(user_id, org_id)`
- [polymorphic relations](https://azimutt.app/docs/aml/relations#polymorphic-relation)
  - `rel comments(item_id) -item_kind=Post> posts(id)`
- [properties](https://azimutt.app/docs/aml/properties)
  - `admins {color: gray, owner: teamA, tags: [pii, private]}` (entity)
  - `  id bigint pk {autoIncrement, hidden}` (attribute)
  - `rel projects(owner) -> users(id) {onDelete: cascade}` (relation)
- [types](https://azimutt.app/docs/aml/types)
  - `type id` (anonymous)
  - `type label varchar(50)` (alias)
  - `type status (draft, public, private)` (enum)
  - `type position {x int, y int}` (struct)
  - ``type age `range (0..150)` `` (custom)
- [namespaces](https://azimutt.app/docs/aml/namespaces)
  - `namespace my_schema` (everything after will have this schema)

Have a look at the [full documentation](https://azimutt.app/docs/aml) to get exhaustive view about this new version.

If you want to see how it looks like at scale, you can check this [800 lines schema](https://raw.githubusercontent.com/azimuttapp/azimutt/refs/heads/main/demos/ecommerce/source_00_design.md) from the [e-commerce demo](https://azimutt.app/45f571a6-d9b8-4752-8a13-93ac0d2b7984/c00d0c45-8db2-46b7-9b51-eba661640c3c?token=9a59ccbb-7a58-4c88-9dfc-692de6177be9).

## What's the big deal?

The language improved and made new use case possibles, that's nice!

But here is the real big deal: in addition to Azimutt editor, AML is now available as a [standalone library](https://www.npmjs.com/package/@azimutt/aml) on npm 🎉
So you can use it on your own (JavaScript) projects 🚀

It also has a great [Monaco editor integration](https://github.com/azimuttapp/azimutt/blob/main/libs/aml/src/extensions/monaco.ts), allowing you to not only write AML but also have a full-fledged IDE for it, with syntax highlighting, completions, contextual errors and more...

Finally, all this made possible for us to build [dialect converters](/converters) from/to several dialects like: AML (of course!), SQL (PostgreSQL for now), Markdown (for doc), Mermaid, JSON...
You can experience everything [right into your browser](/converters/aml/to/postgres) with just one click ❤️

[![AML to PostgreSQL converter]({{base_link}}/aml-to-postgres.png)](/converters/aml/to/postgres)

Give it a try and tell us what you think about this new AML version, the additional tooling we made and the other languages you want to see in our converters 🤩
