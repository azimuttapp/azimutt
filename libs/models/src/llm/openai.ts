import OpenAI from "openai";
import {Logger} from "@azimutt/utils";

// create a key: https://platform.openai.com/api-keys
export class OpenAIConnector {
    private openai: OpenAI

    constructor(private opts: { apiKey: string, model: string, logger: Logger }) {
        this.openai = new OpenAI({apiKey: opts.apiKey, dangerouslyAllowBrowser: true})
    }

    query = async (system: string, user: string): Promise<string> => {
        this.opts.logger.debug(`system: ${system}`)
        this.opts.logger.debug(`user: ${user}`)
        // https://platform.openai.com/docs/api-reference/chat/create
        const completion = await this.openai.chat.completions.create({
            model: this.opts.model,
            messages: [
                {role: 'system' as const, content: system},
                {role: 'user' as const, content: user},
            ].filter(m => m.content),
        })
        return completion.choices?.[0].message.content || 'Invalid LLM answer :/'
    }
}
