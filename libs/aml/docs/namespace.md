# AML - Azimutt Markup Language

[back to home](./README.md)


## Namespace

Objects of the database, such as [entities](./entity.md), [relations](./relation.md) or [types](./type.md), can be grouped under hierarchical layers to organize them.

In AML there are 3 hierarchical levels defined with [identifiers](./identifier.md), from top to bottom:

- **database**
- **catalog**
- **schema**

They are made to match most of the DBMS structures, which have hierarchical levels.

Each level is optional. When defining a database object, they can be added in front of it, from the lower to the higher.

Here are some examples:

```aml
users # defines the users entity with no hierarchical level

public.users # defines the users entity inside the public schema

core.public.users # defines the users entity inside the public schema and core catalog

analytics.core.public.users # defines the users entity inside the public schema, core catalog and analytics database
```

This can be done anywhere, for example in relations:

```aml
rel public.posts(user_id) -> auth.users(id)
```


### Namespace directive

As it can be painful to repeat everywhere the same namespace, you can use the namespace directive to define one as default for every following object:

```aml
namespace core.public

users # defines the `users` entity inside the `core` catalog and `public` schema
```

Even with a default namespace defined, you can override it by specifying it explicitly:

```aml
namespace core.public

dto.users # defines the `users` entity inside the `core` catalog but in the `dto` schema instead of the `public` one
```

Finally, you can override the default namespace with a new one, for example:

```aml
namespace auth

users # defines the `users` entity inside the `auth` schema

namespace seo # override the previous default namespace

posts # defines the `posts` entity inside the `seo` schema
```

The new defined namespace fully overrides the previous one, for all levels:

```aml
namespace core.public
namespace seo
posts # defines the `posts` entity inside the `seo` schema (not inside the `core` catalog)
```

Having an empty namespace removes the current namespace:

```aml
namespace public

users # the users entity in inside the public schema

namespace

posts # the posts entity has no hierarchical level (not in the public schema)
```
