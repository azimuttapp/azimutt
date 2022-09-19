import {Uuid, zero} from "./uuid";
import {Slug} from "./basics";

export type OrganizationId = Uuid
export type OrganizationSlug = Slug
export type OrganizationPlan = 'free' | 'pro'
export const OrganizationPlan: { [key in OrganizationPlan]: key } = {
    free: 'free',
    pro: 'pro'
}

export function validPlan(value: string): OrganizationPlan {
    if (value === OrganizationPlan.free) {
        return OrganizationPlan.free
    } else if (value === OrganizationPlan.pro) {
        return OrganizationPlan.pro
    } else {
        throw `Invalid plan ${JSON.stringify(value)}`
    }
}

export interface Organization {
    id: OrganizationId
    slug: OrganizationSlug
    name: string
    activePlan: OrganizationPlan
    logo: string
    location: string | null
    description: string | null
}

export const legacy = {
    id: zero,
    slug: zero,
    name: 'Legacy',
    activePlan: OrganizationPlan.free,
    logo: 'https://azimutt.app/logo.png',
    location: null,
    description: null
}
