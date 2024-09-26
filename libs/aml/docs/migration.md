# AML - Azimutt Markup Language

[back to home](./README.md)


## Migration from v1

This new version of AML is coming 2 years after [the first one](./v1/README.md) ([post](https://azimutt.app/blog/aml-a-language-to-define-your-database-schema) & [PR](https://github.com/azimuttapp/azimutt/pull/98) ^^).
During this time, we discovered a lot of new use cases and some shortcomings (such as composite foreign keys).

This new iteration fixes the issues, improve consistency and add nice features such as [namespace](./namespace.md), [properties](./properties.md), [nested attributes](./entity.md#nested-attribute), [polymorphic relations](./relation.md#polymorphic-relation) and more.

We made it mostly retro-compatible, so you only have to fix the issued warnings (or use our [migration tool](https://azimutt.app/converters/amlv1/to/aml) ^^).


### Semantic changes

AMLv1 was built with relational databases in mind, too much in fact. So we had **tables**, **columns** and **foreign keys**.

We wanted to make this new iteration AML more generic to better embrace the diversity of databases as well as other types of modeling, so we renamed:

- **table** to **entity**
- **column** to **attribute**
- **foreign key** to **relation**

As AML doesn't have a lot of keywords, it almost changes nothing in its syntax, except for foreign keys.


### Breaking changes

#### Standalone relation: change `fk` to `rel`

In AMLv1, you could define standalone relations like this:

```amlv1
fk events.created_by -> users.id
```

Now, you will define this with the `rel` keyword:

```aml
rel events(created_by) -> users(id)
```

**Why**:

- this is to align with semantic changes described above, some relations are not foreign keys, so it makes more sense like this


#### Inline relation: change `fk` to `->`

In AMLv1, you could define relations inline with the attribute such as:

```amlv1
posts
  id uuid pk
  author uuid fk users.id
```

Now, it needs to be changed to:

```aml
posts
  id uuid pk
  author uuid -> users(id)
```

**Why**:

- we introduced [relation kinds](./relation.md#one-to-one): **one-to-one** (`--`), **many-to-one** (`->`) and **many-to-many** (`<>`), it fits well with the many-to-one `->` and would have been harder to keep obvious with the `fk` keyword
- we introduced [polymorphic relations](./relation.md#polymorphic-relation), the `->` giving the opportunity to specify the kind column inside the relation link: `rel events(item_id) -item_kind=User> users(id)`, which would have been harder to keep simple with the `fk` keyword
- we semantically moved from **foreign keys** to **relations** as some relations are not materialized by foreign keys. This is the case on document databases but also on relational databases for polymorphic relations or by the choice of developers (performance reasons or other).
- it's a closer definition to the standalone definition of relations, the end is identical: `-> users(id)`


#### Attribute ref: change from `table.column` to `table(column)`

In AMLv1, column references are defined with a `.` between the table and the column:

```amlv1
fk events.created_by -> users.id
```

Now, we use `()` instead to separate the entity from the attribute(s):

```aml
rel events(created_by) -> users(id)
```

**Why**:

- we introduced [composite relations](./relation.md#composite-relation): several columns pointing at several other columns, with the previous notation it was not clear how to specify them, now it's obvious: `rel events(user_id, role_id) -> user_roles(user_id, role_id)`
- the support of [nested attributes](./entity.md#nested-attribute) was introduced later with a specific separator (`:`) to avoid confusion between `schema.table.column` and `table.column.nested`, the syntax was `table.column:nested`, this was ugly and with this change we can fix this 😎
- it's closer to the SQL syntax, which should make a lot of people more at home


#### Nested attribute: change `:` to `.`

In AMLv1, nested columns could be referenced like this:

```amlv1
fk events.details:user_id -> users.id
```

I guess almost nobody used it as it was not properly documented, and you couldn't create nested columns with AMLv1 (they have to come from a database source).

Now, you can simply use the `.`, thanks to the attribute ref change with the `()` (no more confusion):

```aml
rel events(details.user_id) -> users(id)
```

**Why**:

- the previous syntax was an ugly hack to introduce unplanned feature, we took this new version as an opportunity to fix it ^^
