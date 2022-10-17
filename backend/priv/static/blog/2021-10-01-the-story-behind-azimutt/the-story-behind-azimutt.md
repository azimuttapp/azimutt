---
title: The story behind Azimutt
banner: "{{base_link}}/digital-singularity.jpg"
excerpt: I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened...
category: azimutt story
tags: build in public, data catalog, sql explorer
author: loic
---

Since always, I'm convinced one of the biggest usage of software should be to help users make sense of the huge amount of information we have access to.
Better understanding the world to act smarter, something like:

![digital singularity]({{base_link}}/digital-singularity.jpg)
*Invoke AI to be smarter. Ok, not like this ^^*

In fact, when I look into my past jobs, it was almost always the case:

- *TRF Retail:* help retailers understand what is happening in their store
- *Amundi:* help Ops teams understand and manage all file exchanges
- *Criteo:* help data engineers and analysts schedule timeseries jobs, and understand them!
- *Zeenea:* help companies understand their data stores
- *Doctolib:* help patient choose doctors and manage their health
- *Azimutt:* help developers understanding their database

I have been thinking about how to organize information, manage complexity and think in system since always, and more specifically about understanding the data we work with as developers for 5 years now.
It started at *Criteo* where I launched [DataDoc](https://medium.com/criteo-engineering/datadoc-the-criteo-data-observability-platform-2cd826a9a1af) to help analysts navigate in the 1500+ tables in Hive, focusing on business documentation UX instead of technical data gathering, like most of the data catalogs I knew at this time.
Then I moved to *Zeenea* to do it full time in a startup dedicated to it.
I led the tech team, but we had different vision for the product, so I moved to *Doctolib* and thought I was finally done with this topic. However, as soon as I looked at the database, I thought I would need a tool to navigate through the hundreds of tables we have.
I looked at available tools but none of them was helpful:
- ERDs always display everything, so they are useless when you have more than 50 tables
- data catalogs are mainly about documenting data for governance, not so much about relational databases insights

So, after several weeks of research, I decided to build my own with all the knowledge accumulated from experience and investigations.

*Azimutt* is all about helping developers understand their relational database.
So it doesn't fit well in big data environment where you look at data flow between table. But it's perfect to make sense of the relational database behind an application.
For now, it's just a web app, allowing you to easily navigate in your schema. And this is already huge 🤩 compared to other tool I know.
If you haven't tried it yet, [you should]({{app_link}})! And keep me posted on what you think!
But, more important than the current status after a few months of work, the vision behind *Azimutt* is to empower developers to understand and manage their relational database, at any scale, from a few tables to thousands of them.
And I will not stop until it integrates perfectly in the developers workflow and answer immediately their questions.
I have clear ideas about this (take a look at our [public roadmap]({{roadmap_link}})), to improve and expand, but your contribution is also key, sharing your use cases and giving some feedback. I'm prioritizing user requests so if you want to have an impact on database tools, [here is your time]({{feedback_link}}).

If "understanding better how your database work" is a problem that matter to you, please get in touch, share your use cases and let's discuss limitless possibilities! 
