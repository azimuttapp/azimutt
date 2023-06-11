import {describe, expect, test} from "@jest/globals";
import * as fs from "fs";
import {formatSchema, parseSchema} from "../src";

describe('prisma', () => {
    test('test', () => {
        const prismaSchema = fs.readFileSync('tests/resources/schema1.prisma', {encoding: 'utf8', flag: 'r'})
        // console.log('prismaSchema', prismaSchema)
        const prismaAst = parseSchema(prismaSchema)
        fs.writeFileSync('tests/resources/schema1.prisma.json', JSON.stringify(prismaAst, null, 2))
        // console.log('prismaAst', prismaAst)
        const azimuttSchema = formatSchema(prismaAst)
        fs.writeFileSync('tests/resources/schema1.azimutt.json', JSON.stringify(azimuttSchema, null, 2))
        console.log('azimuttSchema', azimuttSchema)
        expect(1 + 1).toEqual(2)
    })
})
