import {Uuid} from "./uuid";
import {Slug} from "./basics";
import {z} from "zod";

export type OrganizationId = Uuid
export const OrganizationId = Uuid
export type OrganizationSlug = Slug
export const OrganizationSlug = Slug
export type OrganizationName = string
export const OrganizationName = z.string()
export type OrganizationPlan = 'free' | 'pro'
export const OrganizationPlan = z.enum(['free', 'pro'])

export interface Organization {
    id: OrganizationId
    slug: OrganizationSlug
    name: OrganizationName
    activePlan: OrganizationPlan
    logo: string
    location?: string
    description?: string
}

export const Organization = z.object({
    id: OrganizationId,
    slug: OrganizationSlug,
    name: OrganizationName,
    activePlan: OrganizationPlan,
    logo: z.string().url(),
    location: z.string().optional(),
    description: z.string().optional(),
}).strict()
