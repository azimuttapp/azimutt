# AML Support for VS Code 🪄

[![VS Code Marketplace](https://vsmarketplacebadges.dev/version/azimutt.vscode-aml.png)](https://marketplace.visualstudio.com/items?itemName=azimutt.vscode-aml)
[![Star Azimutt on GitHub](https://img.shields.io/github/stars/azimuttapp/azimutt)](https://github.com/azimuttapp/azimutt)
[![Follow @azimuttapp on Twitter](https://img.shields.io/twitter/follow/azimuttapp.svg?style=social)](https://twitter.com/intent/follow?screen_name=azimuttapp)
[![Tweet](https://img.shields.io/twitter/url.svg?url=https%3A%2F%2Fazimutt.app)](https://twitter.com/intent/tweet?url=https%3A%2F%2Fmarketplace.visualstudio.com%2Fitems%3FitemName%3Dazimutt.vscode-aml&via=azimuttapp&text=Design%20database%20schema%20fast%20in%20VS%20Code!&hashtags=database%2Cdiagram%2Cerd%2Csql)

A VS Code extension to design database schemas using [AML](https://azimutt.app/aml), a simple DSL that speed your design by 2x ✨

![AML in VS Code](https://raw.githubusercontent.com/azimuttapp/azimutt/refs/heads/main/extensions/vscode-aml/assets/screenshot.png)

## 🌟 Features

- Syntax highlight, error reporting and suggestions for AML code (`.aml` files)
- Symbol navigation in AML
- convert AML to PostgreSQL, JSON, DOT, Mermaid, Markdown (Command Palette)
- convert SQL and JSON to AML (Command Palette)


## 💡 Usage

1. Create an empty `.aml` file or use `AML: New database schema (ERD)` command
2. Write your schema using AML, check [documentation](https://azimutt.app/docs/aml) is needed

Here is how AML looks like:

```aml
users
  id uuid pk
  name varchar index
  email varchar unique
  role user_role(admin, guest)=guest

posts | store all posts
  id uuid pk
  title varchar
  content text | allow markdown formatting
  author uuid -> users(id) # inline relation
  created_at timestamp=`now()`
```

## 📋 Roadmap

- diagram preview
- auto-complete (cf [registerCompletionItemProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCompletionItemProvider.html))
- rename (cf [registerRenameProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerRenameProvider.html))
- hover infos (cf [registerHoverProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerHoverProvider.html))
- go-to-definition (cf [registerDefinitionProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerDefinitionProvider.html) and [registerImplementationProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerImplementationProvider.html))
- quick-fixes (cf [registerCodeActionProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCodeActionProvider.html))
- hints with actions (cf [registerCodeLensProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCodeLensProvider.html))
- AML support in Markdown (like [Mermaid](https://marketplace.visualstudio.com/items?itemName=edgebus.markdown-mermaid-container))
- diagram preview for SQL files, then add other languages: Prisma, DBML, [bigER](https://github.com/borkdominik/bigER/wiki/Language)...
- Connect to a database
- Create a [Language Server](https://code.visualstudio.com/api/language-extensions/language-server-extension-guide)


## 🤝 Issues & Contributing

If you have any issue or bug, please [create an issue](https://github.com/azimuttapp/azimutt/issues).

If you want to improve this extension, feel free to reach out or submit a pull request.


## 🛠️ Development

VS Code language extensions are made of several and quite independent part.
For general knowledge, look at the [extension documentation](https://code.visualstudio.com/api) and more specifically the [language extension overview](https://code.visualstudio.com/api/language-extensions/overview).

Here are the different parts of this extension:

- [language-configuration.json](language-configuration.json) for language behavior like brackets, comments and folding (cf [doc](https://code.visualstudio.com/api/language-extensions/language-configuration-guide))
- [syntaxes/aml.tmLanguage.json](syntaxes/aml.tmLanguage.json) for basic syntax highlighting (cf [doc](https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide)) and, later, [Semantic Highlighting](https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide) in [src/web/extension.ts](src/web/extension.ts)
- [snippets.json](snippets.json) for basic language suggestions (cf [extension doc](https://code.visualstudio.com/api/language-extensions/snippet-guide) and [snippet doc](https://code.visualstudio.com/docs/editor/userdefinedsnippets))
- [package.json](package.json) and [src/web/extension.ts](src/web/extension.ts) for defining commands and more advanced behaviors
  - [AmlDocumentSymbolProvider](src/web/extension.ts) for symbol detection
  - [previewAml](src/web/extension.ts) for AML preview

Tips:

- Debug extension via F5 (Run Web Extension)
- Relaunch the extension from the debug toolbar after changing code in `src/web/extension.ts`
- Reload (`Ctrl+R` or `Cmd+R` on Mac) the VS Code window with your extension to load your changes

## 🚀 Publication

[Publish extension](https://code.visualstudio.com/api/working-with-extensions/publishing-extension) on the VS Code marketplace:

- Update `package.json` version and `CHANGELOG.md`
- Package the extension: `vsce package`
- Publish the extension: `vsce publish`

Tips:

- Install vsce with `npm install -g @vscode/vsce`
- Get Personal Access Token from [azimutt](https://dev.azure.com/azimutt)
- Manage extension from the [marketplace](https://marketplace.visualstudio.com/manage/publishers/azimutt)
