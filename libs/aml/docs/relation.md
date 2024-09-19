# AML - Azimutt Markup Language

[back to home](./README.md)


## Relation

Relations are edges in [Entity-Relationship model](https://wikipedia.org/wiki/Entity%E2%80%93relationship_model). In relational databases, they can be modeled with **foreign keys**, but not necessarily.

In AML, they can be defined either as an [attribute option](./entity.md#index-and-constraint):

```aml
users
  id uuid pk

roles
  id uuid pk
  created_by uuid -> users(id)

user_roles
  user_id uuid pk -> users(id)
  role_id uuid pk -> roles(id)
```

Or standalone:

```aml
users
  id uuid pk

roles
  id uuid pk
  created_by uuid

user_roles
  user_id uuid pk
  role_id uuid pk

rel roles(created_by) -> users(id)
rel user_roles(user_id) -> users(id)
rel user_roles(role_id) -> roles(id)
```

If the target entity has a **single attribute primary key**, the target attribute can be omitted (will be assigned to the primary key).

```aml
users
  id uuid pk

roles
  id uuid pk
  created_by uuid

user_roles
  user_id uuid pk -> users
  role_id uuid pk -> roles

rel roles(created_by) -> users
```

Also, if omitted, the attribute type will be defined using the targeted attribute, so this is equivalent to the previous definition:

```aml
users
  id uuid pk

roles
  id uuid pk
  created_by

user_roles
  user_id pk -> users
  role_id pk -> roles

rel roles(created_by) -> users
```


### Many to One

Relations defined with `->` are **many-to-one** relations: several rows can target a single one.


### One to One

Relation with **one-to-one** cardinality can be defined using the `--` symbol.
If neither side of the relation has a unique index, AML compiler will issue a warning as the logical definition doesn't match the physical one.

```aml
users
  id uuid pk

profiles
  id uuid pk -- users(id)
```

Or as standalone:

```aml
users
  id uuid pk

profiles
  id uuid pk

rel profiles(id) -- users(id)
```

You can ignore attribute specification when there is single attribute primary key:

```rel
rel profiles -- users
```

Also, a different implementation could be:

```aml
users
  id uuid pk

profiles
  id uuid pk
  user_id uuid unique -- users
```


### Many to Many

Relations with **many-to-many** cardinality are usually implemented with a join entity having two many-to-one relations like:

```aml
users
  id uuid pk

projects
  id uuid pk

user_projects
  user_id pk -> users
  project_id pk -> project
```

If you don't care about the join entity, you can define it logically in AML with:

```aml
users
  id uuid pk

projects
  id uuid pk

rel projects(id) <> users(id)
```

And even without defining the attribute as there is single attribute primary keys:

```aml
rel projects <> users
```


### Nested attributes

Relations can connect nested attributes as well:

```aml
users
  id uuid pk
  details
    twitter_id varchar

companies
  id uuid pk

events
  id uuid pk
  details json
    company json
      id uuid -> companies(id)

tweets
  id uuid pk
  profile varchar -> users(details.twitter_id)
```

Of course, this also works with standalone relations:

```aml
users
  id uuid pk
  details
    twitter_id varchar

companies
  id uuid pk

events
  id uuid pk
  details json
    company json
      id uuid

tweets
  id uuid pk
  profile varchar

rel events(details.company.id) -> companies(id)
rel tweets(profile) -> users(details.twitter_id)
```


### Composite relation

If you have a composite primary key, you may also want composite foreign keys. You can easily define them by listing all the attributes:

```aml
users
  id uuid pk

projects
  id uuid

user_projects
  user_id pk -> users
  project_id pk -> projects

user_project_rights
  user_id pk
  project_id pk
  access project_right(read, write)=read

rel user_project_rights(user_id, project_id) -> user_projects(user_id, project_id)
```

This kind of relation can only be defined using standalone relation.


### Polymorphic relation

Polymorphic relations are used to target different entities depending on the value of another attribute.

For example, if you want to make a comment system in your app and be able to comment on different entities, you can either create one comment entity for each entity, like:

```aml
posts
  id uuid pk
  title varchar

post_comments
  id uuid pk
  post_id -> posts
  content text

pages
  id uuid pk
  title varchar

page_comments
  id uuid pk
  page_id -> pages
  content text
```

But this can become painful as the number of commentable entities grows, keeping everything consistent or getting all the comments from a user.

Instead, you can create a single comment entity targeting different entities, depending on an attribute value (discriminator):

```aml
posts
  id uuid pk
  title varchar

pages
  id uuid pk
  title varchar

comments
  id uuid pk
  item_kind comment_kind(posts, pages)
  item_id uuid
  content text

rel comments(item_id) -item_kind=posts> posts(id)
rel comments(item_id) -item_kind=pages> pages(id)
```

We could even make nested comments with:

```aml
rel comments(item_id) -item_kind=comments> comments(id)
```

The value is not always the table name, some ORMs use the model name instead, so it could be `Post` instead of `posts`.


### Metadata

Relations can also have [custom properties](./properties.md) and [documentation](./documentation.md):

```aml
rel projects(created_by) -> users(id) {onDelete: cascade, ignore} | the user creating the project
```

But this works only for standalone definition, when inline, properties and documentation will be assigned to the attribute ^^
