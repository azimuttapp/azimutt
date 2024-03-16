# AML: Azimutt Markup Language

## Identifier

Identifiers are names for objects. You can find them everywhere, for [entities](./entity.md) or fields, [namespaces](./namespace.md) or [relations](./relation.md) and [types](./type.md).

They are composed of word characters, so any [snake_case](https://wikipedia.org/wiki/Snake_case) or [CamelCase](https://wikipedia.org/wiki/Camel_case) notation will be fine, here is their specific regex: `\b\w+\b`.

If you need to include other things inside such as spaces or special characters, you can escape them using `"`.

Here are a valid identifiers:

- `posts`
- `post_authors`
- `"user events"`
