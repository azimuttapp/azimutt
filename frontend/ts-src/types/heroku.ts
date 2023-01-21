import {Uuid} from "./uuid";
import {z} from "zod";

export type HerokuId = Uuid
export const HerokuId = Uuid

export interface HerokuResource {
    id: HerokuId
}

export const HerokuResource = z.object({
    id: HerokuId
}).strict()
