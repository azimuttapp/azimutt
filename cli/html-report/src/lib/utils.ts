import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function plural(word: string): string {
  if (
    word.endsWith("y") &&
    !(
      word.endsWith("ay") ||
      word.endsWith("ey") ||
      word.endsWith("oy") ||
      word.endsWith("uy")
    )
  ) {
    return word.slice(0, -1) + "ies"
  } else if (
    word.endsWith("s") ||
    word.endsWith("x") ||
    word.endsWith("z") ||
    word.endsWith("sh") ||
    word.endsWith("ch")
  ) {
    return word + "es"
  } else {
    return word + "s"
  }
}

export function pluralize(count: number, word: string): string {
  if (count === 1) {
    return `1 ${word}`
  } else {
    return `${count} ${plural(word)}`
  }
}
