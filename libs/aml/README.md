<p align="center">
    <a href="https://azimutt.app/aml" target="_blank" rel="noopener">
        <picture>
          <source media="(prefers-color-scheme: dark)" srcset="docs/assets/logo-white.png">
          <source media="(prefers-color-scheme: light)" srcset="docs/assets/logo.png">
          <img alt="Azimutt logo" src="docs/assets/logo.png" width="500">
        </picture>
    </a>
</p>

<p align="center">
  <a href="https://azimutt.app/aml" target="_blank" rel="noopener">Home page</a> •
  <a href="./docs/README.md" target="_blank" rel="noopener">Documentation</a> •
  <a href="https://www.npmjs.com/package/@azimutt/aml" target="_blank" rel="noopener">npm package</a>
</p>

**AML** (Azimutt Markup Language) is the **easiest language to design databases**.  
Made to be fast to learn and write.


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


## How to use it

- In [Azimutt designer](https://azimutt.app/create?aml): design your database schema with AML
- In [Dialect converters](https://azimutt.app/converters/aml): convert AML to other dialects such as SQL, JSON, Markdown...
- As a code library (see API below)


## API

This package has a very simple API:

```typescript
function parseAml(content: string): ParserResult<Database> { /* ... */ }
function generateAml(database: Database): string { /* ... */ }
```

You can look at the [Database](../models/src/database.ts) definition, it's how Azimutt model any database schema (offers [zod](https://zod.dev) validations and TypeScript types).

[ParserResult](../models/src/parserResult.ts) is just a class with a `result` and `errors` fields.

Here is a sample usage:

```typescript
const aml = 'users\  id int pk\n  name varchar\n'
const parsed = parseAml(aml)
if (parsed.errors) {
    parsed.errors.forEach(e => console.log('paring error', e.message))
}
if (parsed.result) {
    console.log('database', parsed.result)
    const generated: string = generateAml(parsed.result)
    console.log('generated', generated)
}
```

You can have both, a `result` and some `errors` as there is syntax recovery and some errors are warnings (see `level` field).

This package also offer a few more features:

```typescript
function generateMermaid(database: Database) {} // generate a Mermaid erDiagram
function generateMarkdown(database: Database) {} // generate markdown documentation
function generateJsonDatabase(database: Database): string {} // generate nice JSON (similar to `JSON.stringify(db, null, 2), but more compact)
function parseJsonDatabase(content: string): ParserResult<Database> {} // parse and validate JSON (`zod.safeParse()` adapted to Azimutt APIs)
const schemaJsonDatabase: JSONSchema = {} // the JSON Schema object for the Database type
```

The last useful thing is the [Monaco Editor helpers](src/extensions/monaco.ts):

```typescript
const monaco = {language, completion, codeAction, codeLens, createMarker}
```

You can set up [Monaco Editor](https://microsoft.github.io/monaco-editor) to be a powerful IDE for AML:

```typescript
monaco.languages.register({id: 'aml'})
monaco.languages.setMonarchTokensProvider('aml', aml.monaco.language()) // syntax highlighting
monaco.languages.registerCompletionItemProvider('aml', aml.monaco.completion()) // auto-complete
monaco.languages.registerCodeActionProvider('aml', aml.monaco.codeAction()) // quick-fixes
monaco.languages.registerCodeLensProvider('aml', aml.monaco.codeLens()) // hints with actions

const model = monaco.editor.createModel('users\n  id int pk\n  name varchar index\n', 'aml')
var editor = monaco.editor.create(document.getElementById('aml-editor'), {
  model,
  theme: 'vs-light',
  minimap: {enabled: false},
  automaticLayout: true,
  scrollBeyondLastLine: true,
})
editor.onDidChangeModelContent(e => {
  const parsed = parseAml(editor.getValue())
  monaco.editor.setModelMarkers(model, 'owner', (parsed.errors || []).map(e => aml.monaco.createMarker(e, model, editor)))
  const db = parsed.result // <= here is your Database object (or undefined ^^)
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
