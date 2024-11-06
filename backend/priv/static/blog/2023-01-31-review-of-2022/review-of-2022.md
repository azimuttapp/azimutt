---
title: Review of 2022, plans for 2023
banner: "{{base_link}}/2023-new-year.jpg"
excerpt: 2022 has been quite a year for Azimutt, we went from a basic tool to a full-fledged product, ready to be used by large companies, like Doctolib! Here's what happened, and what to expect next...
category: azimutt
author: loic
---

Last day of January, still time for a 2022 wrap up and wish you a Happy New Year 🍾

2022 was a **huge year for Azimutt** with our motivation always high to push it every week. And we expect 2023 to be the same. In 2022, we went from a simple MVP with just enough features to be useful, to a usable product covering several complementary use cases such as [design](/use-cases/design), [explore](/use-cases/explore), [document](/use-cases/document) and even [analyze](/use-cases/analyze) your database.

![Happy New Year 2023]({{base_link}}/2023-new-year.jpg)

From the UI evolution, Azimutt is now much more polished, moving from [Bootstrap](https://getbootstrap.com) to [Tailwind](https://tailwindcss.com), but everything was already there in terms of spirit:

![New home]({{base_link}}/2022-2023-home.png)
*Azimutt home page*

![Improved import]({{base_link}}/2022-2023-import.png)
*Importing your database schema in Azimutt*

We greatly improved the SQL parsing and also added several other ways to import: from a database connection or even JSON you can build from any source.
For example, you could import your couchbase schema with a simple script [listing collections](https://docs.couchbase.com/server/current/rest-api/listing-scopes-and-collections.html) and [inferring their structure](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/infer.html). We also added some sample projects to experiment Azimutt even if you don't have your schema ready.

We also added import/export for the whole Azimutt project, so you can save it, for example in your git repository to have it versioned.

![Improved layout]({{base_link}}/2022-2023-layout.png)
*Database layout from selected tables*

The diagram has also improved a lot, with logical types (much shorter than real ones) and a default limitation of 15 columns, sorted by importance. 

But of course, what changed most was Azimutt capabilities and especially two, opening use cases very complementary to database exploration.

The first is of course documentation, you can add markdown notes to any table and column, and also some [markdown memos](./document-your-database-with-memos) in layouts, creating a very visual documentation.

The other one is designing your database, from scratch or as evolution for a new feature. It's done with [Azimutt Markup Language](./aml-a-language-to-define-your-database-schema), the most intuitive language to define your database structure 😄

On top of these new capabilities we introduced a server to remotely [store your projects](./azimutt-v2), essential to share them with your team, and stop working alone only. Remote projects can be embedded anywhere, they can be a nice addition to other kind of documentation. We also introduced paid plans, a starting point to make Azimutt sustainable on the long term.

## What's next?

In 2022, we moved from an MVP to a full product, in 2023 we plan to go from a confidential open source project to a well known one. That would be a huge challenge for two developers avid of features ^^

That would mean more integrations with other tools to streamline your workflow. We already started with a [Heroku Add-on](./integrate-azimutt-with-heroku-addon), and we plan to do much more, such as IntelliJ IDEA and Visual Studio Code plugins to easily load SQL files or use your SQL connections, but also a desktop app to better handle your local files and database connection, reaching to your local database and keeping your project in sync.

It would also mean **better onboarding, documentation and UX**, as well as more discussions with users to improve what matter the most to them.

On the feature side, the two big ones we plan are the **real time collaboration**, allowing you to work with several people at the same time.
And a full-featured **data explorer**. For now Azimutt focuses mostly on database schema but data exploration would be a great addition to it, especially with a bit of AI...

Of course, yearly plans often changes, and we [trust you to have a great impact on them]({{issues_link}}), focusing one what matter the most for users, and keeping plans as they are: ideas of the future, that give a direction but don't enforce it over field reality.

And now, let's go back to coding 🧑‍💻

![Coding]({{base_link}}/coding.jpg)
