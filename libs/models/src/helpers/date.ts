import {Duration, Timestamp} from "../common";

export const oneSecond: Duration = 1000
export const oneMinute: Duration = 60 * 1000
export const oneHour: Duration = 60 * 60 * 1000
export const oneDay: Duration = 24 * 60 * 60 * 1000

export function showDate(date: Timestamp): string {
    return `${new Date(date).toISOString().split('T')[0]}`
}
