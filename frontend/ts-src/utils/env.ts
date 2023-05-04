import {z} from "zod";

export type Env = 'dev' | 'staging' | 'prod'
export const Env = z.enum(['dev', 'staging', 'prod'])
