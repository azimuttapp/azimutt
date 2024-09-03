# AMLv2: Azimutt Markup Language

[back to home](./README.md)


## Type

Custom types can be helpful for better semantics, consistency, constraints or even structure data.

Defining and using a type in AML is straightforward:

```aml
type bug_status

bugs
  id uuid pk
  status bug_status
```

This type has a name but nothing else, so except semantics, the status attribute doesn't have a concrete type defined.

For such usage, they don't need to be defined standalone as attribute types can handle anything, so this is also perfectly fine:

```aml
bugs
  id uuid pk
  status bug_status
```


### Alias

To add some semantics and have a concrete type, a type can map to another one, like a type alias:

```aml
type bug_status varchar
```


### Enum

Defining enums can be really helpful to make the schema clearer. They can be defined inline in the attribute definition:

```aml
bugs
  id uuid pk
  status bug_status(new, "in progress", done)
```

Or standalone:

```aml
type bug_status(new, "in progress", done)
```


### Struct

Types can also hold a struct, this can be seen a bit similar to nested attributes, but it's a different and reusable perspective. 

```aml
type bug_status{internal varchar, public varchar}
```


### Custom

Types can also hold custom definitions like:

```aml
type bug_status `range(subtype = float8, subtype_diff = float8mi)`
```


### Namespace

Like [entities](./entity.md), types are defined within a [namespace](./namespace.md) and inherit the defined default namespace:

```aml
type reporting.public.bug_status varchar
```


### Metadata

Types can also have [custom properties](./properties.md) and [documentation](./documentation.md):

```aml
type bug_status varchar {private, tags: [seo]} | defining a post status
```

But this works only for standalone definition, when inline, properties and documentation will be assigned to the attribute ^^
