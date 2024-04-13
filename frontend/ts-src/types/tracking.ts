import {z} from "zod";
import {LegacyOrganizationId, LegacyProjectId} from "@azimutt/database-model";

export type TrackDetails = { [key: string]: string | number | boolean | null };
export const TrackDetails = z.record(z.union([z.string(), z.number(), z.boolean(), z.null()]))

export interface TrackEvent {
    name: string
    details?: TrackDetails
    organization?: LegacyOrganizationId
    project?: LegacyProjectId
}

export const TrackEvent = z.object({
    name: z.string(),
    details: TrackDetails.optional(),
    organization: LegacyOrganizationId.optional(),
    project: LegacyProjectId.optional()
}).strict()
