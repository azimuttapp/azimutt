import {describe, expect, test} from "@jest/globals";
import {z} from "zod";
import {zodParse} from "./zod";

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
    }).strict().describe('User')
    const File = z.discriminatedUnion('kind', [
        z.object({kind: z.literal('local'), path: z.string()}).strict(),
        z.object({kind: z.literal('remote'), url: z.string()}).strict()
    ]).describe('File')
    const Position = z.union([
        z.object({width: z.number(), height: z.number()}).strict(),
        z.object({left: z.number(), top: z.number()}).strict(),
        z.object({x: z.number(), y: z.number()}).strict()
    ]).describe('Position')

    describe('zodParse', () => {
        test('additional keys', () => {
            const data = {...user, fullname: 'Loïc'}
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at _root_: invalid additional key 'fullname' (\"Loïc\")"})
        })
        test('required', () => {
            const {id, ...data} = user
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at .id: expect 'number' but got 'undefined' ()"})
        })
        test('bad type', () => {
            const data = {...user, name: 2}
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at .name: expect 'string' but got 'number' (2)"})
        })
        test('nested error', () => {
            const data = {...user, org: {...user.org, admin: {...user.org.admin, name: true}}}
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at .org.admin.name: expect 'string' but got 'boolean' (true)"})
        })
        test('invalid literal', () => {
            const data = {...user, version: 2}
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at .version: expect 1 but got 2"})
        })
        test('invalid enum', () => {
            const data = {...user, roles: ['guest', 'troll', 'admin']}
            expect(zodParse(User)(data as any).toJson()).toEqual({failure: "Invalid User, at .roles.1: expect `\"guest\" | \"admin\"` but got \"troll\""})
        })
        test('invalid discriminated union', () => {
            const data = {kind: 'bad'}
            expect(zodParse(File)(data as any).toJson()).toEqual({failure: "Invalid File, at .kind: expect `\"local\" | \"remote\"` but got \"bad\""})
        })
        test('invalid union', () => {
            const data = {dx: 0, dy: 0}
            expect(zodParse(Position)(data as any).toJson()).toEqual({failure: "Invalid Position, at _root_: invalid union for {\"dx\":0,\"dy\":0}"})
        })
    })
})
