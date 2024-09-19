<p align="center">
    <a href="https://azimutt.app/aml" target="_blank" rel="noopener">
        <picture>
          <source media="(prefers-color-scheme: dark)" srcset="docs/logo-white.png">
          <source media="(prefers-color-scheme: light)" srcset="docs/logo.png">
          <img alt="Azimutt logo" src="docs/logo.png" width="500">
        </picture>
    </a>
</p>

<p align="center">
  <a href="https://azimutt.app/aml" target="_blank" rel="noopener">Home page</a> •
  <a href="./docs/README.md" target="_blank" rel="noopener">Documentation</a> •
  <a href="https://www.npmjs.com/package/@azimutt/aml" target="_blank" rel="noopener">npm package</a>
</p>

**AML** (Azimutt Markup Language) is the **easiest language to design databases**.  
It's made to be fast to learn and write, with very few keywords or special characters.


## Why AML?

- **Structured text** is WAY better than GUI: portable, copy/paste, find/replace, versioning, column edition...
- It's **simpler, faster to write and less error-prone than SQL** or other database schema DSLs
- **Made for humans**: readable, flexible, can hold [custom properties](./docs/properties.md)
- **Database agnostic**: hold concepts, not specific syntax, can be [converted to other dialects](https://azimutt.app/converters/aml)
- **Free** as 🕊️ but also 🍺

In short, it's perfect for fast prototyping and brainstorming. To know more, have a look at the [AML documentation](./docs/README.md).


## Example

```aml
users
  id uuid pk
  name varchar
  email varchar index
  role user_role(admin, guest)=guest

posts
  id uuid pk
  title varchar
  content text | formatted in markdown
  created_at timestamp=`now()`
  created_by uuid -> users(id) # inline relation
```


## Why AML?

- It is database agnostic, focusing on the essential database structure definition without worrying about the <= line length
- Structured text is WAY better than GUI: portable, copy/paste, find/replace, versioning, column edition...
- It's simpler, faster to write and less error-prone than SQL or other database schema DSLs
- Made for humans: readable, flexible, can hold [custom properties](./docs/properties.md)
- Database agnostic: hold concepts, not specific syntax, can be [converted to other dialects](https://azimutt.app/converters/aml)
- Free 🕊️ 🍺

In short, it's perfect for fast prototyping and brainstorming. To know more, have a look at the [AML documentation](./docs/README.md).


## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-aml-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/aml).


## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
