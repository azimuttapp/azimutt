---
title: The story behind Azimutt
author: Loïc Knuchel
published: 2021-10-01
category: azimutt
tags: 
excerpt: I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened...
---

Since always, I'm convinced one of the biggest usage of software should be to help users make sense of the huge amount of information we have access to.
Better understanding the world to act smarter, something like:

![digital singularity](./{{slug}}/digital-singularity.jpg)
*Invoke AI to be smarter. Ok, not like this ^^*

In fact, when I look into my past jobs, it was almost always the case:

- *TRF Retail*: helping retail manager understand what is happening in their store
- *Amundi*: help SRE teams understand and manage file exchanges
- *Criteo*: help data engineers and analysts schedule timeseries jobs, and understand them!
- *Zeenea*: help companies understand their data stores
- *Doctolib*: help patient choose doctors and manage their health
- *Azimutt*: help developers understanding their database

I have been thinking about how to organize information and manage complexity since always, and more specifically about understanding the data we work with as developers for 5 years now.
It started at *Criteo* where I launched [DataDoc](https://medium.com/criteo-engineering/datadoc-the-criteo-data-observability-platform-2cd826a9a1af) to help analysts navigate in the 1500+ tables in Hive, focusing on business documentation UX instead of technical data gathering, like most of the data catalogs I knew at this time.
Then I moved to *Zeenea* to do it full time in a startup dedicated to it.
Vision and cultural fit didn't work out, so I moved to *Doctolib* and thought I was finally done with this topic, but as soon as I looked at the database, I thought I would need a tool to navigate through the hundreds of tables.
I looked at available ones but nothing was helpful:
- ERDs are useless when you have more than 50 tables, as they display everything
- data catalogs are more about documenting data lakes and data pipelines, not so much about relational databases

So, after several weeks of research, I decided to build my own with all this accumulated knowledge.

*Azimutt* is all about helping developers understanding their relational database.
So it doesn't fit well in big data environment where you look at data flow between table.
For now it's "only" a web app, allowing you to nicely navigate in your schema. And it's already huge 🤩 compared to other tool I know.
If you haven't tried it yet, [you should]({{app_link}})! And keep me posted on what you think!
But, more important than the current status after a few months of work, the vision behind *Azimutt* is to empower developers to understand and manage their relational database, at any scale, from a few tables to thousands of tables.
And I will not stop until it integrates perfectly in the developers workflow and answer immediately their questions.
I have clear ideas about this (take a look at our [public roadmap]({{roadmap_link}})), to improve and expand, but your contribution is also key, sharing your use cases and giving some feedback. I'm prioritizing user requests so if you want to have an impact on database tools, [here is your time]({{feedback_link}}).

If "understanding better how your database work" is a problem that matter to you, please get in touch, share your use cases and let's discuss limitless possibilities! 
