import {Organization} from "./organization";
import {organization} from "../utils/constants.test";

describe('organization', () => {
    test('zod full', () => {
        const res: Organization = Organization.parse(organization) // make sure parser result is aligned with TS type!
        expect(res).toEqual(organization)
    })
    test('zod empty', () => {
        const valid: Organization = {...organization, location: undefined, description: undefined}
        const res: Organization = Organization.parse(valid)
        expect(res).toEqual(valid)
    })
    test('zod invalid', () => {
        const {slug, ...invalid} = organization
        const res = Organization.safeParse(invalid)
        expect(res.success).toEqual(false)
    })
})
