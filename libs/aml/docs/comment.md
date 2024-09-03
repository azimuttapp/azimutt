# AMLv2: Azimutt Markup Language

[back to home](./README.md)


## Comments

AML comments are used to note things in the AML source without taking them into account in the parsing result.

There are only line comments starting with the `#` character, everything after will be ignored.

They can be helpful to visually identify sections, add beloved TODOs or explain why you did some things.

Here is an example:

```aml
# this is a comment

#
# Auth schema
#

users
  id uuid pk # all ids should be uuid, please!
  name varchar
  details json # TODO: specify the schema here!

#
# Social schema
#

# posts are blog posts, for SEO ^^
posts
  id uuid pk
  author -> users(id) # don't define relation types, they will be inherited from their linked column

# TODO: add social media entities
```

The only place they are not supported is in [multiline documentation](./documentation.md#multiline-documentation).
