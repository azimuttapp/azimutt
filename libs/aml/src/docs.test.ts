import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {pathJoin, pathParent, pluralize, pluralizeL, slugifyGitHub} from "@azimutt/utils";
import {generateAml, parseAml} from "./index";

describe('AML docs', () => {
    const project = 'libs/aml'
    const amlPaths: string[] = ['./README.md', '../../demos/ecommerce/source_00_design.md', '../../demos/ecommerce/source_10_additional_relations.md']
        .concat(listFiles('../../backend/lib/azimutt_web/templates/website/docs'))
        .filter(path => path.endsWith('.md') || path.endsWith('.aml') || path.endsWith('.html') || path.endsWith('.html.heex'))
    const amlFiles: {[path: string]: string} = Object.fromEntries(amlPaths.map(path => [path, fs.readFileSync(path, 'utf8')]))

    test('parse and generate AML snippets', () => {
        Object.entries(amlFiles).map(([path, content]) => {
            getAmlSnippets(path, content).forEach(({snippet, version}, index) => {
                const res = parseAml(snippet).mapError(errors => errors.filter(e => e.level === 'error'))
                if ((res.errors || []).length > 0) {
                    console.log(`File ${path}, snippet ${index + 1}${version ? ` (${version})` : ''}:\n${snippet}`)
                    expect(res.errors).toEqual([])
                }
                const gen = generateAml(res.result || {}, !!version)
                if (gen !== snippet) {
                    console.log(`File ${path}, snippet ${index + 1}${version ? ` (${version})` : ''}`)
                    expect(gen).toEqual(snippet)
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

function listFiles(dir: string): string[] {
    return fs.readdirSync(dir, {recursive: true}).map(path => pathJoin(dir, path as string))
}

function getAmlSnippets(path: string, content: string): {snippet: string, version?: string}[] {
    if (path.indexOf('/demos/') !== -1) return [{snippet: content}] // files in demos are fully AML
    if (path.endsWith('.aml')) return [{snippet: content}] // aml file
    if (path.endsWith('.md')) return (content.match(/```aml(v1)?[^]*?```/gm) || []).map(snippet => ({
        snippet: snippet.replace(/^```aml(v1)?\n/, '').replace(/```$/, ''),
        version: snippet.startsWith('```amlv1\n') ? 'v1' : undefined
    }))
    if (path.endsWith('.html') || path.endsWith('.html.heex')) return (content.match(/<pre><code class="hljs aml(v1)?">[^]*?<\/code><\/pre>/gm) || []).map(snippet => ({
        snippet: snippet.replace(/^<pre><code class="hljs aml(v1)?">/, '').replace(/<\/code><\/pre>$/, '').replaceAll('&lt;', '<'),
        version: snippet.startsWith('<pre><code class="hljs amlv1">') ? 'v1' : undefined
    }))
    return []
}

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
