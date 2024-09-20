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


## API

This package has a quite simple API, in fact, just two functions you will (mostly) care about:

```typescript
function parseAml(content: string): ParserResult<Database> {}
function generateAml(database: Database): string {}
```

You can look at the [Database](../models/src/database.ts) definition, it's how Azimutt is modeling any database schema in JavaScript (and JSON).

The [ParserResult](../models/src/parserResult.ts) is just a class with a `result` and `errors` fields.

You will also have access to other useful functions, for example to work with JSON:

```typescript
function parseJsonDatabase(content: string): ParserResult<Database> {} // it's just a zod.safeParse() adapted to Azimutt APIs
function generateJsonDatabase(database: Database): string {} // it's just a JSON.stringify with "nice" formatting
const schemaJsonDatabase: JSONSchema = {...} // the JSON Schema for the Database type
```

They will allow you to parse/serialize [Database](../models/src/database.ts) from/to JSON (using [zod](https://zod.dev) types), and provides you the JSON schema object for the Database.

The last useful thing is the [Monaco Editor helpers](src/extensions/monaco.ts):

```typescript
const monaco = {language, completion, codeAction, codeLens, createMarker}
```

You can set up your Monaco Editor with AML like this:

```typescript
monaco.languages.register({id: 'aml'})
monaco.languages.setMonarchTokensProvider('aml', aml.monaco.language()) // syntax highlighting
monaco.languages.registerCompletionItemProvider('aml', aml.monaco.completion()) // auto-complete
monaco.languages.registerCodeActionProvider('aml', aml.monaco.codeAction()) // quick-fixes
monaco.languages.registerCodeLensProvider('aml', aml.monaco.codeLens()) // hints with actions

const model = monaco.editor.createModel('', 'aml')
var editor = monaco.editor.create(document.getElementById('aml-editor'), {
  theme: 'vs-light',
  model,
  minimap: {enabled: false},
  automaticLayout: true,
  scrollBeyondLastLine: false,
})
editor.onDidChangeModelContent(e => {
  const parsed = parseAml(editor.getValue())
  monaco.editor.setModelMarkers(model, 'owner', (parsed.errors || []).map(e => aml.monaco.createMarker(e, model, editor)))
  const db = parsed.result // <= here is your Database (or undefined ^^)
})
```

You can also use the Database JSON Schema for improved JSON editing experience in Monaco.
As an example you can try the [AML to JSON converter](https://azimutt.app/converters/aml/to/json) or the [JSON to AML converter](https://azimutt.app/converters/json/to/aml)


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
