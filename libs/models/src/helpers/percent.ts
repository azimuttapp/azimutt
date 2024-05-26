import {Percent} from "../common";

export function computePercent(start: number, end: number): Percent {
    return (end - start) / start
}

export function showPercent(pc: Percent): string {
    return `${Math.round(pc * 100)}%`
}
