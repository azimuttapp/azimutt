---
title: Stop using auto-increment for table primary keys!
banner: "{{base_link}}/fail.jpg"
excerpt: It is quite popular to use integer auto-increments for table primary keys, lots of tutorial and even frameworks do so. But it's a mistake that will bite you, unless you fail before. Here is why and how to fix it, easily.
category: database design
author: loic
---

Are you working with a database? Do you know what is the type of your identifier field? Good chances are it's an auto-incremented integer. Why? Most tutorials I have seen use them, some framework use them as default and, with auto-increment built into databases, it feels natural to many developers.
Behind this usually no-brainer choice, you may have bad times down the road if you are not working on toy projects.

![fail]({{base_link}}/fail.jpg)

> A good design choice at the beginning can save a hundred hours of work down the line

Before explaining what are the problems, let's see why they are still heavily used (in my opinion). First, I think it's from defaults settings and habits. It's a very powerful incentive or sometimes not even an active decision.
But they also have interesting points:

- it's easy to talk about and remember them ("the user 42 has a bad setting"). This is less true with bigger numbers (over 100k) but most tables stay under
- it's very easy to understand them and even a bit satisfying to see the numbers increase over time
- they give some prestige to early users when the service grow: "I'm user 536 on Twitter"
- some developers are happy not using too much storage space for identifiers everywhere (premature optimization anyone?)

If you see other reasons to use them, please [let me know]({{azimutt_twitter}}), so I could add them.

As you saw in the title, I think they are a poor choice and will list the reasons just after. But let's break the suspense right away on the proposed solution to compare them along the way. You probably already know it: [random UUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier).

![better]({{base_link}}/better.jpg)

Now let's dig into why you should prefer UUIDs over sequential numeric identifiers and why they are dangerous:

### Enumeration attack and information leaking

Sequential numbers are of course easily guessable. It's easy for anyone to get the exhaustive list of a resource with such an identifier. So they can extract a lot of data. Even if public, having them as a whole can be very dangerous. And I don't even talk if you have a hole in your authorization system, with guessable identifiers, it can have catastrophic consequences.

With such an identifier generation, anyone also knows which identifiers will be used next, at some point in the future or even just the next one (when you create an entity, you get the current incremented value). This ease a lot possible timing attacks with tricky race condition.

Such identifiers also leak information about the size of your tables but also when a specific item has been created. These might be precious information for an attacker or competitors to exploit.

Random UUIDs on the other hand makes all this impossible and makes vulnerability exploitation much harder.

If security is a big concern for you, you can even keep your identifiers hidden (and non-guessable!) so doing specific joins or filter will be much harder for an attacker. You can do this by using slugs as public identifiers: unique values not used in foreign keys, so you can only access the identified resource.

### Scaling bottleneck

When your system grows you will progressively distribute it to handle the load. Stateless web servers are quite easy. Even database read replica can be setup without too much trouble. But having multiple write database is always very challenging. The sharding can be done per table (define which tables are on which instance) but also using a sharding key (even users are on the first instance and odd ones on the second for example). This last approach is not possible with sequential numbers as you always need a central component to keep track of the sequence value, and most of the time it's the database using the auto-increment feature. For heavy tables this could be very problematic, for example: tracking, audit, history...

On the other hand, as UUIDs can be independently generated anywhere, like in your applicative server, they scale with no problem. The only risk is possible collision but it's [so low it could be safely ignored](https://en.wikipedia.org/wiki/Universally_unique_identifier#Collisions) in most of the case. If you fear collisions, use this [collision calculator](https://zelark.github.io/nano-id-cc) to customize your random id.

### Reach the limit

If you used an integer early on thinking 2^32 is big enough for your table identifiers, a few years later you may find out it's not.
Are you monitoring this? Or will you rush an ugly fix once you have errors pilling up on production?
Moving to a long number will give you much more time but changing a column type will get an exclusive lock on the table and rewrite the data which can be quite long, especially if your table is big, with billions of records (remember, integer is too small for the id). If you can't stop your system for some time, you will definitively not like it!

### Error identification

Enough with security or scaling issues, now let's talk about you, the developer. You may have heard about these little things called bugs. Sadly they are far from rare, even with all the current techniques (types, tests, code review, QA...). Sooner or later you will use a non-identifier integer as identifier, and this time you will see: nothing, absolutely nothing. You have high chances for this specific integer to have a record matching with this identifier, so everything with work fine. Except you are now corrupting user data without knowing it. Your best chance to notice is a user bug report saying they have strange data. But it will be far from easy to reproduce, troubleshoot and identify the root cause. And if you do, you will have so much fun fixing all the corrupted data, if it's even possible (probably since a long time ago).

Instead of that, with UUIDs you will have a failing selection or join as UUIDs are globally unique, not only inside your table but your whole database. Way easier to identify and no data to fix.

This happened to me once in a personal project: I inverted two identifiers in a function causing some strange 404 errors, thanks UUIDs. I had very hard time debugging it as it was in a hard to reproduce flow and since then, whenever I can, I use dedicated types for identifiers in my code, so it can't happen again! I can only encourage you to do the same ;) 

### Side effects

When using database auto-increments, they are a part of your application state. But they are quite hard to control, and you probably forgot about them.

For example, if you don't reset them properly between your tests, you will have inconsistencies depending on their order or even initialization, especially if you have some lazy code. And good luck troubleshooting that!

Also, as it's an internal state of the database, you can't control them, but will probably always get the same ones, with just a few differences in rare cases (due to race condition, test order or lazy instantiation). Best bugs ever ^^

UUIDs instead, will be generated by your test code, either randomly or hardcoded, but it will be quite clear to find what is happening.

Please, take my advice and avoid yourself all this future trouble.

![gift]({{base_link}}/gift.jpg)

I personally experienced each one of the mentioned problems in different situations, so I can assure you, it is very painful to deal with them after the fact. Sometimes difficult to troubleshoot, sometimes hard to fix or even sometimes completely impossible 🤯
That's why I can only encourage you to do this simple choice from the beginning, so you and your co-workers can live your peaceful life of developers ^^

If you are dealing with a large database, have a look at [Azimutt]({{app_link}}). I built it for myself, especially to handle very large databases because I couldn't find any decently useful tool for that. If you do, please [honestly tell me what you think]({{feedback_link}}): it's key for me to build a generally useful tool, not just one for my specific case ;)

Cheers!
Have fun and enjoy!
