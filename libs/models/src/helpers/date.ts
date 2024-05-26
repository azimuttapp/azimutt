import {Timestamp} from "../common";

export function showDate(date: Timestamp): string {
    return `${new Date(date).toISOString().split('T')[0]}`
}
