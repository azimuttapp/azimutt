import {Uuid} from "./uuid";
import {Slug} from "./basics";

export type OrganizationId = Uuid
export type OrganizationSlug = Slug

export interface Organization {
    id: OrganizationId
    slug: OrganizationSlug
    name: string
    activePlan: string
    logo: string
    location: string | null
    description: string | null
}
