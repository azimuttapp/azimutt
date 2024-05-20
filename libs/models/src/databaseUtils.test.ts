import {describe, expect, test} from "@jest/globals";
import {
    AttributeId,
    AttributePath,
    attributePathFromId,
    AttributePathId,
    attributePathSame,
    attributePathToId,
    AttributeRef,
    attributeRefFromId,
    attributeRefSame,
    attributeRefToId,
    AttributesId,
    AttributesRef,
    attributesRefFromId,
    attributesRefSame,
    attributesRefToId,
    attributeTypeParse,
    EntityId,
    EntityRef,
    entityRefFromId,
    entityRefSame,
    entityRefToId,
    flattenAttribute,
    getAttribute,
    getPeerAttributes,
    Namespace,
    namespaceFromId,
    NamespaceId,
    namespaceToId,
    TypeId,
    TypeRef,
    typeRefFromId,
    typeRefToId
} from "./index";

describe('databaseUtils', () => {
    test('parse & format Namespace', () => {
        const samples: { id: NamespaceId; ref: Namespace }[] = [
            {id: '', ref: {}},
            {id: 'public', ref: {schema: 'public'}},
            {id: 'core.public', ref: {catalog: 'core', schema: 'public'}},
            {id: 'ax.core.public', ref: {database: 'ax', catalog: 'core', schema: 'public'}},
            {id: 'ax..', ref: {database: 'ax'}},
            {id: 'core.', ref: {catalog: 'core'}},
            {id: '"user schema"', ref: {schema: 'user schema'}},
        ]
        samples.map(({id, ref}) => {
            expect(namespaceFromId(id)).toEqual(ref)
            expect(namespaceToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: NamespaceId; ref: Namespace; targetId: NamespaceId }[] = [
            {sourceId: 'bad char', ref: {schema: 'bad char'}, targetId: '"bad char"'},
            // {sourceId: 'a.b.c.d.e.f', ref: {database: 'a.b.c', catalog: 'd', schema: 'e', entity: 'f'}, targetId: '"a.b.c".d.e.f'}, // FIXME: don't split on . inside "
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(namespaceFromId(sourceId)).toEqual(ref)
            expect(namespaceFromId(targetId)).toEqual(ref)
            expect(namespaceToId(ref)).toEqual(targetId)
        })
    })
    test('parse & format EntityRef', () => {
        const samples: { id: EntityId; ref: EntityRef }[] = [
            {id: 'users', ref: {entity: 'users'}},
            {id: 'public.users', ref: {schema: 'public', entity: 'users'}},
            {id: 'core.public.users', ref: {catalog: 'core', schema: 'public', entity: 'users'}},
            {id: 'ax.core.public.users', ref: {database: 'ax', catalog: 'core', schema: 'public', entity: 'users'}},
            {id: 'ax...users', ref: {database: 'ax', entity: 'users'}},
            {id: '"user table"', ref: {entity: 'user table'}},
        ]
        samples.map(({id, ref}) => {
            expect(entityRefFromId(id)).toEqual(ref)
            expect(entityRefToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: EntityId; ref: EntityRef; targetId: EntityId }[] = [
            {sourceId: '', ref: {entity: ''}, targetId: ''},
            {sourceId: 'bad char', ref: {entity: 'bad char'}, targetId: '"bad char"'},
            // {sourceId: 'a.b.c.d.e.f', ref: {database: 'a.b.c', catalog: 'd', schema: 'e', entity: 'f'}, targetId: '"a.b.c".d.e.f'}, // FIXME: don't split on . inside "
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(entityRefFromId(sourceId)).toEqual(ref)
            expect(entityRefFromId(targetId)).toEqual(ref)
            expect(entityRefToId(ref)).toEqual(targetId)
        })
    })
    test('entityRefSame', () => {
        expect(entityRefSame({entity: 'users'}, {entity: 'users'})).toBeTruthy()
        expect(entityRefSame({schema: 'public', entity: 'users'}, {schema: 'public', entity: 'users'})).toBeTruthy()
        expect(entityRefSame({catalog: 'gtm', schema: 'public', entity: 'users'}, {catalog: 'gtm', schema: 'public', entity: 'users'})).toBeTruthy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'})).toBeTruthy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ae', catalog: 'gtm', schema: 'public', entity: 'users'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', catalog: 'cdn', schema: 'public', entity: 'users'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', catalog: 'cdn', schema: 'cdo', entity: 'users'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', catalog: 'cdn', schema: 'cdo', entity: 'accounts'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {catalog: 'gtm', schema: 'public', entity: 'users'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', schema: 'public', entity: 'users'})).toBeFalsy()
        expect(entityRefSame({database: 'ax', catalog: 'gtm', schema: 'public', entity: 'users'}, {database: 'ax', catalog: 'gtm', entity: 'users'})).toBeFalsy()
    })
    test('parse & format AttributePath', () => {
        const samples: { path: AttributePathId; names: AttributePath }[] = [
            {path: 'details', names: ['details']},
            {path: 'details.address', names: ['details', 'address']},
            {path: 'details.address.street', names: ['details', 'address', 'street']},
        ]
        samples.map(({path, names}) => {
            expect(attributePathFromId(path)).toEqual(names)
            expect(attributePathToId(names)).toEqual(path)
        })
    })
    test('attributePathSame', () => {
        expect(attributePathSame(['id'], ['id'])).toBeTruthy()
        expect(attributePathSame(['details', 'address', 'street'], ['details', 'address', 'street'])).toBeTruthy()
        expect(attributePathSame(['id'], ['name'])).toBeFalsy()
        expect(attributePathSame(['details', 'address', 'street'], ['details', 'address'])).toBeFalsy()
        expect(attributePathSame(['details', 'address', 'street'], ['details', 'address', 'city'])).toBeFalsy()
        expect(attributePathSame(['details', 'address', 'street'], ['details', 'place', 'street'])).toBeFalsy()
    })
    test('parse & format AttributeRef', () => {
        const samples: { id: AttributeId; ref: AttributeRef }[] = [
            {id: 'users(id)', ref: {entity: 'users', attribute: ['id']}},
            {id: 'users(details.org)', ref: {entity: 'users', attribute: ['details', 'org']}},
        ]
        samples.map(({id, ref}) => {
            expect(attributeRefFromId(id)).toEqual(ref)
            expect(attributeRefToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: AttributeId; ref: AttributeRef; targetId: AttributeId }[] = [
            {sourceId: 'users', ref: {entity: 'users', attribute: ['']}, targetId: 'users()'},
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(attributeRefFromId(sourceId)).toEqual(ref)
            expect(attributeRefFromId(targetId)).toEqual(ref)
            expect(attributeRefToId(ref)).toEqual(targetId)
        })
    })
    test('attributeRefSame', () => {
        expect(attributeRefSame({entity: 'users', attribute: ['id']}, {entity: 'users', attribute: ['id']})).toBeTruthy()
        expect(attributeRefSame({entity: 'users', attribute: ['id']}, {entity: 'users', attribute: ['id', 'name']})).toBeFalsy()
        expect(attributeRefSame({entity: 'users', attribute: ['id']}, {entity: 'users', attribute: ['name']})).toBeFalsy()
    })
    test('parse & format AttributesRef', () => {
        const samples: { id: AttributesId; ref: AttributesRef }[] = [
            {id: 'users(id)', ref: {entity: 'users', attributes: [['id']]}},
            {id: 'users(id, name)', ref: {entity: 'users', attributes: [['id'], ['name']]}},
            {id: 'users(details.org)', ref: {entity: 'users', attributes: [['details', 'org']]}},
        ]
        samples.map(({id, ref}) => {
            expect(attributesRefFromId(id)).toEqual(ref)
            expect(attributesRefToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: AttributesId; ref: AttributesRef; targetId: AttributesId }[] = [
            {sourceId: 'users', ref: {entity: 'users', attributes: [['']]}, targetId: 'users()'},
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(attributesRefFromId(sourceId)).toEqual(ref)
            expect(attributesRefFromId(targetId)).toEqual(ref)
            expect(attributesRefToId(ref)).toEqual(targetId)
        })
    })
    test('attributesRefSame', () => {
        expect(attributesRefSame({entity: 'users', attributes: [['id']]}, {entity: 'users', attributes: [['id']]})).toBeTruthy()
        expect(attributesRefSame({entity: 'users', attributes: [['id'], ['name']]}, {entity: 'users', attributes: [['id'], ['name']]})).toBeTruthy()
        expect(attributesRefSame({entity: 'users', attributes: [['id']]}, {entity: 'users', attributes: [['id', 'name']]})).toBeFalsy()
        expect(attributesRefSame({entity: 'users', attributes: [['id']]}, {entity: 'users', attributes: [['name']]})).toBeFalsy()
    })
    test('parse & format AttributeType', () => {
        expect(attributeTypeParse('text')).toEqual({full: 'text', kind: 'unknown'})
    })
    test('parse & format TypeRef', () => {
        const samples: { id: TypeId; ref: TypeRef }[] = [
            {id: 'users', ref: {type: 'users'}},
            {id: 'public.users', ref: {schema: 'public', type: 'users'}},
            {id: 'core.public.users', ref: {catalog: 'core', schema: 'public', type: 'users'}},
            {id: 'ax.core.public.users', ref: {database: 'ax', catalog: 'core', schema: 'public', type: 'users'}},
            {id: 'ax...users', ref: {database: 'ax', type: 'users'}},
            {id: '"user table"', ref: {type: 'user table'}},
        ]
        samples.map(({id, ref}) => {
            expect(typeRefFromId(id)).toEqual(ref)
            expect(typeRefToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: TypeId; ref: TypeRef; targetId: TypeId }[] = [
            {sourceId: '', ref: {type: ''}, targetId: ''},
            {sourceId: 'bad char', ref: {type: 'bad char'}, targetId: '"bad char"'},
            // {sourceId: 'a.b.c.d.e.f', ref: {database: 'a.b.c', catalog: 'd', schema: 'e', type: 'f'}, targetId: '"a.b.c".d.e.f'}, // FIXME: don't split on . inside "
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(typeRefFromId(sourceId)).toEqual(ref)
            expect(typeRefFromId(targetId)).toEqual(ref)
            expect(typeRefToId(ref)).toEqual(targetId)
        })
    })
    test('getAttribute', () => {
        const id = {name: 'id', type: 'uuid'}
        const street = {name: 'street', type: 'varchar'}
        const city = {name: 'city', type: 'varchar'}
        const address = {name: 'address', type: 'json', attrs: [street, city]}
        const details = {name: 'details', type: 'json', attrs: [address]}
        expect(getAttribute(undefined, [])).toEqual(undefined)
        expect(getAttribute([], [])).toEqual(undefined)
        expect(getAttribute([], ['id'])).toEqual(undefined)
        expect(getAttribute([id], [])).toEqual(undefined)
        expect(getAttribute([id], ['id'])).toEqual(id)
        expect(getAttribute([id], ['details'])).toEqual(undefined)
        expect(getAttribute([id, details], ['details'])).toEqual(details)
        expect(getAttribute([id, details], ['details', 'address'])).toEqual(address)
        expect(getAttribute([id, details], ['details', 'address', 'city'])).toEqual(city)
        expect(getAttribute([id, details], ['details', 'bad', 'city'])).toEqual(undefined)
    })
    test('getPeerAttributes', () => {
        const id = {name: 'id', type: 'uuid'}
        const street = {name: 'street', type: 'varchar'}
        const city = {name: 'city', type: 'varchar'}
        const address = {name: 'address', type: 'json', attrs: [street, city]}
        const details = {name: 'details', type: 'json', attrs: [address]}
        expect(getPeerAttributes(undefined, [])).toEqual([])
        expect(getPeerAttributes([], [])).toEqual([])
        expect(getPeerAttributes([], ['id'])).toEqual([])
        expect(getPeerAttributes([id], [])).toEqual([id])
        expect(getPeerAttributes([id], ['id'])).toEqual([id])
        expect(getPeerAttributes([id, details], ['details'])).toEqual([id, details])
        expect(getPeerAttributes([id, details], ['details', 'address'])).toEqual([address])
        expect(getPeerAttributes([id, details], ['details', 'address', 'city'])).toEqual([street, city])
        expect(getPeerAttributes([id, details], ['details', 'bad', 'city'])).toEqual([])
    })
    test('flattenAttribute', () => {
        expect(flattenAttribute({name: 'id', type: 'uuid'})).toEqual([{path: ['id'], attr: {name: 'id', type: 'uuid'}}])
        expect(flattenAttribute({name: 'details', type: 'json', attrs: [{name: 'address', type: 'varchar'}]})).toEqual([
            {path: ['details'], attr: {name: 'details', type: 'json', attrs: [{name: 'address', type: 'varchar'}]}},
            {path: ['details', 'address'], attr: {name: 'address', type: 'varchar'}},
        ])
        expect(flattenAttribute({name: 'details', type: 'json', attrs: [
            {name: 'twitter', type: 'varchar'},
            {name: 'address', type: 'json', attrs: [
                {name: 'street', type: 'varchar'},
                {name: 'city', type: 'varchar'},
            ]},
            {name: 'created', type: 'varchar'},
        ]})).toEqual([
            {path: ['details'], attr: {name: 'details', type: 'json', attrs: [
                {name: 'twitter', type: 'varchar'},
                {name: 'address', type: 'json', attrs: [
                    {name: 'street', type: 'varchar'},
                    {name: 'city', type: 'varchar'},
                ]},
                {name: 'created', type: 'varchar'},
            ]}},
            {path: ['details', 'twitter'], attr: {name: 'twitter', type: 'varchar'}},
            {path: ['details', 'address'], attr: {name: 'address', type: 'json', attrs: [
                {name: 'street', type: 'varchar'},
                {name: 'city', type: 'varchar'},
            ]}},
            {path: ['details', 'address', 'street'], attr: {name: 'street', type: 'varchar'}},
            {path: ['details', 'address', 'city'], attr: {name: 'city', type: 'varchar'}},
            {path: ['details', 'created'], attr: {name: 'created', type: 'varchar'}},
        ])
    })
})
