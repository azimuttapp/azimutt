import {Uuid} from "./uuid";
import {Slug} from "./basics";
import {z} from "zod";
import {HerokuResource} from "./heroku";

export type OrganizationId = Uuid
export const OrganizationId = Uuid
export type OrganizationSlug = Slug
export const OrganizationSlug = Slug
export type OrganizationName = string
export const OrganizationName = z.string()
export type PlanId = 'free' | 'team'
export const PlanId = z.enum(['free', 'team'])

export interface Plan {
    id: PlanId
    name: string
    layouts: number | null
    colors: boolean
    db_analysis: boolean
    db_access: boolean
}

export const Plan = z.object({
    id: PlanId,
    name: z.string(),
    layouts: z.number().nullable(),
    colors: z.boolean(),
    db_analysis: z.boolean(),
    db_access: z.boolean()
}).strict()

export interface Organization {
    id: OrganizationId
    slug: OrganizationSlug
    name: OrganizationName
    plan: Plan
    logo: string
    location?: string
    description?: string
    heroku?: HerokuResource
}

export const Organization = z.object({
    id: OrganizationId,
    slug: OrganizationSlug,
    name: OrganizationName,
    plan: Plan,
    logo: z.string().url(),
    location: z.string().optional(),
    description: z.string().optional(),
    heroku: HerokuResource.optional(),
}).strict()
