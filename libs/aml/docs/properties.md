# AML - Azimutt Markup Language

[back to home](./README.md)


## Custom properties

Custom properties are key/value pairs defined on objects to add some flexible context or documentation beside the schema.
They are a good complement to [textual documentation](./documentation.md), being less expressive but more structured.

Here is an example: `{color: red, pii: true}`

Keys are [identifiers](./identifier.md) and values can have several forms:

- boolean, ex: `{pii: true}`
- number, ex: `{size: 12}`
- identifier, ex: `{color: red}`
- array, ex: `{tags: [pii, sensitive]}`
- omitted, ex: `{auto_increment}`

You can use any key/value pair, they will be kept in the model.

Some specific keys are standardized for certain objects and can be interpreted by generators or in [Azimutt](https://azimutt.app).


### Entity properties

Here are the standardized properties for [entities](./entity.md):

- `color`, to define the default Azimutt color, values: red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose, gray
- `icon`, show a nice icon in the entity header, values: email, folder, home, user, users...
- `position`, to define the default position when added to a layout, the value should be an array with two numbers
- `notes`, to define default notes for the entity
- `tags`, to define default tags for the entity
- `deprecated`, will be added to tags in Azimutt but can be better defined here
- `hidden`, will be added to tags in Azimutt but can be better defined here

An example with all the properties:

```aml
users {color: red, position: [50, 50], notes: "some notes here", tags: [pii], deprecated}
```


### Entity attribute properties

Here are the standardized properties for [entity attributes](./entity.md#attribute):

- `auto_increment`
- `hidden`, to make the column not visible by default
- `notes`, to define default notes for the entity
- `tags`, to define default tags for the entity
- `deprecated`, will be added to tags in Azimutt but can be better defined here

An example with all the properties:

```aml
users
  id {auto_increment, notes: "some notes here", tags: [pii], deprecated}
```


### Relation properties

Here are the standardized properties for [relations](./relation.md):

- `on_update`, values should be in: no_action, set_null, set_default, cascade, restrict
- `on_delete`, values should be in: no_action, set_null, set_default, cascade, restrict

An example with all the properties:

```aml
rel posts(author) -> users(id) {on_update: no_action, on_delete: cascade}
```


### Type properties

None for now
