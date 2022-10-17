---
title: "[changelog] Cloud Nord, visual roadmap and unreleased work ^^"
banner: "{{base_link}}/cloud-nord.jpg"
excerpt: The big launch teased last month still needs a bit of polish, but we can reveal more about it... You will be the first ones to discover and maybe use it! Hope it will please you <3
category: azimutt
tags: changelog, azimutt
author: loic
---

I know some of you can't wait to see this, and we were hard at work the whole month, but we still need a bit of polish before releasing the **project sharing**. It's a game changing feature for you, as you will be able to work as a team on your database schema but also for us as it was quite challenging to keep our strong data privacy with this. We can't wait to hear your feedback on it, so we can continue to improve 🚀

![Azimutt presented at Cloud Nord]({{base_link}}/cloud-nord.jpg)

- [Project sharing](#project-sharing)
- [Azimutt mind map](#azimutt-mind-map)
- [PostgreSQL internals](#postgresql-internals)
- [Cloud Nord](#cloud-nord)
- [Popover/Tooltip z-index](#popover-tooltip-z-index)

## Project sharing

[Azimutt]({{app_link}}) is a tool to explore and understand your database schema. This information can be sensitive, and thus we decided to make it privacy first. Everything happens on your browser: from loading the SQL, exploring it and saving the project in the local storage. You can see it as a local app delivered through your browser.

This is awesome, but also has some limitations. The biggest one is when it comes to collaboration, you have no way to collaborate on a single project and build a permanent diagram and documentation for your company. Not anymore:

![Save Azimutt project]({{base_link}}/save-project.png)

You can now create an account and save your project. You can keep it **local**, like now, and only metadata will be stored in Azimutt to manage project versions and migrations when needed. But you can also choose **remote** to upload it to Azimutt and then share it with other people and collaborate on a single reference.

## Azimutt mind map

When preparing the talk for [Cloud Nord](#cloud-nord) we took a step back and noticed that Azimutt had grown a lot during this first year. It's not just an exploration tool. It's becoming a full-featured tool to understand your database with **exploration**, **design**, **documentation** and **analysis**. For example database design capabilities were [introduced in June](./changelog-2022-06), just in time for the Sunny Tech conference.

So we made this mind map to make it clearer, with existing features but also planned ones, so you can see what is coming:

[![Azimutt mind map]({{base_link}}/azimutt-mind-map.png)](https://mm.tt/map/2434161843?t=N2yWZj1pc1)

As you can see, there is a lot of planned features and with the continuous improvement of the existing ones we can't commit on a date for each one but the project sharing is just around the corner and the probable next ones are database stats and markdown documentation with sticky notes (from very different areas ^^).

We are also counting on you to help us prioritize the most impactful ones or suggest new ones! Come and discuss in our [GitHub issues]({{issues_link}}).

## PostgreSQL internals

In July, we added the ability to [import your database schema using your database connection](./changelog-2022-07) instead of just your exported schema. This was a great help for less technical people as they just need to provide database credentials. But this was also very interesting for us as we had to investigate PostgreSQL internals.

We finally took the time to write a complete article about our process and findings [exploring PostgreSQL internals](./explore-postgresql-internals). Not only we dived into `pg_catalog` and `information_schema` but we also took the opportunity to provide them as a [sample Azimutt project](/new?sample=postgresql) with full documentation, so you can explore and understand much more easily 🎁

## Cloud Nord

This is the second time we were selected to talk about Azimutt at a French conference. The first one was [Sunny Tech](./changelog-2022-06#sunny-tech) and it was so great to discuss in person with so many of you! This time it was at [Cloud Nord](https://www.cloudnord.fr): 

![Azimutt talk at Cloud Nord]({{base_link}}/cloud-nord-2.jpg)

Making such presentations is a great way to have direct feedback from the audience. It also allows us to take a step back and notice progress, either in terms of features, users but also maturity of the solution. The talk was much clearer this second time 🎉

![Azimutt talk at Cloud Nord]({{base_link}}/cloud-nord-3.jpg)

## Popover/Tooltip z-index

This one can be quite insignifiant regarding the other news here, but it's probably the one that will change the most your use of Azimutt ^^ Since the
beginning we had this CSS where popups didn't show on top of everything for tables. They stayed at the current table z-index despite having a much higher z-index.

This was due to a [stacking context](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Positioning/Understanding_z_index/The_stacking_context) created by a z-index in the whole diagram.

This thing is quite tricky so if you have trouble with z-index, just check the link above and I hope you can fix them. At least, that's what worked for Azimutt and I learnt about them!

## See you next month

That's all for this month. Thanks for reading until here. I can't wait to release our project sharing feature and get your feedback.

Cheers!
