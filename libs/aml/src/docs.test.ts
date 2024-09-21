import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {pathJoin, pathParent, pluralize, pluralizeL, slugifyGitHub} from "@azimutt/utils";
import {generateAml, parseAml} from "./aml";

describe('docs', () => {
    const project = 'libs/aml'
    const amlDocs = './docs'
    const amlPaths: string[] = fs.readdirSync(amlDocs, {recursive: true})
        .map(path => pathJoin(amlDocs, path as string))
        .concat(['./README.md', '../../demos/ecommerce/source_00_design.md', '../../demos/ecommerce/source_10_additional_relations.md'])
        .filter(path => path.endsWith('.md'))
    const amlFiles: {[path: string]: string} = Object.fromEntries(amlPaths.map(path => [path, fs.readFileSync(path, 'utf8')]))
    const amlRegex = /```aml\n[^]*?\n```/gm

    test('parse AML snippets', () => {
        const filesWithErrors = Object.entries(amlFiles).map(([path, content]) => {
            // for `../demos/` files, get the whole file, not just some snippets inside
            const snippets = (path.indexOf('../demos/') !== -1 ? [content] : (content.match(amlRegex) || []).map((s: string) => s.replace(/^```aml\n/, '').replace(/```$/, '')))
                .map((aml, index) => ({index, aml, errors: parseAml(aml).errors || []}))
                .filter(res => res.errors.filter(e => e.kind === 'error').length > 0)
            return {path, snippets}
        }).filter(file => file.snippets.length > 0)

        if (filesWithErrors.length > 0) {
            const nbErrors = filesWithErrors.reduce((acc, f) => acc + f.snippets.reduce((a, e) => a + e.errors.length, 0), 0)
            const allMsg = `${pluralize(nbErrors, 'error')} in ${pluralizeL(filesWithErrors, 'file')}:`
            const values = filesWithErrors.map(file => {
                const fileMsg = `\n\n  - ${pathJoin(project, file.path)}, ${pluralizeL(file.snippets, 'bad snippet')}:`
                const values = file.snippets.map(snippet => {
                    const snippetStart = snippet.aml.slice(0, 70).replace(/\n/g, '\\n').trim() + (snippet.aml.length > 70 ? '...' : '')
                    const snippetMsg = `\n    - snippet ${snippet.index + 1} (${snippetStart}), ${pluralizeL(snippet.errors, 'error')}:`
                    const errorsMsgs = snippet.errors.map(error => `\n      - line ${error.position.start.line}, col ${error.position.start.column}: ${error.message}`)
                    return snippetMsg + errorsMsgs.join('')
                })
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('') + '\n'
        }
    })
    test.skip('re-generate AML snippets', () => {
        Object.entries(amlFiles).map(([path, content]) => {
            const snippets = path.indexOf('../demos/') !== -1 ? [content] : (content.match(amlRegex) || []).map((s: string) => s.replace(/^```aml\n/, '').replace(/```$/, ''))
            snippets.forEach((aml, index) => {
                const res = parseAml(aml)
                const gen = generateAml(res.result || {})
                if (gen !== aml && !aml.includes('namespace')) { // can't generate `namespace` directive for now :/
                    console.log(`File ${path}, snippet ${index + 1}`)
                    expect(gen).toEqual(aml)
                }
            })
        })
    })
    test('check relative links', () => {
        const filesWithErrors = Object.entries(amlFiles).map(([path, content]) => {
            const fileFolder = pathParent(path)
            const anchors = getAnchors(content)
            const links = getLinks(content)
            const brokenLinks = links.filter(link => {
                if (link.startsWith('http')) { // urls
                    return false // don't check them
                } else if (link.startsWith('#')) { // anchors
                    return !anchors.has(link)
                } else { // local paths
                    const [path, anchor] = link.split('#')
                    const linkPath = pathJoin(fileFolder, path)
                    if (!fs.existsSync(linkPath)) return true // keep if file doesn't exist
                    if (anchor) {
                        const linkedContent: string = amlFiles[linkPath] || fs.readFileSync(linkPath, 'utf8')
                        const linkedAnchors = getAnchors(linkedContent)
                        return !linkedAnchors.has('#' + anchor)
                    }
                    return false
                }
            })
            return {path, brokenLinks}
        }).filter(file => file.brokenLinks.length > 0)

        if (filesWithErrors.length > 0) {
            const nbBrokenLinks = filesWithErrors.reduce((acc, f) => acc + f.brokenLinks.length, 0)
            const allMsg = `${pluralize(nbBrokenLinks, 'broken link')} in ${pluralizeL(filesWithErrors, 'file')}:`
            const values = filesWithErrors.map(file => {
                const fileMsg = `\n\n  - ${pathJoin(project, file.path)}, ${pluralizeL(file.brokenLinks, 'broken link')}:`
                const values = file.brokenLinks.map(brokenLink => `\n    - ${brokenLink}`)
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('') + '\n'
        }
    })
})

function getLinks(markdown: string): string[] {
    const linkRegex = /\[[^\]]*?]\([^)]*?\)/g
    const links = markdown.match(linkRegex) || []
    return links.map((link: string) => link.match(/\[.*?]\((.*?)\)/)?.[1] || '') // extract url/path
}

function getAnchors(markdown: string): Set<string> {
    const codeRegex = /^```(?:[a-z]*)?$(.*?)^```$/gm
    const titleRegex = /^#+(.+)$/gm
    const titles = markdown
        .replace(codeRegex, '') // remove code blocks from markdown (may contain comments starting with #, like titles)
        .match(titleRegex) // get lines starting with # (titles)
    return new Set(titles?.map(title => '#' + slugifyGitHub(title.match(/^#+(.+)/)?.[1]?.trim() || '')))
}
