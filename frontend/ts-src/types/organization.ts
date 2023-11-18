import {Uuid} from "./uuid";
import {Slug} from "./basics";
import {z} from "zod";
import {CleverCloudResource} from "./clevercloud";
import {HerokuResource} from "./heroku";

export type OrganizationId = Uuid
export const OrganizationId = Uuid
export type OrganizationSlug = Slug
export const OrganizationSlug = Slug
export type OrganizationName = string
export const OrganizationName = z.string()
export type PlanId = 'free' | 'pro'
export const PlanId = z.enum(['free', 'pro'])

// MUST stay in sync with frontend/src/Models/Plan.elm & backend/lib/azimutt/organizations/organization_plan.ex
export interface Plan {
    id: PlanId
    name: string
    layouts: number | null
    memos: number | null
    groups: number | null
    colors: boolean
    private_links: boolean
    sql_export: boolean
    db_analysis: boolean
    db_access: boolean
    streak: number
}

export const Plan = z.object({
    id: PlanId,
    name: z.string(),
    layouts: z.number().nullable(),
    memos: z.number().nullable(),
    groups: z.number().nullable(),
    colors: z.boolean(),
    private_links: z.boolean(),
    sql_export: z.boolean(),
    db_analysis: z.boolean(),
    db_access: z.boolean(),
    streak: z.number(),
}).strict()

export interface Organization {
    id: OrganizationId
    slug: OrganizationSlug
    name: OrganizationName
    plan: Plan
    logo: string
    description?: string
    clever_cloud?: CleverCloudResource
    heroku?: HerokuResource
}

export const Organization = z.object({
    id: OrganizationId,
    slug: OrganizationSlug,
    name: OrganizationName,
    plan: Plan,
    logo: z.string().url(),
    description: z.string().optional(),
    clever_cloud: CleverCloudResource.optional(),
    heroku: HerokuResource.optional(),
}).strict()
