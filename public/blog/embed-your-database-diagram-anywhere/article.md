---
title: Embed your database schema anywhere
excerpt: If you ever write some documentation or designed some database evolution, it could be helpful to include a visual diagram to make it more understandable. Learn how to do it with Azimutt and much more, be sure to read until the end.
category: azimutt feature
tags: entity relationship diagram
author: loic
published: 2022-03-21
---

[Azimutt](https://azimutt.app/projects) is already the perfect tool to explore your database schema, I hope you experienced it yourself. You can search, display what you need, follow relations and even use advanced feature like find needed joins between two tables or identify problems in your schema such as missing relations. You may like all this and make great use of it in your own investigations, but, it was only personal research. No way to easily share this with your co-workers or anyone else.

Not anymore! Embed your schema and make it accessible to whom you want:

<iframe width="100%" height="400px" src="https://azimutt.app/embed?project-url=https://raw.githubusercontent.com/azimuttapp/azimutt/main/public/samples/basic.azimutt.json&mode=static" title="Embedded Azimutt diagram" frameborder="0" allowtransparency="true" allowfullscreen="true" scrolling="no" style="box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;"></iframe>

Notice it's **interactive**, you can hover columns and select tables but everything is fixed. When embedding your schema, you can choose which Azimutt feature you want to provide, from none, juste like a picture to everything including project settings and layout navigation (more examples below).

One big challenge here is doing that without compromising your database schema privacy. For that, Azimutt still host nothing, to embed your schema you will have to download it and host it yourself, with the access you want. For example, in a [gist](https://gist.github.com), github/gitlab/bitbucket repository with the required access or anything else that can serve a json file.

But, what about documentation showing a specific part of the schema?
You're right! By default, the embed mode shows the current layout of the project, but you can choose a specific layout to display. For example, here is the [gospeak](https://gospeak.io) project (in samples) shown with the *speaker* layout, and the *move* mode, so you can rearrange the tables if you like:

<iframe width="100%" height="500px" src="https://azimutt.app/embed?project-url=https://raw.githubusercontent.com/azimuttapp/azimutt/main/public/samples/gospeak.azimutt.json&layout=speaker&mode=move" title="Embedded Azimutt diagram" frameborder="0" allowtransparency="true" allowfullscreen="true" scrolling="no" style="box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;"></iframe>

Create the layout you want to highlight your point and embed it. It's that easy!

In fact, you have everything done for you in the sharing modal (accessible with the top right sharing icon): project download, specify project url, layout (optional) and embed mode:

![Azimutt embed setup]({{base_link}}/azimutt-embed.jpg)
*Azimutt embed setup*

You even have a dynamic view of your settings, replacing the big image on the left, so you can experiment what the different modes do:

![Azimutt embed preview]({{base_link}}/azimutt-embed-preview.jpg)
*Azimutt embed preview*

Sharing page with your schema embed or even directly the embed url will largely ease your communication. For example, I created a confluence page at Doctolib with our database schema, so developers could search for it on confluence and see it directly and interactively. Much easier than explaining to everybody that Azimutt exists, he/she can grab the structure.sql, import it, and then create a few layouts. I had an overwhelming feedback doing that 🎉 Maybe you should try it yourself too ^^

All this is great, but working daily with other people and a database schema that is always evolving can be challenging, as the Azimutt project is not, at least not automatically. You don't want to see an outdated diagram, and you don't want to update it every day either...

One solution there, this one is just for you, fellow readers that went until the end of this article. The feature is still hidden, but instead of giving your Azimutt project to the embed url, you can directly give your SQL schema. For that, just replace the `project-url` parameter with a `source-url` parameter pointing at your database schema, and the *full* mode allowing you to [explore it fully](./how-to-explore-your-database-schema-with-azimutt), it can be very convenient:

<iframe width="100%" height="550px" src="https://azimutt.app/embed?source-url=https://raw.githubusercontent.com/azimuttapp/azimutt/main/public/samples/gospeak.sql&mode=full" title="Embedded Azimutt diagram" frameborder="0" allowtransparency="true" allowfullscreen="true" scrolling="no" style="box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;"></iframe>

You now have a fresh project, created from your dynamically parsed schema 🥳

The drawback here is you can't provide predefined settings and layouts. But stay tuned, Azimutt is always improving... And even more if you come, [discuss]({{azimutt_twitter}}) and [provide some feedback]({{feedback_link}}) ❤️
