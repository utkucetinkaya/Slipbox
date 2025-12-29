# Firebase Functions Dependencies Fix

## Issue

TypeScript errors due to missing node_modules. PowerShell execution policy prevents npm install.

## Solution

### Option 1: Enable PowerShell Scripts (Recommended)
```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run in projects directory:
cd Desktop/iosappidea/firebase-backend/functions
npm install
```

### Option 2: Use Command Prompt
```cmd
# Open Command Prompt (cmd.exe)
cd Desktop\iosappidea\firebase-backend\functions
npm install
```

### Option 3: Use VS Code Integrated Terminal
1. Open VS Code
2. Terminal → New Terminal
3. Select "Command Prompt" from dropdown
4. Run: `npm install`

## After Installation

Dependencies that will be installed:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK  
- `openai` - OpenAI API client
- `pdfkit` - PDF generation
- `axios` - HTTP client
- `uuid` - UUID generation (for share tokens)

TypeScript errors will resolve once node_modules is installed.

## Verify Installation

```bash
npm run build
```

Should compile without errors.
