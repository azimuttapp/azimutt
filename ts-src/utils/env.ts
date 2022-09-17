export type Env = 'dev' | 'staging' | 'prod'
export const Env: { [key in Env]: key } = {
    dev: 'dev',
    staging: 'staging',
    prod: 'prod'
}

export function getEnv(): Env {
    if (window.location.hostname.endsWith('localhost')) {
        return Env.dev
    } else if (window.location.hostname.endsWith('azimutt.dev')) {
        return Env.staging
    } else if (window.location.hostname.endsWith('azimutt.app')) {
        return Env.prod
    } else {
        throw `Invalid hostname '${window.location.hostname}'`
    }
}
