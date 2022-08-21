# AML: Azimutt Markup Language

**AML is a text language allowing you to define your database schema in the quickest and most intuitive way.**

It was built with the minimal boilerplate to be fast to write but also to limit the learning curve and possible mistakes.  It's, of course, the language used in [Azimutt](https://azimutt.app) to define or extend your schema (along with other data sources like SQL code, database connection or even JSON).

Here is a typical example of what it looks like:

```aml
users | store every user # AML comment
  id uuid pk
  login varchar(30) unique
  role user_role(guest, member, admin)=guest
  email varchar nullable
  group_id fk groups.id
  created timestamp=now()
```

As you can see, almost all characters are your own content, no ceremony.

Now let's dig more into it and see all the features...  
If you want to try them live, just create a [new empty project](https://azimutt.app/projects/create) on Azimutt.

- [Tables](#-tables)
- [Columns](#-columns)
- [Relations](#-relations)
- [Comments](#-comments)
- [Philosophy & Conventions](#-philosophy--conventions)
- [Full example](#-full-example)

## 🔖 Tables

Defining a table is the most common thing you will do with AML, and it's as simple as writing its name:

```aml
my_table_name
```

This name should be without space or dot but to allow them you can use `"`.  
You can prefix your table name with its schema name followed by a dot if you want, the same rules apply to it (no space or dot, or use `"`).  
Finally, you can add a `*` at the end of the table name to mark it as a *view* instead of a table.

Here is some examples of tables definitions:

```aml
users
public.users
"user table"
"users.sql"
users_view*
"demo 2"."users 2"
```

As you can see, it's possible to define one table per line and with as little as one word, it's quite convenient to quickly write what you have in mind!

## 🔖 Columns

Tables are great, but without columns, they are a bit poor...  
A column can be defined as simple as its name with a 2 space indentation:

```aml
users
  id
```

Here you are, you just defined a `users` table with an `id` column 🎉  
It's very convenient to write very fast all the tables and columns you have in mind.
As for the table and schema names, if you need space or dot inside, you can use `"` around it.

Of course, you may want to provide additional details on columns, here is its full structure:

```aml
  name type nullable pk index unique check fk table.column | notes # comment
```

Every part being optional except the name. Some parts may have additional options.
Let's detail them...

- [Column type](#column-type)
- [Column modifiers](#column-modifiers)
- [Column relation](#column-relation)

### Column type

There is no SQL validation for it, you can write anything you want and define meaningful types names to help understanding your schema. Of course, the same rule applies, if you need spaces or dots inside, you will need to use `"` around.

If the type has a *default value*, you can write it just after an `=` sign (ex: `int=0`).  
If the type has *enumerable values*, you can write them in parenthesis (ex: `role(guest, admin)`).

Here are some valid examples:

- `int`: one of the most basic type ^^
- `"character varying"`: a type with space in it
- `varchar(12)`: a type with a precision (not treated as enum if only one or two values which are integers)
- `decimal(5, 2)`: another kind of precision
- `varchar=y`: a default value
- `state(active,disabled)`: an enum
- `role(guest, admin)=guest`: an enum with a default value

### Column modifiers

As seen in the [Columns](#-columns) section, a column can have several modifiers.

`nullable` is a simple flag, telling the column can contain `null` values. In AML, by default columns are not nullable, this is the opposite of SQL but much more convenient and quick to write, as most of your columns should not be nullable.

`pk` means *primary key*, use it to identify a column as a table primary key. You can use this flag in several columns to create a composite primary key.

`index`, `unique` and `check` have a similar behavior. You can use them as flag to express the column property, but you can also give them a name using the `=` sign (ex: `unique=user_slug`). This name will be shown in the interface but also will allow to create a constraint on several columns sharing the same constraint name.

For the `check` constraint, you can use this name (or label) to define the condition.

Here is some examples:

```aml
users
  id uuid pk
  first_name varchar unique=name
  last_name varchar unique=name check="LEN(last_name) > 3"
  bio text nullable

credentials
  provider_id varchar pk
  provider_key varchar pk
  user_id fk users.id
```

### Column relation

Some columns can reference another column, eventually using a SQL foreign key. In AML, this can be done with the `fk` keyword (shortcut for *foreign key* 😉) in the column definition or as a standalone instruction (see [Relations](#-relations)).  
This relation means a column references another one, and thus can be used in a join clause. But it does not necessarily imply there is a real foreign key in the database schema.

To define a relation in the column definition, just add the `fk` keyword with a column reference after like this: `fk table.column`, or with the table schema: `fk schema.table.column`.

In the case of [polymorphic relations](https://devdojo.com/tnylea/understanding-polymorphic-relationships), you can define several relations starting from a column, but the additional ones should be defined using standalone instructions (see [Relations](#-relations)).  
*For better consistency, it's recommended to only use standalone relations to define polymorphic relations even if not required by the language.*

For [composite relations](https://www.ibm.com/docs/en/informix-servers/14.10?topic=format-defining-composite-primary-foreign-keys) (involving several columns), they are **not supported** yet in AML or Azimutt. This is a planned evolution but no timeline has been decided as many other important features are still to come. If you need them, please reach out, so we can plan them.

## 🔖 Relations

As seen before, relations can be defined [inside the column definition](#column-relation), and it's often the most efficient way to do so. But, sometimes, is useful or needed to define them as a standalone instruction.

Here is how to do it:

```aml
fk projects.owner -> users.id
```

The standalone relation instruction should start with the `fk` keyword and then have two column references separated by a simple arrow (`->`).

This is useful to define multiple relations from a column (in case of polymorphic relations) or define relations between columns that are not defined in AML (useful to declare relations that were not found in SQL or database sources because they didn't have a foreign key).

Here is an example:

```aml
requests
  id uuid
  kind varchar
  item_type varchar
  item_id integer

fk requests.item_id -> users.id
fk requests.item_id -> talks.id
fk requests.item_id -> logins.id
```

## 🔖 Comments

Having comments on tables and relations can be a great help for people to understand how the database works. In AML you can define a *SQL comment* using the `|` symbol at the end of your table or column definition. It will be visible directly inside the interface.

For example:

```aml
users | store all our users
  id | column to uniquely identify a user
```

This is the only special part of AML that doesn't need `"` to contain spaces and dots.

There is also *AML comments* you can use to write explanations you don't want to show in the interface. They are useful to explain why you wrote what you wrote ^^. Such comments are defined with the `#` symbol and should be at the end of the line (everything after is ignored).  
SQL and AML comments can be combined in the same line but the AML one should **always** be after.

Let's see an example:

```aml
# the user table
users | store ALL users
  id | unique identifier # not sure if I should put `uuid` or `int`
  name varchar # which size?
  created_at timestamp=now() | never update this column
```

## 🔖 Philosophy & Conventions

In order to be the fastest to write, AML have very few keywords and symbols, and they are all very short and preferred in lower case for fluid typing.  
Still, if you want to highlight the difference between keywords and your content (names, types, doc...), you can write AML keywords in upper case to ease reading.  
But it's strongly encouraged to be consistent.

As said in introduction, AML is built to be very intuitive and fast to learn and write.
If you see possible improvements on the syntax or even features, please don't hesitate to [post an issue](https://github.com/azimuttapp/azimutt/issues), so we could improve it for everyone ❤️  
If you like it or want to give feedback, we will be very pleased to hear about you. Please get in touch with us on Twitter: [@azimuttapp](https://twitter.com/azimuttapp).

## 🔖 Full example

Now everything has been explained, let's write a meaningful example to give you a larger view of what it looks like to use AML as schema definition.

Let's define a hypothetical e-commerce shop:

![e-commerce schema defined using AML](e-commerce-using-aml.png)

```aml
#
# Identity domain
#

users
  id uuid pk
  slug varchar unique | user identifier in urls
  role user_role(customer, staff, admin)
  name varchar
  avatar url
  email varchar unique
  email_validated timestamp nullable
  phone varchar unique
  phone_validated timestamp nullable
  bio text nullable
  company varchar nullable
  locale locale(en, fr)
  created_at timestamp
  updated_at timestamp
  last_login timestamp

credentials
  provider_id provider(google, facebook, twitter, email) pk
  provider_key varchar pk | user id in provider system
  hasher hash_method(md5, sha1, sha256)
  password_hash varchar
  password_salt varchar
  user_id uuid fk users.id

social_profiles
  user_id uuid fk users.id
  platform social_platform(facebook, twitter, instagram, slack, github)
  platform_user varchar
  created_at timestamp

#
# Catalog domain
#

categories
  id uuid pk
  slug varchar unique | category identifier in urls
  name varchar
  description text
  tags varchar[]
  parent_category uuid fk categories.id
  created_at timestamp
  updated_at timestamp

products
  id uuid pk
  category_id uuid nullable fk categories.id
  title varchar
  picture varchar
  summary text
  description text
  price number | in Euro
  discount_type discount_type(none, percent, amount)
  discount_value number
  tags varchar[]
  created_at timestamp
  updated_at timestamp

reviews
  id uuid pk
  user_id uuid fk users.id
  product_id uuid fk products.id
  rating int index | between 1 and 5
  comment text
  created_at timestamp

#
# Cart domain
#

carts
  id uuid pk
  status cart_status(active, ordered, abandonned)
  created_at timestamp=now
  created_by uuid fk users.id
  updated_at timestamp

cart_items
  cart_id uuid pk fk carts.id
  product_id uuid pk fk products.id
  price number
  quantity int check="quantity > 0" | should be > 0
  created_at timestamp

#
# Order domain
#

orders
  id uuid pk
  user_id uuid fk users.id
  created_at timestamp

order_lines
  id uuid pk
  order_id uuid fk orders.id
  product_id uuid fk products.id | used as reference and for re-order by copy data at order time as they should not change
  price number | in Euro
  quantity int check="quantity > 0" | should be > 0
```

Hope you enjoyed AML, happy hacking on [Azimutt](https://azimutt.app)!
