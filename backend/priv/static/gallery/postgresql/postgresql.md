---
icon: circle-stack
color: indigo
name: PostgreSQL
website: https://www.postgresql.org
banner: "{{base_link}}/banner.png"
excerpt: If you ever need to explore PostgreSQL internals to extract metadata and automate things, this example is a must-have. It comes with all the tables from the schema storing database structure but also with build-in documentation and relations.
tables: 63
project-url: /elm/samples/postgresql.azimutt.json
published: 2022-10-25
---

If you are interested into PostgreSQL internals and more specifically how it stores its internal schema, using `information_schema` and `pg_catalog` schemas, I can't recommend you enough my blog post about [my exploration to extract the database schema](/blog/explore-postgresql-internals).

The first thing to know is that `information_schema` is defined in the SQL standard so all databases implement it. The queries you make using it should be portable between different databases. But the catch is: it's often not enough to get very specific information. So in PostgreSQL there is the `pg_catalog` schema where PostgreSQL store all its internal structure. This is very specific to PostgreSQL, but you can find anything. In fact, the `information_schema` is mostly SQL views on top of `pg_catalog` ^^

If you want precise links to the documentation, here they are, for the [information_schema](https://www.postgresql.org/docs/current/information-schema.html) and the [pg_catalog](https://www.postgresql.org/docs/current/catalogs.html). But you will need plenty of tabs open to track your data across the tables.

I integrated all the documentation inside SQL comments for this example, so it should be much easier to navigate between tables and columns in Azimutt than in the documentation. Ok, the current tooltips are not that great, I will improve them but if I didn't do it already, send me a message, so I can prioritize it more (I follow a lot the user requests for prioritization as I have way too much to do ^^).
