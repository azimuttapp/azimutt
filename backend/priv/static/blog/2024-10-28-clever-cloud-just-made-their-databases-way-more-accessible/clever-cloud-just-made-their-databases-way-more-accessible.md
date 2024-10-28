---
title: Clever Cloud just made their databases way more accessible
banner: "{{base_link}}/banner.jpg"
excerpt: You guessed it, Clever Cloud is partnering with Azimutt to allow their customers to speed up their database investigations and better understand and manage their databases.
category: azimutt
tags: [partnership]
author: loic
---

Here we are, [Clever Cloud](https://www.clever-cloud.com), the famous French hosting provider who is making deploying apps easy for developers, just released the *Azimutt addon*, allowing their customers to seamlessly use Azimutt within their platform 🚀

![Azimutt addon on Clever Cloud]({{base_link}}/banner.jpg)

If you are here, you probably already know Azimutt and how it makes database way easier to explore and understand.
We have always been in the hunt of the best features to help you in this task such as [multi-layout](/docs/layouts), [find path](/docs/find-path) and even [cross-database exploration](/docs/sources).
Today we make a big step in this direction for the Clever Cloud customers with this partnership.
It's important as it acknowledges Azimutt usefulness when working with real world databases: often large and messy 😅

This brand-new integration will streamline your workflow by making everything accessible from the same interface and with your existing accounts and billing process 🪄

![Azimutt addon on Clever Cloud]({{base_link}}/clever-cloud-addon-azimutt.jpg)


## Easy setup

Azimutt addon is available on Clever Cloud like any other addon. To access it, click "Create" from your dashboard and then "an add-on":

![Create a Clever Cloud Addon]({{base_link}}/clever-cloud-create-addon.jpg)

Then, choose Azimutt:

![Create Azimutt addon on Clever Cloud]({{base_link}}/clever-cloud-create-addon-azimutt.jpg)

After, you will have a few more steps like:

- choosing the plan. If you just want to try it out, **go with the free one**. If you need more, you will have the same plans as Azimutt's, see our [pricing page](/pricing) for more details.
- you don't need to choose and link a Clever Cloud application, Azimutt will connect directly to your database, in fact, any database ^^

The final step is get your database url, allowing Azimutt to extract your database schema:

![Connect Azimutt to your database]({{base_link}}/clever-cloud-create-addon-azimutt-url.jpg)

The whole list of supported databases is [available here](/connectors), we currently support all the mainstream SQL databases such as PostgreSQL, MySQL, MariaDB, SQL Server and Oracle.
But also some document databases like MongoDB and Couchbase and some others.
If yours is not on the list, [let us know](/connectors/new), it's quite easy to implement new connectors.

If you have any comment or suggestion about this integration, please tell us on the [Clever Cloud community space](https://github.com/CleverCloud/Community/discussions/45).


## Safety first!

If you are worried to give your database url to Azimutt, this is a great reaction. But in fact, you are not giving it^^

The URL you give is kept on your browser and only sent to a [Gateway](/docs/gateway) for connecting to your database.
This Gateway is [Open Source](https://github.com/azimuttapp/azimutt/tree/main/gateway) and hosted by Clever Cloud. So if you trust them to host your database, you can trust them to connect to it 😉  
You can also start the Gateway locally, using npm: `npx azimutt@latest gateway` so everything stays on your machine, and you can even reach your local databases 🤘

Handling customer databases is a critical responsibility. And we both, Clever Cloud and Azimutt, take it very seriously.
In fact, Azimutt was even built with this in mind from day one as it was a prerequisite to be used at Doctolib (where the project started), and that's what lead us to our [privacy first architecture](/docs/data-privacy).


## Still here?

Now it's time to [give it a try](https://console.clever-cloud.com), GO! 💪

No matter who you are, if you need to understand better your database, Azimutt will be your best mate:

- *Developers*: have a visual overview of your data model, see and follow relations to it, and even draft changes for new features (thanks to [AML](https://azimutt.app/aml))
- *Product Managers*: skip requests to your dev team to know what is available or possible, look at it on your own and improve your product understanding
- *Data analysts*: explore all your data sources at once in a visual way, but also design and iterate on your data mart (new tables or architecture)
- *Support*: bug investigation with Azimutt row-exploration is just another level, seriously looks like cheat code ^^

If you want to know more about what Azimutt can do for you, we made a launch Stream with [Horacio](https://x.com/LostInBrittany).
We explained why we made this partnership, how to set it up and did a short demo, showcasing Azimutt strength on cross-database exploration:

<iframe width="720" height="405" src="https://www.youtube-nocookie.com/embed/yVGz6yBeFn0?start=203&rel=0" title="Explorez vos bases de données en un clin d'œil avec Azimutt !" frameborder="0" allowfullscreen></iframe>

> When I tested Azimutt, I was amazed at how easy it was to connect to any database and be able to navigate through it.

-- *Horacio*

We hope Azimutt will help you. BTW it's fully [Open Source](https://github.com/azimuttapp/azimutt), you can see how it works and even contribute if you need improvements for your use cases.  
And while you are at it, give us a star, it's the main *Open Source currency* 😊

Cheers!
