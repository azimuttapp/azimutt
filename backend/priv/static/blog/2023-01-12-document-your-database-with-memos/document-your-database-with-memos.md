---
title: Document your database schema using rich text memos
banner: "{{base_link}}/azimutt-memos.png"
excerpt: Have you ever dreamed about embellishing your database schema with some doc? Text, images, headings, links, code, table and more? It's now a core feature of Azimutt, here's more...
category: azimutt
tags: azimutt, feature
author: loic
---

Hi again 👋, it has been a long time since the [last post](./azimutt-v2)...

We were quite busy building awesome features, and now we are happy to release them. Expect more posts about recent improvements which **drastically improved Azimutt**.

Let's start today by telling you about **memos**:

![Document your database schema with memos]({{base_link}}/azimutt-memos.png)

The database documentation part is always a pain, and we hope Azimutt could help with several features. Since the beginning you could see **comments on tables and columns** directly inside Azimutt diagrams and create **layouts** to showcase any relevant tables and columns for your goal. It can be a feature, a team scope or anything else.

Then we added **notes** on tables and columns. They are very similar to SQL comments but just stored in Azimutt project instead of your database. Much easier to update, less accessible for other tools.

And now we are introducing **memos** 🎉

They are small pieces of content you can freely place anywhere in your layout. And as they are rendered using **markdown**, you can really leverage them for rich layout documentation. For example, you could:

- link to other documentation or website
- add images for branding, highlighting some parts or even showing some emotions
- add SQL queries and sample result
- or any other creative idea or custom need you may have

To create a memo it's really simple, just double click anywhere in your diagram background (or right click, also works 😉).

The first screenshot is a good example of what you can achieve with many Azimutt features, memos but not only and can be seen as overloaded but here is a more realistic documentation example, showcasing the [Gospeak](https://gospeak.io) database schema:

![Documenting Gospeak database]({{base_link}}/azimutt-memos-gospeak.png)

I personally love the new capabilities offered by memos and I feel schema can be much easier to understand with a bit of text floating around. [Tell us]({{azimutt_twitter}}) how you feel about them and don't hesitate to share your realizations or [improvements you can see]({{issues_link}}), even minor ones like small UX trick 😉

If you want to play a bit with this new feature, here is the previous layout [embedded](./embed-your-database-diagram-anywhere), so you can move things and create new memos (but can't save obviously ^^):

<iframe width="100%" height="450px" src="https://azimutt.app/embed?project-id=9b317ef6-ee82-49ca-ae3b-63bf8110e13f&layout=introduction&mode=layout&token=151c37dd-6a92-4412-a57e-9f1b8563ae99" title="Embedded Azimutt diagram" frameborder="0" allowtransparency="true" allowfullscreen="true" scrolling="no" style="box-shadow: 0 2px 8px 0 rgba(63,69,81,0.16); border-radius:5px;"></iframe>

For now, this feature is limited to 1 memo per layout on free plan and, of course, truly unlimited for pro ones. We are just starting out so really don't hesitate to [reach at us](mailto:{{azimutt_email}}) if you think it's too limited or the pro plan is not fine for you. We can easily find arrangements to make you succeed using Azimutt 🚀

Make a great use of these new shiny memos, but don't abuse them ^^

See you soon on 🧭
