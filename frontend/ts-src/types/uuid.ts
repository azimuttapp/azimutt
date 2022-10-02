import {z} from "zod";

export type Uuid = string
export const Uuid = z.string().uuid()

export const zero: Uuid = "00000000-0000-0000-0000-000000000000"
