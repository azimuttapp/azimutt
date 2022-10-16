import {z} from "zod";
import {errorToString} from "./zod";
import {SafeParseReturnType} from "zod/lib/types";

describe('zod', () => {
    const user = {id: 1, name: 'Loïc', roles: ['admin'], org: {id: 1, name: 'Azimutt', admin: {id: 1, name: 'Loïc'}}, version: 1}
    const User = z.object({
        id: z.number(),
        name: z.string().optional(),
        roles: z.enum(['guest', 'admin']).array(),
        org: z.object({
            id: z.number(),
            name: z.string(),
            admin: z.object({
                id: z.number(),
                name: z.string(),
            })
        }),
        version: z.literal(1)
    }).strict()
    const File = z.discriminatedUnion('kind', [
        z.object({kind: z.literal('local'), path: z.string()}).strict(),
        z.object({kind: z.literal('remote'), url: z.string()}).strict()
    ])
    const Position = z.union([
        z.object({width: z.number(), height: z.number()}).strict(),
        z.object({left: z.number(), top: z.number()}).strict(),
        z.object({x: z.number(), y: z.number()}).strict()
    ])

    describe('toString', () => {
        test('additional keys', () => {
            const data = {...user, fullname: 'Loïc'}
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at _root_: invalid additional key 'fullname' (\"Loïc\")")
        })
        test('required', () => {
            const {id, ...data} = user
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .id: expect 'number' but got 'undefined' (undefined)")
        })
        test('bad type', () => {
            const data = {...user, name: 2}
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .name: expect 'string' but got 'number' (2)")
        })
        test('nested error', () => {
            const data = {...user, org: {...user.org, admin: {...user.org.admin, name: true}}}
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .org.admin.name: expect 'string' but got 'boolean' (true)")
        })
        test('invalid literal', () => {
            const data = {...user, version: 2}
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .version: expect 1 but got 2")
        })
        test('invalid enum', () => {
            const data = {...user, roles: ['guest', 'troll', 'admin']}
            const error = getError(data, User.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .roles.1: expect `\"guest\" | \"admin\"` but got \"troll\"")
        })
        test('invalid discriminated union', () => {
            const data = {kind: 'bad'}
            const error = getError(data, File.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at .kind: expect `\"local\" | \"remote\"` but got \"bad\"")
        })
        test('invalid union', () => {
            const data = {dx: 0, dy: 0}
            const error = getError(data, Position.safeParse(data))
            expect(error).toEqual("1 validation error:\n - at _root_: invalid union for {\"dx\":0,\"dy\":0}")
        })
    })

    function getError<Input, Output>(data: any, res: SafeParseReturnType<Input, Output>): string {
        if (res.success) {
            throw 'Failure expected!'
        } else {
            return errorToString(data, res.error)
        }
    }
})
