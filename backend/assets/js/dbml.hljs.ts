import {HLJSApi, Language} from "highlight.js"

const entityRegex = /^[a-zA-Z_][a-zA-Z0-9_#]*/
const attributeNameRegex = /^ +[a-zA-Z_][a-zA-Z0-9_#]*/
const attributeTypeRegex = /\b(uuid|(var|n)?char2?|character( varying)?|(tiny|medium|long|ci)?text|(tiny|small|big)?int(eger)?(\d+)?|numeric|float|double( precision)?|bool(ean)?|timestamp( with(out)? time zone)?|date(time)?|time( with(out)? time zone)?|interval|json|string|number)\b/
const relationRegex = /> [a-z]+\.[a-z]+/
const stringRegex = /['`][^'`]*['`]/
const commentRegex = /\/\/.*/
const keywordRegex = /Table|pk|primary key|not null|default|unique|note|ref|indexes|enum/

// see https://highlightjs.readthedocs.io/en/latest/language-guide.html
export function language(hljs: HLJSApi): Language {
    return {
        name: 'dbml',
        case_insensitive: true,
        contains: [
            // {scope: 'title', begin: entityRegex},
            {scope: 'title.class', begin: attributeNameRegex},
            // FIXME: {scope: 'type', beginScope: 'title.class', begin: / [a-zA-Z]+/, end: / |\(|=|\n/}, // attribute type
            {scope: 'type', begin: attributeTypeRegex},
            {scope: 'subst', begin: relationRegex},
            {scope: 'string', begin: stringRegex},
            {scope: 'comment', begin: commentRegex},
            {scope: 'keyword', begin: keywordRegex},
        ]
    }
}
