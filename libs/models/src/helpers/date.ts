import {Duration, Timestamp} from "../common";

export const oneDay: Duration = 24 * 60 * 60 * 1000

export function showDate(date: Timestamp): string {
    return `${new Date(date).toISOString().split('T')[0]}`
}
