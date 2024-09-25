import {describe, expect, test} from "@jest/globals";
import {Entity} from "@azimutt/models";
import {
    attributeIndentationMatch,
    attributeNameWrittenMatch,
    attributeTypeWrittenMatch,
    attributeNestedMatch,
    attributeRootMatch,
    entityWrittenMatch,
    relationLinkWrittenMatch,
    relationSrcWrittenMatch,
    suggestAttributeType,
    suggestExtra,
    suggestRelationRef
} from "./monaco";
import {CompletionItem, Position} from "./monaco.types";

describe('Monaco AML', () => {
    describe('completion', () => {
        describe('line matchers', () => {
            test('entityWrittenMatch', () => {
                expect(entityWrittenMatch('users')).toEqual(undefined)
                expect(entityWrittenMatch('users ')).toEqual(['users'])
                expect(entityWrittenMatch('  ')).toEqual(undefined)
                expect(entityWrittenMatch('  id')).toEqual(undefined)
            })
            test('attributeIndentationMatch', () => {
                expect(attributeIndentationMatch('users')).toEqual(undefined)
                expect(attributeIndentationMatch('users ')).toEqual(undefined)
                expect(attributeIndentationMatch(' ')).toEqual([' '])
                expect(attributeIndentationMatch('  ')).toEqual(['  '])
                expect(attributeIndentationMatch('  id')).toEqual(undefined)
            })
            test('attributeNameWrittenMatch', () => {
                expect(attributeNameWrittenMatch('users')).toEqual(undefined)
                expect(attributeNameWrittenMatch('users ')).toEqual(undefined)
                expect(attributeNameWrittenMatch('  ')).toEqual(undefined)
                expect(attributeNameWrittenMatch('  id')).toEqual(undefined)
                expect(attributeNameWrittenMatch('  id ')).toEqual(['id'])
            })
            test('attributeTypeWrittenMatch', () => {
                expect(attributeTypeWrittenMatch('users')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('users ')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('  ')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('  id')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('  id ')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('  id int')).toEqual(undefined)
                expect(attributeTypeWrittenMatch('  id int ')).toEqual(['id', 'int'])
            })
            test('attributeRootMatch', () => {
                expect(attributeRootMatch('users')).toEqual(undefined)
                expect(attributeRootMatch('users(')).toEqual(['users']) // minimal
                expect(attributeRootMatch('users( ')).toEqual(['users'])
                expect(attributeRootMatch('users(a')).toEqual(undefined)
                expect(attributeRootMatch('web.public.users(')).toEqual(['web.public.users']) // namespace
                expect(attributeRootMatch('  user_id int -> users')).toEqual(undefined)
                expect(attributeRootMatch('  user_id int -> users(')).toEqual(['users']) // attribute relation
                expect(attributeRootMatch('rel users')).toEqual(undefined)
                expect(attributeRootMatch('rel users(')).toEqual(['users']) // relation src
                expect(attributeRootMatch('rel posts(author) -> users')).toEqual(undefined)
                expect(attributeRootMatch('rel posts(author) -> users(')).toEqual(['users']) // relation ref
            })
            test('attributeNestedMatch', () => {
                expect(attributeNestedMatch('users')).toEqual(undefined)
                expect(attributeNestedMatch('users(')).toEqual(undefined)
                expect(attributeNestedMatch('users(settings')).toEqual(undefined)
                expect(attributeNestedMatch('users(settings.')).toEqual(['users', 'settings'])
                expect(attributeNestedMatch('web.public.users(settings.address.')).toEqual(['web.public.users', 'settings.address']) // namespace
                expect(attributeNestedMatch('users(name, settings.')).toEqual(['users', 'settings']) // composite
            })
            test('relationLinkWrittenMatch', () => {
                expect(relationLinkWrittenMatch('->')).toEqual(undefined)
                expect(relationLinkWrittenMatch('-> ')).toEqual(['-', undefined, '>']) // minimal
                expect(relationLinkWrittenMatch('-> a')).toEqual(undefined)
                expect(relationLinkWrittenMatch('  user_id int ->')).toEqual(undefined)
                expect(relationLinkWrittenMatch('  user_id int -> ')).toEqual(['-', undefined, '>']) // attribute relation
                expect(relationLinkWrittenMatch('rel users(id) ->')).toEqual(undefined)
                expect(relationLinkWrittenMatch('rel users(id) -> ')).toEqual(['-', undefined, '>']) // relation
                expect(relationLinkWrittenMatch('-item_kind=users> ')).toEqual(['-', 'item_kind=users', '>']) // polymorphic
            })
            test('relationSrcWrittenMatch', () => {
                expect(relationSrcWrittenMatch('rel users')).toEqual(undefined)
                expect(relationSrcWrittenMatch('rel users(')).toEqual(undefined)
                expect(relationSrcWrittenMatch('rel users(id')).toEqual(undefined)
                expect(relationSrcWrittenMatch('rel users(id)')).toEqual(undefined)
                expect(relationSrcWrittenMatch('rel users(id) ')).toEqual(['users(id)'])
                expect(relationSrcWrittenMatch('rel users(id, name) ')).toEqual(['users(id, name)'])
                expect(relationSrcWrittenMatch('rel web.public.users(id, settings.addess.street) ')).toEqual(['web.public.users(id, settings.addess.street)'])
            })
        })
        describe('suggestions', () => {
            const pos: Position = {column: 0, lineNumber: 0}
            test('suggestAttributeType', () => {
                const basic: CompletionItem[] = []
                suggestAttributeType(basic, pos, [])
                expect(basic.map(e => e.insertText).includes('varchar')).toBeTruthy()
                expect(basic.map(e => e.insertText).includes('public.box')).toBeFalsy()

                const custom: CompletionItem[] = []
                suggestAttributeType(custom, pos, [{schema: 'public', name: 'box'}])
                expect(custom.map(e => e.insertText).includes('varchar')).toBeTruthy()
                expect(custom.map(e => e.insertText).includes('public.box')).toBeTruthy()
            })
            test('suggestRelationRef', () => {
                const entities: Entity[] = [{name: 'users', pk: {attrs: [['id']]}}, {name: 'posts', pk: {attrs: [['id']]}}, {name: 'members', pk: {attrs: [['user_id'], ['post_id']]}}]
                const empty: CompletionItem[] = []
                suggestRelationRef(empty, pos, [], undefined, '')
                expect(empty).toEqual([])

                const attribute: CompletionItem[] = []
                suggestRelationRef(attribute, pos, entities, 1, '-> ')
                expect(attribute.map(e => e.insertText)).toEqual(['-> users(id)', '-> posts(id)'])

                const relation: CompletionItem[] = []
                suggestRelationRef(relation, pos, entities, 2, '')
                expect(relation.map(e => e.insertText)).toEqual(['members(user_id, post_id)'])

                const all: CompletionItem[] = []
                suggestRelationRef(all, pos, entities, undefined, '')
                expect(all.map(e => e.insertText)).toEqual(['users(id)', 'posts(id)', 'members(user_id, post_id)'])
            })
            test('suggestExtra', () => {
                const entityExtra: CompletionItem[] = []
                suggestExtra(entityExtra, pos, '')
                expect(entityExtra.map(e => e.label)).toEqual(['{key: value}', '| inline doc', '||| multi-line doc', '# comment'])
                expect(entityExtra.map(e => e.insertText)).toEqual(['{${1:key}: ${2:value}}', '| ${1:your doc}', '|||\n  ${1:your doc}\n|||', '# ${1:your comment}'])

                const attributeExtra: CompletionItem[] = []
                suggestExtra(attributeExtra, pos, '  ')
                expect(attributeExtra.map(e => e.label)).toEqual(['{key: value}', '| inline doc', '||| multi-line doc', '# comment'])
                expect(attributeExtra.map(e => e.insertText)).toEqual(['{${1:key}: ${2:value}}', '| ${1:your doc}', '|||\n    ${1:your doc}\n  |||', '# ${1:your comment}'])

                const nestedAttributeExtra: CompletionItem[] = []
                suggestExtra(nestedAttributeExtra, pos, '      ')
                expect(nestedAttributeExtra.map(e => e.label)).toEqual(['{key: value}', '| inline doc', '||| multi-line doc', '# comment'])
                expect(nestedAttributeExtra.map(e => e.insertText)).toEqual(['{${1:key}: ${2:value}}', '| ${1:your doc}', '|||\n        ${1:your doc}\n      |||', '# ${1:your comment}'])
            })
        })
    })
})
