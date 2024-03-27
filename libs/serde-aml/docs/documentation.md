# AMLv2: Azimutt Markup Language

[back to home](./README.md)


## Textual documentation

Documentation can be added to objects to add textual context to them.
It complements well the [custom properties](./properties.md) with a more people oriented context, it will be rendered with [Markdown syntax](https://wikipedia.org/wiki/Markdown) in [Azimutt](https://azimutt.app).

To use it, just add a `|` at the end of the object definition, here is an example:

```aml
users | store users
```

It can be used on: [entities](./entity.md), [attributes](./entity.md#attribute), [relations](./relation.md) and [types](./type.md).

Here are examples:

```aml
type post_status enum(draft, published, archived) | post lifecycle

public.users | storing all users
  id uuid pk
  name varchar
  email varchar unique | auth identifier

posts
  id uuid
  status post_status
  title varchar
  content text
  author uuid

rel posts(author) -> public.users(id) | link post author
```


### Multiline documentation

If you want longer documentation, you can use multiline documentation with `|||`.

Here is the same example as above:

```aml
type post_status enum(draft, published, archived) |||
  post lifecycle
|||

public.users |||
  storing all users
|||
  id uuid pk
  name varchar
  email varchar unique |||
    auth identifier
  |||

posts
  id uuid
  status post_status
  title varchar
  content text
  author uuid

rel posts(author) -> public.users(id) |||
  link post author
|||
```

The common indentation to every line will be removed using [stripIndent](../../utils/src/string.ts) to keep your code and documentation clean 😉
