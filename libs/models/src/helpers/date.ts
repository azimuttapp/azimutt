import {Duration, Timestamp} from "../common";

export const oneSecond: Duration = 1000
export const oneMinute: Duration = 60 * oneSecond
export const oneHour: Duration = 60 * oneMinute
export const oneDay: Duration = 24 * oneHour
export const oneWeek: Duration = 7 * oneDay
export const oneMonth: Duration = 30 * oneDay
export const oneYear: Duration = 365 * oneDay

export function showDate(date: Timestamp): string {
    return `${new Date(date).toISOString().split('T')[0]}`
}
