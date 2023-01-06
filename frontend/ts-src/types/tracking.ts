import {ProjectId} from "./project";
import {z} from "zod";
import {OrganizationId} from "./organization";

export type TrackDetails = { [key: string]: string | number | boolean | null };
export const TrackDetails = z.record(z.union([z.string(), z.number(), z.boolean(), z.null()]))

export interface TrackEvent {
    name: string
    details?: TrackDetails
    organization?: OrganizationId
    project?: ProjectId
}

export const TrackEvent = z.object({
    name: z.string(),
    details: TrackDetails.optional(),
    organization: OrganizationId.optional(),
    project: ProjectId.optional()
}).strict()
