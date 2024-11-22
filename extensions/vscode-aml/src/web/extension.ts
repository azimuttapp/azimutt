// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
	const fromJson = vscode.commands.registerCommand('vscode-aml.fromJson', () => {
		vscode.window.showInformationMessage('Convert JSON to AML')
	})
	const fromSQL = vscode.commands.registerCommand('vscode-aml.fromSQL', () => {
		vscode.window.showInformationMessage('Convert SQL to AML')
	})
	const convert = vscode.commands.registerCommand('vscode-aml.convert', () => {
		vscode.window.showInformationMessage('Convert AML')
	})

	context.subscriptions.push(fromJson)
	context.subscriptions.push(fromSQL)
	context.subscriptions.push(convert)
}

// This method is called when your extension is deactivated
export function deactivate() {}
