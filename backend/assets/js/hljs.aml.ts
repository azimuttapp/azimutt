import {HLJSApi, Language} from "highlight.js";

export default function(hljs: HLJSApi): Language {
    return {
        name: 'AML',
        case_insensitive: true,
        keywords: 'nullable pk index unique check fk',
        contains: [
            {scope: 'title', begin: /^[a-zA-Z]+/, end: / |\n/}, // entities
            {scope: 'title.class', begin: /^  [a-zA-Z]+/, end: / /}, // attributes
            // FIXME: {scope: 'type', beginScope: 'title.class', begin: / [a-zA-Z]+/, end: / |\(|=|\n/}, // attribute type
            {scope: 'type', begin: /\buuid|varchar|text|int|boolean|timestamp\b/,}, // attribute type
            {scope: 'subst', begin: /-> |fk /, end: /\)| |\n/}, // inline relation
            {scope: 'string', begin: /\|/, end: /#|\n/, excludeBegin: true}, // notes
            hljs.COMMENT('#', '\n'), // comments
        ]
    }
}
