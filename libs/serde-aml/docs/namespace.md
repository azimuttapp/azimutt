# AML: Azimutt Markup Language

## Namespace

Objects of the database, such as [entities](./entity.md) or [relations](./relation.md), can be grouped into hierarchical layers to organize them.

In AML there is 3 hierarchical levels defined with [identifiers](./identifier.md), from top to bottom:

- **database**
- **catalog**
- **schema**

They are made to match most of the DBMS structures which have hierarchical levels.

Each level is optional and when defining a database object, they can be added in front of it, from the lower to the higher.

Here is some examples:

- `users` defines the users entity with no hierarchy level
- `public.users` defines the users entity inside the public schema
- `core.public.users` defines the users entity inside the public schema and core catalog
- `analytics.core.public.users` defines the users entity inside the public schema, core catalog and analytics database

This can be done anywhere, for example in relations:

```aml
rel public.posts(user_id) -> auth.users(id)
```

### Top level namespace

As it can be painful to repeat everywhere the namespace, you can use the top level namespace directive to apply as default namespace to every following object:

```aml
namespace core.public

users # defines the `users` entity inside the `core` catalog and `public` schema
```

Even with a top level namespace defined, you can override the namespace by specifying it explicitly:

```aml
namespace core.public

dto.users # defines the `users` entity inside the `core` catalog but in the `dto` schema, not the `public` one
```

Finally, you can override the default namespace with a new one, for example:

```aml
namespace auth

users # defines the `users` entity inside the `auth` schema

namespace seo # override the default namespace

posts # defines the `posts` entity inside the `seo` schema
```

The new defined namespace fully override the previous one, for all levels:

```aml
namespace core.public
namespace seo
posts # defines the `posts` entity inside the `seo` schema (not inside the `core` catalog)
```
