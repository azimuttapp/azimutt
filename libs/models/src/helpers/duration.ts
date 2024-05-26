import {z} from "zod";

export const Duration = z.number() // in millis
export type Duration = z.infer<typeof Duration>

export const oneSecond: Duration = 1000
export const oneMinute: Duration = 60 * oneSecond
export const oneHour: Duration = 60 * oneMinute
export const oneDay: Duration = 24 * oneHour
export const oneWeek: Duration = 7 * oneDay
export const oneMonth: Duration = 30 * oneDay
export const oneYear: Duration = 365 * oneDay

export function showDuration(millis: Duration): string {
    if (millis > 2 * 365 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 365)} years`
    } else if (millis > 2 * 30 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 30)} months`
    } else if (millis > 2 * 7 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 7)} weeks`
    } else if (millis > 2 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24)} days`
    } else if (millis > 2 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60)} hours`
    } else if (millis > 2 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60)} mins`
    } else if (millis > 10 * 1000) {
        return `${Math.round(millis / 1000)} secs`
    } else {
        return `${Math.round(millis)} ms`
    }
}
