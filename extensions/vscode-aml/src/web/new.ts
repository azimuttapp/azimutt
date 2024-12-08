import * as vscode from "vscode";
import {openFile} from "./utils";

const amlLib = import("@azimutt/aml");

export async function newAml(): Promise<void> {
    const amlSamples = (await amlLib).samples
    const samples: { name: string, content: string }[] = Object.values(amlSamples)
    const sampleName = await vscode.window.showQuickPick(samples.map(s => s.name), {placeHolder: 'Select AML sample'})
    const sample = samples.find(s => s.name === sampleName) || amlSamples.blogBasic
    await openFile('aml', sample.content)
}
