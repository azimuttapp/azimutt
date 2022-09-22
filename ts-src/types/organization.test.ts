import {Organization, OrganizationPlan} from "./organization";

describe('organization', () => {
    const organization: Organization = {
        id: '84547c71-bec5-433b-87c7-685f1c9353b2',
        slug: 'valid',
        name: 'Valid',
        activePlan: OrganizationPlan.enum.free,
        logo: 'https://azimutt.app/logo.png',
        location: 'Paris',
        description: 'bla bla bla'
    }
    test('zod full', () => {
        const res: Organization = Organization.parse(organization) // make sure parser result is aligned with TS type!
        expect(res).toEqual(organization)
    })
    test('zod empty', () => {
        const valid: Organization = {...organization, activePlan: OrganizationPlan.enum.pro, location: null, description: null}
        const res: Organization = Organization.parse(valid)
        expect(res).toEqual(valid)
    })
    test('zod invalid', () => {
        const {location, ...invalid} = organization
        const res = Organization.safeParse(invalid)
        expect(res.success).toEqual(false)
    })
})
