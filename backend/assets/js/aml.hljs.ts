import {HLJSApi, Language} from "highlight.js"

// keep in sync with libs/aml/src/extensions/monaco.ts
const entityRegex = /^[a-zA-Z_][a-zA-Z0-9_#]*/
const attributeNameRegex = /^ +[a-zA-Z_][a-zA-Z0-9_#]*/
const attributeTypeRegex = /\b(uuid|(var|n)?char2?|character( varying)?|(tiny|medium|long|ci)?text|(tiny|small|big)?int(eger)?(\d+)?|numeric|float|double( precision)?|bool(ean)?|timestamp( with(out)? time zone)?|date(time)?|time( with(out)? time zone)?|interval|json|string|number)\b/
const notesRegex = /\|[^#\n]*/
const commentRegex = /#.*/

// see https://highlightjs.readthedocs.io/en/latest/language-guide.html
export function language(hljs: HLJSApi): Language {
    return {
        name: 'aml',
        case_insensitive: true,
        keywords: ['namespace', 'nullable', 'pk', 'index', 'unique', 'check', 'fk', 'rel', 'type'],
        contains: [
            {scope: 'title', begin: entityRegex},
            {scope: 'title.class', begin: attributeNameRegex},
            // FIXME: {scope: 'type', beginScope: 'title.class', begin: / [a-zA-Z]+/, end: / |\(|=|\n/}, // attribute type
            {scope: 'type', begin: attributeTypeRegex},
            {scope: 'subst', begin: /-> |fk /, end: /[) \n]/}, // inline relation
            {scope: 'string', begin: notesRegex},
            {scope: 'comment', begin: commentRegex},
        ]
    }
}
