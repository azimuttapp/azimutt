import {z} from "zod";

export const Uuid = z.string().uuid()
export type Uuid = z.infer<typeof Uuid>
export const Markdown = z.string()
export type Markdown = z.infer<typeof Markdown>
export const Millis = z.number() // milli-seconds
export type Millis = z.infer<typeof Millis>
