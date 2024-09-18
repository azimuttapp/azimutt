import {z} from "zod";

export const Uuid = z.string().uuid()
export type Uuid = z.infer<typeof Uuid>

export const Slug = z.string()
export type Slug = z.infer<typeof Slug>

export const Markdown = z.string()
export type Markdown = z.infer<typeof Markdown>

export const Percent = z.number()
export type Percent = z.infer<typeof Percent>

export const Millis = z.number() // milli-seconds
export type Millis = z.infer<typeof Millis>

export const Timestamp = z.number() // timestamp in millis (ex: 1663007946750)
export type Timestamp = z.infer<typeof Timestamp>

export const DateTime = z.string().datetime() // date in iso format ("2022-09-12T11:13:02.611616Z")
export type DateTime = z.infer<typeof DateTime>

export const Color = z.enum(['gray', 'red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose'])
export type Color = z.infer<typeof Color>

export const Px = z.number() // number of pixels
export type Px = z.infer<typeof Px>

export const Position = z.object({left: Px, top: Px}).strict()
export type Position = z.infer<typeof Position>

export const Size = z.object({width: Px, height: Px}).strict()
export type Size = z.infer<typeof Size>

export const Delta = z.object({dx: z.number(), dy: z.number()}).strict()
export type Delta = z.infer<typeof Delta>

export const SqlScript = z.string() // a whole SQL script with several queries inside
export type SqlScript = z.infer<typeof SqlScript>

export const SqlStatement = z.string() // a single and complete SQL statement
export type SqlStatement = z.infer<typeof SqlStatement>

export const SqlFragment = z.string() // a part of SQL, can be used to build a bigger query
export type SqlFragment = z.infer<typeof SqlFragment>

export const JsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null()])
export type JsValueLiteral = z.infer<typeof JsValueLiteral>
export const JsValue: z.ZodType<JsValue> = z.lazy(() => z.union([JsValueLiteral, z.array(JsValue), z.record(JsValue)]))
export type JsValue = JsValueLiteral | { [key: string]: JsValue } | JsValue[] // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
