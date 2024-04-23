import {describe, expect, test} from "@jest/globals";
import {
    AttributeId,
    AttributePath,
    attributePathFromId,
    AttributePathId,
    attributePathToId,
    AttributeRef,
    attributeRefFromId,
    attributeRefToId,
    attributeTypeParse,
    EntityId,
    EntityRef,
    entityRefFromId,
    entityRefToId,
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
    test('parse & format AttributeRef', () => {
        const samples: { id: AttributeId; ref: AttributeRef }[] = [
            {id: 'users(id)', ref: {entity: 'users', attribute: ['id']}},
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
})
