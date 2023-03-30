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
export type PlanId = 'free' | 'pro'
export const PlanId = z.enum(['free', 'pro'])

export interface Plan {
    id: PlanId
    name: string
    layouts: number | null
    memos: number | null
    colors: boolean
    private_links: boolean
    sql_export: boolean
    db_analysis: boolean
    db_access: boolean
}

export const Plan = z.object({
    id: PlanId,
    name: z.string(),
    layouts: z.number().nullable(),
    memos: z.number().nullable(),
    colors: z.boolean(),
    private_links: z.boolean(),
    sql_export: z.boolean(),
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
