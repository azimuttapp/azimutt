import * as fs from "fs";
import {describe, test} from "@jest/globals";
import {pathJoin, pathParent, slugify} from "@azimutt/utils";
import {ParserResult} from "@azimutt/models";
import {AmlAst} from "../src/parser";

describe('docs', () => {
    const project = 'libs/serde-aml'
    const amlDocs = './docs'
    const amlPaths: string[] = fs.readdirSync(amlDocs, {recursive: true})
        .map(path => pathJoin(amlDocs, path as string))
        .concat(['../../docs/aml/README.md'])
        .filter(path => path.endsWith('.md'))
    const amlFiles: {[path: string]: string} = Object.fromEntries(amlPaths.map(path => [path, fs.readFileSync(path, 'utf8')]))

    test('parse AML snippets', () => {
        const amlRegex = /```aml(.*?)```/gms
        const errorFiles = Object.entries(amlFiles).map(([path, content]) => {
            const matches = content.match(amlRegex) || []
            const errors = matches.map(aml => aml.replace(/^```aml/, '').replace(/```$/, '')).map((aml, index) => {
                const ast: ParserResult<AmlAst> = ParserResult.success([]) // TODO: parse AML and report errors
                return {index, aml, errors: ast.errors || []}
            }).filter(res => res.errors.length > 0)
            return {path, errors}
        }).filter(file => file.errors.length > 0)
        if (errorFiles.length > 0) {
            const allMsg = `\n${errorFiles.length} file(s) with parsing errors:`
            const values = errorFiles.map(file => {
                const fileMsg = `\n  - ${file.errors.length} error(s) in ${pathJoin(project, file.path)}:`
                const values = file.errors.map(err => {
                    const errMsg = `\n    - ${err.errors.length} issue(s) in snippet ${err.index + 1}:`
                    const values = err.errors.map(e => `\n      - Error: ${e.message}`)
                    return errMsg + values.join('')
                })
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('') + '\n'
        }
    })
    test('check relative links', () => {
        const errorFiles = Object.entries(amlFiles).map(([path, content]) => {
            const fileFolder = pathParent(path)
            const anchors = getAnchors(content)
            const brokenLinks = getLinks(content).filter(link => {
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
        if (errorFiles.length > 0) {
            const allMsg = `\n${errorFiles.length} file(s) with broken link(s):`
            const values = errorFiles.map(file => {
                const fileMsg = `\n  - ${file.brokenLinks.length} broken link(s) in ${pathJoin(project, file.path)}:`
                const values = file.brokenLinks.map(brokenLink => `\n    - ${brokenLink}`)
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('') + '\n'
        }
    })
})

function getLinks(markdown: string): string[] {
    const linkRegex = /\[[^\]]*?\]\([^)]*?\)/g
    const links = markdown.match(linkRegex) || []
    return links.map(link => link.match(/\[.*?\]\((.*?)\)/)?.[1] || '') // extract url/path
}

function getAnchors(markdown: string): Set<string> {
    const codeRegex = /^```(?:[a-z]*)?$(.*?)^```$/gms
    const titleRegex = /^#+(.+)$/gm
    const titles = markdown
        .replace(codeRegex, '') // remove code blocks from markdown (may contain comments starting with #, like titles)
        .match(titleRegex) // get lines starting with # (titles)
    return new Set(titles?.map(title => '#' + slugify(title.match(/^#+(.+)/)?.[1]?.trim() || '', {mode: 'github'})))
}
