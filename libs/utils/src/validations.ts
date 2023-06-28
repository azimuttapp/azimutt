export const isObject = (value: unknown): value is Record<string, any> => typeof value === "object" && !Array.isArray(value) && value !== null;
