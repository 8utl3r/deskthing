# Cursor Status Bar Extension

To create a proper status bar item in Cursor, you can create a simple VS Code extension.

## Quick Setup

1. Install VS Code Extension Generator:
```bash
npm install -g yo generator-code
```

2. Create extension:
```bash
mkdir -p ~/cursor-extensions/auto-commit-status
cd ~/cursor-extensions/auto-commit-status
yo code
# Select: New Extension (TypeScript)
# Name: auto-commit-status
# Identifier: auto-commit-status
# Description: Shows auto-commit watcher status
```

3. Replace `src/extension.ts` with:

```typescript
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

let statusBarItem: vscode.StatusBarItem;
let statusUpdateInterval: NodeJS.Timeout;

export function activate(context: vscode.ExtensionContext) {
    // Create status bar item
    statusBarItem = vscode.window.createStatusBarItem(
        vscode.StatusBarAlignment.Right,
        100
    );
    statusBarItem.command = 'autoCommitStatus.showDetails';
    context.subscriptions.push(statusBarItem);

    // Register command to show details
    const showDetails = vscode.commands.registerCommand(
        'autoCommitStatus.showDetails',
        () => {
            const statusFile = path.join(os.homedir(), '.auto_commit_watcher_status.json');
            if (fs.existsSync(statusFile)) {
                const status = JSON.parse(fs.readFileSync(statusFile, 'utf8'));
                vscode.window.showInformationMessage(
                    `Status: ${status.status}\n` +
                    `Message: ${status.message}\n` +
                    (status.countdown ? `Countdown: ${status.countdown}s\n` : '') +
                    (status.lastCommit ? `Last: ${status.lastCommit}` : '')
                );
            } else {
                vscode.window.showInformationMessage('Auto-commit watcher not running');
            }
        }
    );
    context.subscriptions.push(showDetails);

    // Update status every 2 seconds
    statusUpdateInterval = setInterval(updateStatus, 2000);
    updateStatus();

    // Cleanup on deactivate
    context.subscriptions.push({
        dispose: () => {
            if (statusUpdateInterval) {
                clearInterval(statusUpdateInterval);
            }
        }
    });
}

function updateStatus() {
    const statusFile = path.join(os.homedir(), '.auto_commit_watcher_status.json');
    
    if (!fs.existsSync(statusFile)) {
        statusBarItem.text = '$(circle-slash) Auto-Commit: Not running';
        statusBarItem.tooltip = 'Auto-commit watcher is not running';
        statusBarItem.show();
        return;
    }

    try {
        const status = JSON.parse(fs.readFileSync(statusFile, 'utf8'));
        const statusText = status.status || 'unknown';
        const message = status.message || '';
        const countdown = status.countdown;

        let icon = '$(circle-outline)';
        let text = 'Auto-Commit: ';

        switch (statusText) {
            case 'idle':
                icon = '$(circle-filled)';
                text += 'Watching';
                break;
            case 'waiting':
                icon = '$(clock)';
                text += countdown ? `Waiting (${countdown}s)` : 'Waiting';
                break;
            case 'committing':
                icon = '$(sync~spin)';
                text += 'Committing';
                break;
            case 'error':
                icon = '$(error)';
                text += 'Error';
                break;
            default:
                text += statusText;
        }

        statusBarItem.text = `${icon} ${text}`;
        statusBarItem.tooltip = message + (status.lastCommit ? `\nLast: ${status.lastCommit}` : '');
        statusBarItem.show();
    } catch (error) {
        statusBarItem.text = '$(error) Auto-Commit: Error';
        statusBarItem.tooltip = 'Error reading status';
        statusBarItem.show();
    }
}

export function deactivate() {
    if (statusUpdateInterval) {
        clearInterval(statusUpdateInterval);
    }
    if (statusBarItem) {
        statusBarItem.dispose();
    }
}
```

4. Update `package.json`:
```json
{
  "activationEvents": ["*"],
  "contributes": {
    "commands": [
      {
        "command": "autoCommitStatus.showDetails",
        "title": "Show Auto-Commit Status"
      }
    ]
  }
}
```

5. Build and install:
```bash
npm install
npm run compile
# Then install in Cursor by copying the extension folder
```

## Alternative: Simple Status File Reader

If you don't want to create an extension, you can use a terminal command or create a simple script that Cursor can run.

