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
    attributeValueToString,
    DatabaseKind,
    EntityId,
    EntityRef,
    entityRefFromId,
    entityRefSame,
    entityRefToId,
    flattenAttributes,
    generateJsonDatabase,
    getAttribute,
    getPeerAttributes,
    Namespace,
    namespaceFromId,
    NamespaceId,
    namespaceToId,
    parseJsonDatabase,
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
        expect(entityRefSame({entity: '*'}, {entity: 'users'})).toBeTruthy() // wildcard
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
        expect(attributePathSame(['details', '*', 'street'], ['details', 'place', 'street'])).toBeTruthy() // wildcard
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
            {id: 'users(id)', ref: {entity: 'users', attrs: [['id']]}},
            {id: 'users(id, name)', ref: {entity: 'users', attrs: [['id'], ['name']]}},
            {id: 'users(details.org)', ref: {entity: 'users', attrs: [['details', 'org']]}},
        ]
        samples.map(({id, ref}) => {
            expect(attributesRefFromId(id)).toEqual(ref)
            expect(attributesRefToId(ref)).toEqual(id)
        })
        const badSamples: { sourceId: AttributesId; ref: AttributesRef; targetId: AttributesId }[] = [
            {sourceId: 'users', ref: {entity: 'users', attrs: [['']]}, targetId: 'users()'},
        ]
        badSamples.map(({sourceId, ref, targetId}) => {
            expect(attributesRefFromId(sourceId)).toEqual(ref)
            expect(attributesRefFromId(targetId)).toEqual(ref)
            expect(attributesRefToId(ref)).toEqual(targetId)
        })
        expect(attributesRefFromId('*(created_by)')).toEqual({entity: '*', attrs: [['created_by']]}) // wildcard
        expect(attributesRefFromId('"*"(created_by)')).toEqual({entity: '*', attrs: [['created_by']]}) // wildcard
        expect(attributesRefFromId("'*'(created_by)")).toEqual({entity: '*', attrs: [['created_by']]}) // wildcard
        expect(attributesRefToId({entity: '*', attrs: [['created_by']]})).toEqual('"*"(created_by)') // wildcard
    })
    test('attributesRefSame', () => {
        expect(attributesRefSame({entity: 'users', attrs: [['id']]}, {entity: 'users', attrs: [['id']]})).toBeTruthy()
        expect(attributesRefSame({entity: 'users', attrs: [['id'], ['name']]}, {entity: 'users', attrs: [['id'], ['name']]})).toBeTruthy()
        expect(attributesRefSame({entity: 'users', attrs: [['id']]}, {entity: 'users', attrs: [['id', 'name']]})).toBeFalsy()
        expect(attributesRefSame({entity: 'users', attrs: [['id']]}, {entity: 'users', attrs: [['name']]})).toBeFalsy()
        expect(attributesRefSame({entity: '*', attrs: [['created_by']]}, {entity: 'users', attrs: [['created_by']]})).toBeTruthy() // wildcard
        expect(attributesRefSame({entity: 'users', attrs: [['*']]}, {entity: 'users', attrs: [['created_by']]})).toBeTruthy() // wildcard
    })
    test('parse AttributeType', () => {
        // PostgreSQL: https://www.postgresql.org/docs/current/datatype.html
        expect(attributeTypeParse('char')).toEqual({full: 'char', kind: 'string'})
        expect(attributeTypeParse('char(10)')).toEqual({full: 'char(10)', kind: 'string', size: 10})
        expect(attributeTypeParse('character')).toEqual({full: 'character', kind: 'string'})
        expect(attributeTypeParse('character(10)')).toEqual({full: 'character(10)', kind: 'string', size: 10})
        expect(attributeTypeParse('varchar')).toEqual({full: 'varchar', kind: 'string', variable: true})
        expect(attributeTypeParse('varchar(10)')).toEqual({full: 'varchar(10)', kind: 'string', size: 10, variable: true})
        expect(attributeTypeParse('varchar(10) CHARACTER SET utf8mb4')).toEqual({full: 'varchar(10) CHARACTER SET utf8mb4', kind: 'string', size: 10, variable: true, encoding: 'utf8mb4'}) // MySQL
        expect(attributeTypeParse('character varying')).toEqual({full: 'character varying', kind: 'string', variable: true})
        expect(attributeTypeParse('character varying(10)')).toEqual({full: 'character varying(10)', kind: 'string', size: 10, variable: true})
        expect(attributeTypeParse('bpchar(10)')).toEqual({full: 'bpchar(10)', kind: 'string', size: 10})
        expect(attributeTypeParse('nchar(10)')).toEqual({full: 'nchar(10)', kind: 'string', size: 10}) // SQL Server
        expect(attributeTypeParse('nvarchar(10)')).toEqual({full: 'nvarchar(10)', kind: 'string', size: 10, variable: true}) // SQL Server
        expect(attributeTypeParse('string')).toEqual({full: 'string', kind: 'string'}) // BigQuery
        expect(attributeTypeParse('string(10)')).toEqual({full: 'string(10)', kind: 'string', size: 10}) // BigQuery
        expect(attributeTypeParse('bit')).toEqual({full: 'bit', kind: 'string'}) // string in Postgres but int in MySQL :/
        expect(attributeTypeParse('bit(5)')).toEqual({full: 'bit(5)', kind: 'string', size: 5})
        expect(attributeTypeParse('varbit')).toEqual({full: 'varbit', kind: 'string', variable: true})
        expect(attributeTypeParse('varbit(5)')).toEqual({full: 'varbit(5)', kind: 'string', size: 5, variable: true})
        expect(attributeTypeParse('bit varying')).toEqual({full: 'bit varying', kind: 'string', variable: true})
        expect(attributeTypeParse('bit varying(5)')).toEqual({full: 'bit varying(5)', kind: 'string', size: 5, variable: true})
        expect(attributeTypeParse('text')).toEqual({full: 'text', kind: 'string', variable: true})
        expect(attributeTypeParse('citext')).toEqual({full: 'citext', kind: 'string', variable: true})
        expect(attributeTypeParse('tinytext')).toEqual({full: 'tinytext', kind: 'string', variable: true})
        expect(attributeTypeParse('mediumtext')).toEqual({full: 'mediumtext', kind: 'string', variable: true})
        expect(attributeTypeParse('longtext')).toEqual({full: 'longtext', kind: 'string', variable: true})
        expect(attributeTypeParse('tinyint')).toEqual({full: 'tinyint', kind: 'int', size: 1}) // SQL Server
        expect(attributeTypeParse('int2')).toEqual({full: 'int2', kind: 'int', size: 2})
        expect(attributeTypeParse('smallint')).toEqual({full: 'smallint', kind: 'int', size: 2})
        expect(attributeTypeParse('smallserial')).toEqual({full: 'smallserial', kind: 'int', size: 2})
        expect(attributeTypeParse('serial2')).toEqual({full: 'serial2', kind: 'int', size: 2})
        expect(attributeTypeParse('int')).toEqual({full: 'int', kind: 'int', size: 4})
        expect(attributeTypeParse('int4')).toEqual({full: 'int4', kind: 'int', size: 4})
        expect(attributeTypeParse('integer')).toEqual({full: 'integer', kind: 'int', size: 4})
        expect(attributeTypeParse('serial')).toEqual({full: 'serial', kind: 'int', size: 4})
        expect(attributeTypeParse('serial4')).toEqual({full: 'serial4', kind: 'int', size: 4})
        expect(attributeTypeParse('int8')).toEqual({full: 'int8', kind: 'int', size: 8})
        expect(attributeTypeParse('int64')).toEqual({full: 'int64', kind: 'int', size: 8}) // BigQuery
        expect(attributeTypeParse('bigint')).toEqual({full: 'bigint', kind: 'int', size: 8})
        expect(attributeTypeParse('bigint(20) unsigned')).toEqual({full: 'bigint(20) unsigned', kind: 'int', size: 8})
        expect(attributeTypeParse('serial8')).toEqual({full: 'serial8', kind: 'int', size: 8})
        expect(attributeTypeParse('bigserial')).toEqual({full: 'bigserial', kind: 'int', size: 8})
        expect(attributeTypeParse('real')).toEqual({full: 'real', kind: 'float', size: 4})
        expect(attributeTypeParse('float4')).toEqual({full: 'float4', kind: 'float', size: 4})
        expect(attributeTypeParse('float8')).toEqual({full: 'float8', kind: 'float', size: 8})
        expect(attributeTypeParse('double precision')).toEqual({full: 'double precision', kind: 'float', size: 8})
        expect(attributeTypeParse('decimal')).toEqual({full: 'decimal', kind: 'float'})
        expect(attributeTypeParse('decimal(2, 2)')).toEqual({full: 'decimal(2, 2)', kind: 'float'})
        expect(attributeTypeParse('numeric')).toEqual({full: 'numeric', kind: 'float'})
        expect(attributeTypeParse('numeric(2, 2)')).toEqual({full: 'numeric(2, 2)', kind: 'float'})
        expect(attributeTypeParse('number')).toEqual({full: 'number', kind: 'float'})
        expect(attributeTypeParse('number(2, 2)')).toEqual({full: 'number(2, 2)', kind: 'float'})
        expect(attributeTypeParse('bool')).toEqual({full: 'bool', kind: 'bool'})
        expect(attributeTypeParse('boolean')).toEqual({full: 'boolean', kind: 'bool'})
        expect(attributeTypeParse('date')).toEqual({full: 'date', kind: 'date', size: 4})
        expect(attributeTypeParse('time')).toEqual({full: 'time', kind: 'time', size: 8})
        expect(attributeTypeParse('timetz')).toEqual({full: 'timetz', kind: 'time', size: 12})
        expect(attributeTypeParse('time with time zone')).toEqual({full: 'time with time zone', kind: 'time', size: 12})
        expect(attributeTypeParse('time without time zone')).toEqual({full: 'time without time zone', kind: 'time', size: 8})
        expect(attributeTypeParse('timestamp')).toEqual({full: 'timestamp', kind: 'instant', size: 8})
        expect(attributeTypeParse('timestamptz')).toEqual({full: 'timestamptz', kind: 'instant', size: 8})
        expect(attributeTypeParse('timestamp with time zone')).toEqual({full: 'timestamp with time zone', kind: 'instant', size: 8})
        expect(attributeTypeParse('timestamp without time zone')).toEqual({full: 'timestamp without time zone', kind: 'instant', size: 8})
        expect(attributeTypeParse('timestamp(2) without time zone')).toEqual({full: 'timestamp(2) without time zone', kind: 'instant', size: 8})
        expect(attributeTypeParse('datetime')).toEqual({full: 'datetime', kind: 'instant'})
        expect(attributeTypeParse('interval')).toEqual({full: 'interval', kind: 'period', size: 16})
        expect(attributeTypeParse('interval(6)')).toEqual({full: 'interval(6)', kind: 'period', size: 16})
        expect(attributeTypeParse("interval '2 months ago'")).toEqual({full: "interval '2 months ago'", kind: 'period', size: 16})
        expect(attributeTypeParse("interval '2Y 3M 15D 18H 25M 32S'")).toEqual({full: "interval '2Y 3M 15D 18H 25M 32S'", kind: 'period', size: 16})
        expect(attributeTypeParse('bytea')).toEqual({full: 'bytea', kind: 'binary'})
        expect(attributeTypeParse('blob')).toEqual({full: 'blob', kind: 'binary', variable: true}) // MySQL
        expect(attributeTypeParse('tinyblob')).toEqual({full: 'tinyblob', kind: 'binary', variable: true}) // MySQL
        expect(attributeTypeParse('mediumblob')).toEqual({full: 'mediumblob', kind: 'binary', variable: true}) // MySQL
        expect(attributeTypeParse('longblob')).toEqual({full: 'longblob', kind: 'binary', variable: true}) // MySQL
        expect(attributeTypeParse('uuid')).toEqual({full: 'uuid', kind: 'uuid'})
        expect(attributeTypeParse('json')).toEqual({full: 'json', kind: 'json'})
        expect(attributeTypeParse('jsonb')).toEqual({full: 'jsonb', kind: 'json'})
        expect(attributeTypeParse('xml')).toEqual({full: 'xml', kind: 'xml'})
        expect(attributeTypeParse('int[]')).toEqual({full: 'int', kind: 'int', size: 4, array: true})
        expect(attributeTypeParse('character varying(255)[]')).toEqual({full: 'character varying(255)', kind: 'string', size: 255, variable: true, array: true})
        expect(attributeTypeParse('array<string(12)>')).toEqual({full: 'string(12)', kind: 'string', size: 12, array: true}) // BigQuery
        expect(attributeTypeParse('cidr')).toEqual({full: 'cidr', kind: 'unknown'}) // IPv4 or IPv6 network address
        expect(attributeTypeParse('inet')).toEqual({full: 'inet', kind: 'unknown'}) // IPv4 or IPv6 host address
        expect(attributeTypeParse('macaddr')).toEqual({full: 'macaddr', kind: 'unknown'}) // MAC address
        expect(attributeTypeParse('macaddr8')).toEqual({full: 'macaddr8', kind: 'unknown'}) // MAC address
        expect(attributeTypeParse('money')).toEqual({full: 'money', kind: 'unknown'}) // currency amount
        expect(attributeTypeParse('point')).toEqual({full: 'point', kind: 'unknown'}) // geometric point on a plane
        expect(attributeTypeParse('line')).toEqual({full: 'line', kind: 'unknown'}) // infinite line on a plane
        expect(attributeTypeParse('lseg')).toEqual({full: 'lseg', kind: 'unknown'}) // line segment on a plane
        expect(attributeTypeParse('box')).toEqual({full: 'box', kind: 'unknown'}) // rectangular box on a plane
        expect(attributeTypeParse('circle')).toEqual({full: 'circle', kind: 'unknown'}) // circle on a plane
        expect(attributeTypeParse('path')).toEqual({full: 'path', kind: 'unknown'}) // geometric path on a plane
        expect(attributeTypeParse('polygon')).toEqual({full: 'polygon', kind: 'unknown'}) // closed geometric path on a plane
        expect(attributeTypeParse('tsquery')).toEqual({full: 'tsquery', kind: 'unknown'})
        expect(attributeTypeParse('tsvector')).toEqual({full: 'tsvector', kind: 'unknown'})
        expect(attributeTypeParse('txid_snapshot')).toEqual({full: 'txid_snapshot', kind: 'unknown'})
        expect(attributeTypeParse('pg_lsn')).toEqual({full: 'pg_lsn', kind: 'unknown'})
        expect(attributeTypeParse('pg_snapshot')).toEqual({full: 'pg_snapshot', kind: 'unknown'})
        expect(attributeTypeParse('bad')).toEqual({full: 'bad', kind: 'unknown'})
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
    test('flattenAttributes', () => {
        expect(flattenAttributes(undefined)).toEqual([])
        expect(flattenAttributes([])).toEqual([])
        expect(flattenAttributes([{name: 'id', type: 'uuid'}])).toEqual([{path: ['id'], name: 'id', type: 'uuid'}])
        expect(flattenAttributes([{name: 'details', type: 'json', attrs: [{name: 'address', type: 'varchar'}]}])).toEqual([
            {path: ['details'], name: 'details', type: 'json', attrs: [{name: 'address', type: 'varchar'}]},
            {path: ['details', 'address'], name: 'address', type: 'varchar'},
        ])
        expect(flattenAttributes([{name: 'details', type: 'json', attrs: [
            {name: 'twitter', type: 'varchar'},
            {name: 'address', type: 'json', attrs: [
                {name: 'street', type: 'varchar'},
                {name: 'city', type: 'varchar'},
            ]},
            {name: 'created', type: 'varchar'},
        ]}])).toEqual([
            {path: ['details'], name: 'details', type: 'json', attrs: [
                {name: 'twitter', type: 'varchar'},
                {name: 'address', type: 'json', attrs: [
                    {name: 'street', type: 'varchar'},
                    {name: 'city', type: 'varchar'},
                ]},
                {name: 'created', type: 'varchar'},
            ]},
            {path: ['details', 'twitter'], name: 'twitter', type: 'varchar'},
            {path: ['details', 'address'], name: 'address', type: 'json', attrs: [
                {name: 'street', type: 'varchar'},
                {name: 'city', type: 'varchar'},
            ]},
            {path: ['details', 'address', 'street'], name: 'street', type: 'varchar'},
            {path: ['details', 'address', 'city'], name: 'city', type: 'varchar'},
            {path: ['details', 'created'], name: 'created', type: 'varchar'},
        ])
    })
    test('attributeValueToString', () => {
        expect(attributeValueToString('str')).toEqual('str')
        expect(attributeValueToString(42)).toEqual('42')
        expect(attributeValueToString(BigInt(42))).toEqual('42')
        expect(attributeValueToString(NaN)).toEqual('NaN')
        expect(attributeValueToString(Infinity)).toEqual('Infinity')
        expect(attributeValueToString(true)).toEqual('true')
        expect(attributeValueToString(new String('str'))).toEqual('str')
        expect(attributeValueToString(new Number(42))).toEqual('42')
        expect(attributeValueToString(new Boolean(true))).toEqual('true')
        expect(attributeValueToString(new Date(1739896885465))).toEqual('2025-02-18T16:41:25.465Z')
        expect(attributeValueToString(new Date('bad'))).toEqual('null')
    })
    test('parseJsonDatabase', () => {
        expect(parseJsonDatabase(`{}`)).toEqual({result: {}})
        expect(parseJsonDatabase(`{"entities": [{"name": "users"}, {"name": "posts"}]}`)).toEqual({result: {entities: [{name: 'users'}, {name: 'posts'}]}})
        expect(parseJsonDatabase(`{"bad": 1}`)).toEqual({errors: [{message: "Invalid Database, at _root_: invalid additional key 'bad' (1)", kind: 'InvalidJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}]})
        expect(parseJsonDatabase(`{"entities": [{"name": true}]}`)).toEqual({errors: [{message: "Invalid Database, at .entities.0.name: expect 'string' but got 'boolean' (true)", kind: 'InvalidJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}]})
        // expect(databaseJsonParse(`bad`)).toEqual({errors: [{message: "Unexpected token 'b', \"bad\" is not valid JSON", kind: 'MalformedJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}]})
        // expect(databaseJsonParse(`bad`)).toEqual({errors: [{message: "Unexpected token b in JSON at position 0", kind: 'MalformedJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}]})
    })
    test('generateJsonDatabase', () => {
        const prettyJson = generateJsonDatabase({
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'user_role', default: 'guest'},
                    {name: 'settings', type: 'json', attrs: [
                        {name: 'github', type: 'string'},
                        {name: 'twitter', type: 'string'},
                    ]},
                ],
                pk: {name: 'users_pk', attrs: [['id']]},
                indexes: [{name: 'user_name_idx', attrs: [['name']]}],
                checks: [{name: 'user_role_chk', attrs: [['role']], predicate: 'role in ("admin", "guest")'}]
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar'},
                    {name: 'created_by', type: 'int'},
                ],
                indexes: []
            }, {
                name: 'admins',
                kind: 'view',
                def: `SELECT *\nFROM users\nWHERE role='admin';`,
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'varchar'},
                ]
            }],
            relations: [{
                name: 'posts_created_by_fk',
                src: {entity: 'posts', attrs: [['created_by']]},
                ref: {entity: 'users', attrs: [['id']]},
            }],
            types: [{name: 'user_role', values: ['admin', 'guest']}],
            doc: 'CMS database',
            stats: {name: 'cms', kind: DatabaseKind.Enum.postgres, version: '1.2.3'},
            extra: {comment: 'great!', statements: [{id: 1, kind: 'INSERT'}, {id: 2, kind: 'SELECT'}]}
        })
        expect(prettyJson).toEqual(`{
  "entities": [
    {
      "name": "users",
      "attrs": [
        {"name": "id", "type": "int"},
        {"name": "name", "type": "varchar"},
        {"name": "role", "type": "user_role", "default": "guest"},
        {"name": "settings", "type": "json", "attrs": [
          {"name": "github", "type": "string"},
          {"name": "twitter", "type": "string"}
        ]}
      ],
      "pk": {"name": "users_pk", "attrs": [["id"]]},
      "indexes": [
        {"name": "user_name_idx", "attrs": [["name"]]}
      ],
      "checks": [
        {"name": "user_role_chk", "attrs": [["role"]], "predicate": "role in (\\"admin\\", \\"guest\\")"}
      ]
    },
    {
      "name": "posts",
      "attrs": [
        {"name": "id", "type": "int"},
        {"name": "title", "type": "varchar"},
        {"name": "created_by", "type": "int"}
      ],
      "indexes": []
    },
    {
      "name": "admins",
      "kind": "view",
      "def": "SELECT *\\nFROM users\\nWHERE role='admin';",
      "attrs": [
        {"name": "id", "type": "int"},
        {"name": "name", "type": "varchar"},
        {"name": "role", "type": "varchar"}
      ]
    }
  ],
  "relations": [
    {
      "name": "posts_created_by_fk",
      "src": {"entity": "posts", "attrs": [["created_by"]]},
      "ref": {"entity": "users", "attrs": [["id"]]}
    }
  ],
  "types": [
    {"name": "user_role", "values": ["admin", "guest"]}
  ],
  "doc": "CMS database",
  "stats": {"name": "cms", "kind": "postgres", "version": "1.2.3"},
  "extra": {
    "comment": "great!",
    "statements": [
      {
        "id": 1,
        "kind": "INSERT"
      },
      {
        "id": 2,
        "kind": "SELECT"
      }
    ]
  }
}
`)
    })
})
