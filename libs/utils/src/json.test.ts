import {describe, expect, test} from "@jest/globals";
import {safeJsonParse, stringify} from "./json";

describe('json', () => {
    test('safeJsonParse', () => {
        expect(safeJsonParse('bad')).toEqual('bad')
        expect(safeJsonParse('"string"')).toEqual('string')
        expect(safeJsonParse('1')).toEqual(1)
        expect(safeJsonParse('{"foo": "bar"}')).toEqual({foo: 'bar'})
    })
    describe('stringify', () => {
        test('same as JSON.stringify', () => {
            [
                undefined,
                null,
                function () {},
                0,
                3,
                3.14,
                NaN,
                Infinity,
                new Number(3),
                true,
                false,
                new Boolean(false),
                '',
                'text',
                new String("String"),
                "some'esca'pe",
                'some"esca"pe',
                'new\nline',
                'sla\\sh',
                Symbol(''),
                Symbol('sym'),
                new Date(),
                [],
                [undefined, null, function () {}, 0, 3, 3.14, true, false, '', 'text', Symbol(''), Symbol('sym'), new Date()],
                {},
                {id: 1, name: 'sam'},
                {name: {first: 'sam', last: 'knu', middle: null}, tags: ['a', {value: 'b'}, undefined], created: null, updated: undefined},
                new Set([1]),
                new Map([[1, 2]]),
                new WeakSet([{a: 1}]),
                new WeakMap([[{a: 1}, 2]]),
                {x: undefined, y: Object, z: Symbol("")},
                {x: 5, y: 6, toJSON() {return this.x + this.y}},
                {[Symbol("foo")]: "foo"},
            ].forEach(v => {
                expect(stringify(v)).toEqual(JSON.stringify(v) || '')
                expect(stringify(v, 0)).toEqual(JSON.stringify(v, null, 0) || '')
                expect(stringify(v, 2)).toEqual(JSON.stringify(v, null, 2) || '')
                expect(stringify(v, 3)).toEqual(JSON.stringify(v, null, 3) || '')
                expect(stringify(v, '')).toEqual(JSON.stringify(v, null, '') || '')
                expect(stringify(v, '.')).toEqual(JSON.stringify(v, null, '.') || '')
                expect(stringify(v, '---')).toEqual(JSON.stringify(v, null, '---') || '')
            })
        })
        test('more permissive than JSON.stringify', () => {
            expect(stringify(BigInt('2'))).toEqual('2')
            expect(() => JSON.stringify(BigInt('2'))).toThrow(TypeError)
        })
        test('custom', () => {
            const db = {
                entities: [{
                    name: 'users',
                    attrs: [
                        {name: 'id', type: 'uuid'},
                        {name: 'name', type: 'varchar'},
                        {name: 'settings', type: 'json', attrs: [
                            {name: 'github', type: 'string'},
                            {name: 'twitter', type: 'string'},
                        ]},
                    ],
                    pk: {attrs: [['id']]},
                    indexes: [{attrs: [['settings', 'github'], ['settings', 'twitter']]}]
                }]
            }
            expect(stringify(db)).toEqual(JSON.stringify(db))
            expect(stringify(db, 2)).toEqual(JSON.stringify(db, null, 2))
            expect(stringify(db, (path: (string | number)[], value: any) => {
                const last = path[path.length - 1]
                if (last === 'entities') return 0
                if (path.includes('pk')) return 0
                if (path.includes('indexes') && path.length > 3) return 0
                if (path.includes('attrs') && last !== 'attrs') return 0
                return 2
            })).toEqual(`{
  "entities": [{
    "name": "users",
    "attrs": [
      {"name": "id", "type": "uuid"},
      {"name": "name", "type": "varchar"},
      {"name": "settings", "type": "json", "attrs": [
        {"name": "github", "type": "string"},
        {"name": "twitter", "type": "string"}
      ]}
    ],
    "pk": {"attrs": [["id"]]},
    "indexes": [
      {"attrs": [["settings", "github"], ["settings", "twitter"]]}
    ]
  }]
}`)
        })
    })
})
