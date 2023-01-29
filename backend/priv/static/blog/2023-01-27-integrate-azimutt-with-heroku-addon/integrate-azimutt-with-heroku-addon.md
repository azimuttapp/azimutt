---
title: Got a PostgreSQL database on Heroku? Try Azimutt Add-on!
banner: "{{base_link}}/azimutt-heroku.png"
excerpt: Azimutt has now a full integration with Heroku! Let's see how you can easily integrate Azimutt with your PostgreSQL database on Heroku. It's a bliss ✨
category: azimutt
tags: azimutt, feature
author: loic
---

Sometimes the hardest part of a product is how to integrate it with other tools or current user workflows.
With this Heroku integration we are making Azimutt super easily accessible for all Heroku users 🎉

If you use other hosting providers which support addons, let us know, so we could have a look to make your life much easier.
Same for other integrations like IDE or other tools.
We have them in mind, and they will come, but we prioritize according to user needs 😉

Back to [Heroku](https://www.heroku.com), you will be able to find **Azimutt** in the **Data Store Utilities** section:

![Azimutt listed on Heroku]({{base_link}}/azimutt-listed-on-heroku.png)

But for now the [Azimutt Add-on](https://elements.heroku.com/addons/azimutt) is still in *Alpha* stage, this means two things:

- You won't see it, we have to add your email in Alpha users to allow you to install it
- As Alpha user we offer you the Azimutt pro plan, **for free** 🥳

So it's your chance to seamlessly explore your database without limit, just [email us](mailto:{{azimutt_email}}).

Once added to Alpha users, you will be able to install Azimutt add-on through the Heroku CLI:

```bash
heroku addons:create azimutt --app <your_app_name>
```

And... Tada:

![Azimutt installed on Heroku]({{base_link}}/azimutt-installed-on-heroku.png)

**You have it in your application!** Just click to access it ➡️

The first time you will have to configure it with your database url, allowing Azimutt to fetch your schema so you can explore it:

![Configuring Azimutt integration with Heroku]({{base_link}}/azimutt-heroku.png)

Once it's done, your database schema and documentation is only one click away from your Heroku dashboard, literally. **Amazing!**

![Gospeak database schema on Azimutt]({{base_link}}/gospeak-on-azimutt.png)

We hope this integration will ease your use of PostgreSQL as well as Azimutt.
Try it and tell us what you think.
As it's Alpha stage, it's very easy to improve ^^

Cheers!
