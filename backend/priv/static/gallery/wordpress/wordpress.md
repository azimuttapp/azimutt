---
icon: pencil
color: indigo
name: WordPress
website: https://wordpress.org
banner: "{{base_link}}/banner.png"
excerpt: Of course you know WordPress. It's the most popular CMS to build blogs and much more. But did you already have a look at its database? Don't you think it would be cool to understand how those millions of blogs are stored?
tables: 12
project-url: /elm/samples/wordpress.azimutt.json
published: 2022-10-25
---

The funny thing about WordPress database schema is: it doesn't have any foreign key. Relations and joins are of course possible, but without any foreign keys. Which is quite unfortunate for an Entity Relationship Diagram that builds relations from foreign keys ^^

Luckily Azimutt can extend your database schema using its dedicated language: [AML](/blog/aml-a-language-to-define-your-database-schema) (Azimutt Markup Language). You can, in other things, add the relations which don't have foreign keys. We did this to avoid cumbersome UI with many inputs and clicks. Instead, you have a very simple language you write in a single input, at your own typing speed. Here is an example of a table defined in AML:

```aml
users
  id uuid pk
  group_id fk groups.id
  email varchar unique
  created timestamp=now()
```

Of course, the [full AML documentation](https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md) is available.

But, back to the WordPress database... With no foreign key, the database integrity rely only on the code, not on usual database mechanism. I can see two reason for this. The first one is for flexibility. They maybe accept the tradeoff to have fewer data quality but also fewer errors. With all their plugin ecosystem it can be a thing. The other one can be for performance. Of course, checking the consistency on each insert or update can be costly. But clearly, this is the first time I see this. If you have other ideas, please [let me know]({{azimutt_twitter}}).

Another strange thing is, they prefix column names with the table name. For example in the `posts` table, they have `post_name`, `post_status` and `post_author`. Same in `comments` with `comment_date` and `comment_author`. Not sure why...

The interesting thing is their **meta pattern**. It allows them to dynamically store additional properties without updating the schema. For example, the `posts` table has an associated `postmeta` table which has a link to a post and two important columns: `meta_key` and `meta_value`. With this, you can store any key/value you want for any post, without changing the schema. If you have to implement dynamic fields it can be an option. Another one would be to have a JSON column. Each one has its own tradeoffs.
