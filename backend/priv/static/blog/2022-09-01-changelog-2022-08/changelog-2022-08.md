---
title: "[changelog] Type definitions in your diagram, full AML documentation..."
banner: "{{base_link}}/database-exploration.jpg"
excerpt: No rest in August for Azimutt, some nice improvements and tricky bugs finally tackled and released. And also huge preparation work for big launches in September, stay tuned!
category: changelog
author: loic
---

The feature train for Azimutt is still strong, even during summer time!

This month big change was to extract custom type declaration from your schema and display it in Azimutt diagram. This is especially useful for enums, so you can see all possible values for a column without leaving Azimutt!
If you follow us on Twitter ([@azimuttapp]({{azimutt_twitter}})), you know our biggest work is still not released and will bring Azimutt to a completely new level. **Stay tuned!**

![Explore your database schema]({{base_link}}/database-exploration.jpg)

- [Type definitions](#type-definitions)
- [AML documentation](#aml-documentation)
- [Smoother navigation](#smoother-navigation)
- [SQL parser improvements](#sql-parser-improvements)

## Type definitions

Coming from a user request, it's indeed quite useful to see directly in Azimutt the custom type definitions, especially for enums:

![Custom enum values displayed in Azimutt]({{base_link}}/custom-enum.png)

This new information is available from any source:

- parsed from SQL source when you import your database schema
- extracted from database connection source when you provide it
- available in AML source (see documentation just below)
- defined in JSON source to import it from any other system

This should help you even more when exploring your database. Keep rocking!

## AML documentation

AML stands for **Azimutt Markup Language**. It provides a very quick and intuitive language to describe your database schema in plain text:

```aml
users | store every user # AML comment
  id uuid pk
  login varchar(30) unique
  role user_role(guest, member, admin)=guest
  email varchar nullable
  group_id fk groups.id
  created timestamp=now()
```

It's awesome as you don't need to change focus or click anywhere to write everything you have in mind. Your only limit is your typing speed. Obviously, it's used in Azimutt to create or extend your database schema, but until now the only available documentation was the [announcement blog post](./aml-a-language-to-define-your-database-schema). It worked well but with the new addition of the *type definition* we needed to have a better documentation, targeted at learning it.

This is done now, [the AML documentation](https://azimutt.app/docs/aml) is now available and has [several great examples](https://azimutt.app/docs/aml#full-example) 📖


## Smoother navigation

One goal for Azimutt is to offer you a very pleasant experience while exploring your database.

We added contextual menus (right click) for the tables and the whole diagram, and re-worked a bit the one on columns. We also improved keyboard shortcuts so everything is now much more accessible and consistent.
Just try them 😉

We also fixed two annoying bugs: the zoom on cursor and tables little move on click. Your experience should be much smoother now. Why these problems were not fixed earlier? Let's dig a bit as, I think,  it's quite interesting ^^

As we aim for a very pleasant experience and these problems were very annoying, we already tried to fix them several times before, but without any success. What changed and allowed us to finally succeed? **We added types!** Yes, that simple! Let's dig in 👇️

In order to have an easier alignement, tables coordinates are rounded to multiples of 10 to create a (small) grid effect. But sometimes, a computation escaped this rule and created coordinates that were not multiples of 10 (couldn't figure out which one 😥). So when you click on a table, the position is recomputed and aligned on the grid, creating this small, but very annoying, move of the table ([Jérémy Buget](https://twitter.com/jbuget) even mentioned it in [his article](https://jbuget.fr/posts/outils-sql-en-ligne/#visualiser-une-base-de-donn%c3%a9es)).
The *definitive fix* was to create a *type* for grid positions (`Position.Grid`). It has only one creation function that does the grid alignement. This way, using it for table positions, it's guaranteed to be aligned on the grid, no matter what.

The second one, *zooming not exactly on the mouse cursor*, was way trickier. The zoom is made with a `transform: scale(zoom)` having an origin on the top-left of the canvas. So to zoom on a specific point, I have to translate the canvas origin so the desired point stays at the same visual position.
This is where problems start: I have a lot of coordinate systems. First, the cursor and the diagram (gray area) positions in the *browser viewport*, then the canvas position inside the *diagram* (which can have a zoom) and finally, the tables, relations and cursor positions inside the *canvas*. It may sound obvious being said like this (🤞) but finding out everything and doing the conversions from a system to another was quite a tricky thing for me.
In fact, everything had the same type, `Position` with a `left` and `top` attributes. This works well, in theory, but it's not very helpful to keep track of what is what and avoid mistakes. So I decided to create one type for each kind of coordinate which are all incompatibles with the others (as well as needed conversions). So I created: `Positon.Viewport`, `Position.Diagram` and `Position.Canvas`, and function like `viewportToCanvas` and `canvasToViewport` with all the required parameters. 
While adding these types everywhere I noticed I made several mistakes, combining coordinates from different systems. But it worked, sometimes 🤔, when the systems had the same scale (Viewport & Diagram for example). After this long and painful refactoring (had to give new parameters to functions deep inside components sometimes), adding types and fixing (now) obvious mistakes, I could finally see the problem much more clearly 🧐.
I took the correct parameters and figured out I "just" needed to compute the Viewport move of the cursor position during the zoom and subtract it from the origin to make it stay in place. I did that by converting the cursor position from Viewport to Canvas with current zoom and then from Canvas to Viewport with the new zoom. The difference between the initial position and the computed one was the needed origin move. And, ... it worked 🎉🎉🎉

That's one of the numerous times I tell myself I should create much more types than I already do. Especially when several concepts have the same structure (see [primitive obsession](https://refactoring.guru/fr/smells/primitive-obsession) code smell). If you find yourself in a similar situation, try adding very specific types to add guarantees:

> [When you find a bug, does not only commit your fix, but also create a Type, so it can't come back.](https://twitter.com/loicknuchel/status/1564888867563528192)


## SQL parser improvements

As always this month had its number of new edge cases covered for the SQL parser (such as `unlogged tables`) so all users can work well with Azimutt.
It really helps when you report problems, so we can fix them for everyone, and most of the time quite quickly 🚀
So please, if you see something, report it by sending the suggested email or open an [issue on Github]({{issues_link}}).


## See you next month

Can't wait for next month release with all the new features we are working on already and the new opened horizons...
It will be the biggest month for Azimutt and I hope you will be with us for it!

Cheers!
