import {z} from "zod";
import {prettyNumber} from "@azimutt/utils";

export const Bytes = z.number() // number of bytes
export type Bytes = z.infer<typeof Bytes>

export const Ko: Bytes = 1000
export const Mo: Bytes = 1000 * Ko
export const Go: Bytes = 1000 * Mo
export const To: Bytes = 1000 * Go
export const Po: Bytes = 1000 * To

export function showBytes(bytes: Bytes): string {
    if (bytes > Po) return `${prettyNumber(bytes / Po)} Po`
    if (bytes > To) return `${prettyNumber(bytes / To)} To`
    if (bytes > Go) return `${prettyNumber(bytes / Go)} Go`
    if (bytes > Mo) return `${prettyNumber(bytes / Mo)} Mo`
    if (bytes > Ko) return `${prettyNumber(bytes / Ko)} ko`
    return `${Math.round(bytes)} bytes`
}
