import {z} from "zod";
import "openai/shims/web"; // FIXME 'web' fails on frontend/ts-src/types/ports.test.disabled.ts tests :/
import OpenAI from "openai";

// create a key: https://platform.openai.com/api-keys
export const OpenAIKey = z.string()
export type OpenAIKey = z.infer<typeof OpenAIKey>

export const OpenAIModel = z.enum(['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'])
export type OpenAIModel = z.infer<typeof OpenAIModel>

export class OpenAIConnector {
    private openai: OpenAI

    constructor(private opts: { apiKey: OpenAIKey, model: OpenAIModel }) {
        this.openai = new OpenAI({apiKey: opts.apiKey, dangerouslyAllowBrowser: true})
    }

    query = async (system: string, user: string): Promise<string> => {
        // console.log(`system: ${system}`)
        // console.log(`user: ${user}`)
        // https://platform.openai.com/docs/api-reference/chat/create
        const completion = await this.openai.chat.completions.create({
            model: this.opts.model,
            messages: [
                {role: 'system' as const, content: system},
                {role: 'user' as const, content: user},
            ].filter(m => m.content),
        })
        const answer = completion.choices?.[0].message.content
        // console.log(`answer ${this.opts.model}: ${answer}`)
        return answer || 'Invalid LLM answer :/'
    }
}
