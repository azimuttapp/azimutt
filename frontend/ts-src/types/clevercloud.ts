import {Uuid} from "./uuid";
import {z} from "zod";

export type CleverCloudId = Uuid
export const CleverCloudId = Uuid

export interface CleverCloudResource {
    id: CleverCloudId
}

export const CleverCloudResource = z.object({
    id: CleverCloudId
}).strict()
