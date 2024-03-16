import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {AmlAst, ParserResult, Position} from "../src/parser";

describe('docs', () => {
    const folder = './docs'
    const paths = fs.readdirSync(folder, {recursive: true}).map(path => `${folder}/${path}`)
    const files = paths.filter(path => path.endsWith('.md')).map(path => ({path, content: fs.readFileSync(path, 'utf8')}))

    test('parse AML snippets', () => {
        const amlRegex = /```aml(.*?)```/gms
        const errorFiles = files.map(file => {
            const matches = file.content.match(amlRegex) || []
            const errors = matches.map(aml => aml.replace(/^```aml/, '').replace(/```$/, '')).map((aml, index) => {
                const ast: ParserResult<AmlAst> = {result: [], errors: [], warnings: []} // TODO: parse AML and report errors
                return {index, aml, errors: ast.errors || [], warnings: ast.warnings || []}
            }).filter(res => res.errors.length > 0 || res.warnings.length > 0)
            return {path: file.path, errors}
        }).filter(file => file.errors.length > 0)
        if (errorFiles.length > 0) {
            const allMsg = `\n${errorFiles.length} file(s) with parsing errors:`
            const values = errorFiles.map(file => {
                const fileMsg = `\n  - ${file.errors.length} error(s) in ${file.path}:`
                const values = file.errors.map(err => {
                    const errMsg = `\n    - ${err.errors.length + err.warnings.length} issue(s) in snippet ${err.index + 1}:`
                    const values = err.errors.map(e => `\n      - Error: ${e.message}`)
                        .concat(err.warnings.map(e => `\n      - Warning: ${e.message}`))
                    return errMsg + values.join('')
                })
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('')
        }
    })
    test('check relative links', () => {
        const linkRegex = /\[[^\]]*?\]\([^)]*?\)/g
        const errorFiles = files.map(file => {
            const links = file.content.match(linkRegex) || []
            const brokenLinks = links
                .map(link => link.match(/\[.*?\]\((.*?)\)/)?.[1] || '') // extract url/path
                .filter(link => link.startsWith('.')) // keep relative paths only
                .map(link => `${folder}/${link.split('#')[0]}`) // make them relative to docs folder and remove hash
                .filter(path => !fs.existsSync(path)) // keep the ones not found
            return {path: file.path, brokenLinks}
        }).filter(file => file.brokenLinks.length > 0)
        if (errorFiles.length > 0) {
            const allMsg = `\n${errorFiles.length} file(s) with broken link(s):`
            const values = errorFiles.map(file => {
                const fileMsg = `\n  - ${file.brokenLinks.length} broken link(s) in ${file.path}:`
                const values = file.brokenLinks.map(brokenLink => `\n    - ${brokenLink}`)
                return fileMsg + values.join('')
            })
            throw allMsg + values.join('')
        }
    })
})
