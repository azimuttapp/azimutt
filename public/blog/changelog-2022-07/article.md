---
title: [changelog] Get schema using database connection, JSON source and more
excerpt: July: holidays and big change! You can now import your schema in Azimutt using a database connection, no need to export it yourself anymore. This is THE big change but not the only nice improvement, of the month.
category: azimutt
tags: changelog, azimutt
author: loic
published: 2022-08-02
---

Hi again! Welcome to this second edition of Azimutt's changelog 🎉

This month big change is on project creation. You now have several new ways of creating an Azimutt project as well as managing your sources: database connection, JSON or even empty ones will surely help you!

![Extracting schema from database]({{base_link}}/database-extract.jpeg)

- [Database & JSON sources](#database-json-sources)
- [Empty project](#empty-project)
- [Improved layout management](#improved-layout-management)
- [Configurable default schema](#configurable-default-schema)
- [Improve SQL parser](#improve-sql-parser)

## Database & JSON sources

If you already used Azimutt, you noticed it is build around sources to import one or more database schema. We started with only SQL sources, parsing your database schema to build our beautiful diagram. Then, [last month](./changelog-2022-06) we added [Azimutt Markup Language](./aml-a-language-to-define-your-database-schema) as available source, allowing you to create or extend your schema with a very simple language. And this month we added two new kind of sources: one from database connection and one from JSON.

The **database connection** enables you to create a source using your database connection url, no schema extraction or parsing error for you anymore! As browsers can't do it directly, we needed to proxy it through our server but *nothing* is stored (you can check the [source code](https://github.com/azimuttapp/server)), and at some point, you will be able to do it locally, using [Azimutt desktop app](https://github.com/azimuttapp/azimutt/issues/91). This source will also enable a huge number of new and incredible features using database access, such as search in data, table/column values and statistics or even run your queries. 

The **JSON source** on the other side will enable much broader use of Azimutt. Instead of being only restricted to SQL or relational databases, you can parse and format anything you want (other databases like graph or document, code classes...) in a model of tables/columns and relations, and then import and explore it in Azimutt. This could unlock original/unexpected use cases 🧙

## Empty project

From the creation wizard, you can now create an empty project (no source). This looks trivially stupid but transforms Azimutt from an exploration tool only to also a schema creation tool, like others ERDs. So thanks to this, and AML, you now have a very flexible tool for everything related to database schema.

## Improved layout management

Layouts are one of the best, and unique, feature of Azimutt. They store tables and columns disposition, allowing you to create several diagrams showing features, use cases or even team scopes. Yet they were a bit hidden and not intuitive to use (had to update them manually). Some users didn't even notice them and created multiple projects to simulate this ^^
They are now more visible: you always see and update a layout, the initial one or the one you created, and they are live updated, no more manual save. So you can create an empty layout, duplicate an existing one or delete one (except the currently used).
Please [tell me]({{azimutt_twitter}}) if it's intuitive enough or how it can still be improved. As it's at the heart of the tool, it's essential to make it as clear and easy as possible to use for anyone, especially new users.

## Configurable default schema

In order to lighten the UI, the default schema is not displayed in the table name. Until now, it was hardcoded to `public` but some database use another one (like `dbo` for Sql Server) or you can even choose to put your tables in a specific schema. So now, this default schema is configurable from project settings and computed on project creation using the most used schema in your source.

## Improve SQL parser

As always, this never ending task is still here ^^
It's better month after month and the test harness is also improving a lot 🚀
If you still find some errors in SQL parsing, please send them, so they can be fixed (within a few hours/days).

## See you next month

Hope you liked these improvements. We have many more to come and work on big changes during this summer, get ready for them!
If you see anything that could help you to use Azimutt or working with your database, [let us know]({{issues_link}}), so we can make it happen 😉

Cheers!
