---
title: Exploring document databases with Azimutt nested columns
banner: "{{base_link}}/json.jpg"
excerpt: Azimutt is known for exploring relational databases. But today, it got a huge upgrade, making document databases such as MongoDB and Couchbase easily explorable too. Let's dive in.
category: azimutt
tags: azimutt
author: loic
---

Today is a great day for Azimutt. For years (2, actually ^^) it was built to explore relational databases using their explicit schema. Yet, many other databases exists, often called NoSQL, and they also could benefit a lot from better exploration tools.

Today, we bring **document databases** such as [MongoDB](https://www.mongodb.com) and [Couchbase](https://www.couchbase.com) as officially supported in Azimutt, as well as any JSON document one 🎉

![JSON Document]({{base_link}}/json.jpg)

As they don't have any explicit schema, so we fetch a sample from their collections and infer a schema from it. This being done, it's very easy to replicate this with any other database using JSON based documents, or with JSON columns in relational databases, or even with any JSON object you may have in a file. Just tell us your needs, if they are not covered yet, and we could easily adapt. Or even you can adapt it directly 😉

This schema export is built in a [NodeJS CLI](https://www.npmjs.com/package/azimutt), si if you have `npm` installed on your machine you can try it right away. For example: `npx azimutt export mongodb "mongodb://user:password@md7h4xp.mongodb.net"` will export all the databases and collections from your MongoDB instance.

We built this CLI in a very modular way, so you could adapt it from its [source code](https://github.com/azimuttapp/azimutt/tree/main/cli) to inject any custom business logic, for example to define relations based on naming, add some documentation from an external source or even filter/transform schemas 🤘

Here is what it looks like using MongoDB sample data:

![MongoDB sample schema logs]({{base_link}}/cli-logs.jpg)

The second thing we are adding to Azimutt is **nested columns**. Relational databases have very flat schemas, but not document databases. In order to have a very good support of document database schemas we introduced nested columns. You can toggle them (visible or not), at several level, create relations from/to nested columns and also show/hide/sort them individually like normal ones.

Here is how it looks like:

![MongoDB schema in Azimutt]({{base_link}}/mongodb-in-azimutt.png)
*MongoDB sample data*

![Couchbase schema in Azimutt]({{base_link}}/couchbase-in-azimutt.png)
*Couchbase sample data*

Ok, relations in these schema doesn't make a lot of sense, they were just to try, but I'm sure you will have a great use of them.

We wanted to do that for a long time but had a lot of other things to do. We finally prioritized it thanks to a few customer requests 🎉

If you need any improvement to Azimutt making your life easier, from **little fancy UX changes** to **huge ones**, we are really eager to hear you to make Azimutt the best tool to explore and understand your database.

Cheers!  
Azimutt team
