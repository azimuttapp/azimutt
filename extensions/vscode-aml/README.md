# AML Support for VS Code

[![VS Code Marketplace](https://img.shields.io/vscode-marketplace/v/azimutt.vscode-aml.svg?label=vscode%20marketplace&style=flat-square&color=007ec6)](https://marketplace.visualstudio.com/items?itemName=azimutt.vscode-aml)
[![Star Azimutt on GitHub](https://img.shields.io/github/stars/azimuttapp/azimutt)](https://github.com/azimuttapp/azimutt)
[![Follow @azimuttapp on Twitter](https://img.shields.io/twitter/follow/azimuttapp.svg?style=social)](https://twitter.com/intent/follow?screen_name=azimuttapp)

A VS Code extension to design database schemas with [AML](https://azimutt.app/aml), a simple DSL that speed your design by 2x ✨

![AML in VS Code](https://raw.githubusercontent.com/azimuttapp/azimutt/refs/heads/main/extensions/vscode-aml/assets/screenshot.png)

## Features

- Syntax highlight and suggestions for AML code (`.aml` files)
- Symbol navigation in AML


## Usage

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

## Roadmap

- diagram preview + open in Azimutt
- convert AML to PostgreSQL, JSON, DOT, Mermaid, Markdown (Command Palette)
- convert SQL and JSON to AML (Command Palette)
- Add parsing errors ([createDiagnosticCollection](https://code.visualstudio.com/api/references/vscode-api#languages.createDiagnosticCollection)?)
- auto-complete (cf [registerCompletionItemProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCompletionItemProvider.html))
- rename (cf [registerRenameProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerRenameProvider.html))
- hover infos (cf [registerHoverProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerHoverProvider.html))
- go-to-definition (cf [registerDefinitionProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerDefinitionProvider.html) and [registerImplementationProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerImplementationProvider.html))
- quick-fixes (cf [registerCodeActionProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCodeActionProvider.html))
- hints with actions (cf [registerCodeLensProvider](https://microsoft.github.io/monaco-editor/typedoc/functions/languages.registerCodeLensProvider.html))
- AML support in Markdown
- Connect to a database


## Issues & Contributing

If you have any issue or bug, please [create an issue](https://github.com/azimuttapp/azimutt/issues).

If you want to improve this extension, feel free to reach out or submit a pull request.


## Development

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

## Publication

[Publish your extension](https://code.visualstudio.com/api/working-with-extensions/publishing-extension) on the VS Code extension marketplace.

- Get Personal Access Token from [azimutt](https://dev.azure.com/azimutt)
- Manage extension from the [marketplace](https://marketplace.visualstudio.com/manage/publishers/azimutt)
- package the extension: `vsce package`
- publish the extension: `vsce publish`
- if needed, install vsce: `npm install -g @vscode/vsce`
