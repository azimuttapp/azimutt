import {z} from "zod";

export type Env = 'dev' | 'staging' | 'prod'
export const Env = z.enum(['dev', 'staging', 'prod'])

export function getEnv(): Env {
    if (window.location.hostname.endsWith('localhost')) {
        return Env.enum.dev
    } else if (window.location.hostname.endsWith('azimutt.dev')) {
        return Env.enum.staging
    } else {
        return Env.enum.prod
    }
}
