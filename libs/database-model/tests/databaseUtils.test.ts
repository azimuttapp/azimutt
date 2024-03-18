import {describe, expect, test} from "@jest/globals";
import {
    AttributeId,
    AttributePath,
    AttributePathId,
    AttributeRef,
    EntityId,
    EntityRef,
    formatAttributePath,
    formatAttributeRef,
    formatEntityRef,
    formatNamespace,
    Namespace,
    NamespaceId,
    parseAttributePath,
    parseAttributeRef,
    parseAttributeType,
    parseEntityRef,
    parseNamespace
} from "../src";

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
            expect(parseNamespace(id)).toEqual(ref)
            expect(formatNamespace(ref)).toEqual(id)
        })
        const badSamples: { sourceId: NamespaceId; ref: Namespace; targetId: NamespaceId }[] = [
            {sourceId: 'bad char', ref: {schema: 'bad char'}, targetId: '"bad char"'},
            // {sourceId: 'a.b.c.d.e.f', ref: {database: 'a.b.c', catalog: 'd', schema: 'e', entity: 'f'}, targetId: '"a.b.c".d.e.f'}, // FIXME: don't split on . inside "
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(parseNamespace(sourceId)).toEqual(ref)
            expect(parseNamespace(targetId)).toEqual(ref)
            expect(formatNamespace(ref)).toEqual(targetId)
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
            expect(parseEntityRef(id)).toEqual(ref)
            expect(formatEntityRef(ref)).toEqual(id)
        })
        const badSamples: { sourceId: EntityId; ref: EntityRef; targetId: EntityId }[] = [
            {sourceId: '', ref: {entity: ''}, targetId: ''},
            {sourceId: 'bad char', ref: {entity: 'bad char'}, targetId: '"bad char"'},
            // {sourceId: 'a.b.c.d.e.f', ref: {database: 'a.b.c', catalog: 'd', schema: 'e', entity: 'f'}, targetId: '"a.b.c".d.e.f'}, // FIXME: don't split on . inside "
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(parseEntityRef(sourceId)).toEqual(ref)
            expect(parseEntityRef(targetId)).toEqual(ref)
            expect(formatEntityRef(ref)).toEqual(targetId)
        })
    })
    test('parse & format AttributePath', () => {
        const samples: { path: AttributePathId; names: AttributePath }[] = [
            {path: 'details', names: ['details']},
            {path: 'details.address', names: ['details', 'address']},
            {path: 'details.address.street', names: ['details', 'address', 'street']},
        ]
        samples.map(({path, names}) => {
            expect(parseAttributePath(path)).toEqual(names)
            expect(formatAttributePath(names)).toEqual(path)
        })
    })
    test('parse & format AttributeRef', () => {
        const samples: { id: AttributeId; ref: AttributeRef }[] = [
            {id: 'users(id)', ref: {entity: 'users', attribute: ['id']}},
        ]
        samples.map(({id, ref}) => {
            expect(parseAttributeRef(id)).toEqual(ref)
            expect(formatAttributeRef(ref)).toEqual(id)
        })
        const badSamples: { sourceId: AttributeId; ref: AttributeRef; targetId: AttributeId }[] = [
            {sourceId: 'users', ref: {entity: 'users', attribute: ['']}, targetId: 'users()'},
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(parseAttributeRef(sourceId)).toEqual(ref)
            expect(parseAttributeRef(targetId)).toEqual(ref)
            expect(formatAttributeRef(ref)).toEqual(targetId)
        })
    })
    test('parse & format AttributeType', () => {
        expect(parseAttributeType('text')).toEqual({full: 'text', kind: 'unknown'})
    })
})
