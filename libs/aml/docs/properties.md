# AML - Azimutt Markup Language

[back to home](./README.md)


## Custom properties

Custom properties are key/value pairs defined on objects to add some flexible context or documentation beside the schema.
They are a good complement to [textual documentation](./documentation.md), being less expressive but more structured.

Here is an example: `{color: red, pii}`

Keys are [identifiers](./identifier.md) and values can have several forms:

- boolean, ex: `{pii: true}`
- number, ex: `{size: 12}`
- identifier, ex: `{color: red}`
- array, ex: `{tags: [pii, sensitive]}`
- omitted, ex: `{autoIncrement}`

You can use any key/value pair, they will be kept in the model.

Some specific keys are standardized for certain objects and can be interpreted by generators or in [Azimutt](https://azimutt.app), see below.


### Entity properties

Here are the standardized properties for [entities](./entity.md):

- `view`, define the entity as a view, use it to define the view query, ex: `{view: "SELECT * FROM users"}`
- `color`, to define the entity default color for Azimutt layouts, values: red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose, gray (`{color: red}`)
- `tags`, to define tags for the entity (`{tags: [pii, "owner:team1"]}`)

Here is an example:

```aml
users {color: red, tags: [pii, deprecated]}
```

Some others are considered but not handled yet:

- `icon`, show an icon in the entity header, values: email, folder, home, user, users... (`{icon: user}`)
- `position`, define the default position when added to a layout, the value should be an array with two numbers, left and top (`{position: [15, 10]}`)
- `notes`, define default notes for the entity (similar to doc but saved in Azimutt) (`{notes: "stored in Azimutt"}`)
- `deprecated`, will be added to tags in Azimutt (`{deprecated}`)


### Entity attribute properties

Here are the standardized properties for [entity attributes](./entity.md#attribute):

- `autoIncrement`, for primary keys with auto-increment (`{autoIncrement}`)
- `hidden`, to make the column not visible by default on layouts (`{hidden}`)
- `tags`, to define default tags for the attribute (`{tags: [pii]}`)

Here is an example:

```aml
users
  id {autoIncrement, tags: [pii]}
```

Some others are considered but not handled yet:

- `notes`, define default notes for the entity (similar to doc but saved in Azimutt) (`{notes: "stored in Azimutt"}`)
- `deprecated`, will be added to tags in Azimutt (`{deprecated}`)


### Relation properties

Here are the standardized properties for [relations](./relation.md):

- `onUpdate`, values should be in: no action, set null, set default, cascade, restrict ({`onUpdate: "set null"`})
- `onDelete`, values should be in: no action, set null, set default, cascade, restrict ({`onDelete: "cascade"`})

An example with all the properties:

```aml
rel posts(author) -> users(id) {onUpdate: "no action", onDelete: cascade}
```


### Type properties

None for now
