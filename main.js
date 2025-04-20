const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  mainWindow.loadFile('index.html');
  //devtools
  // mainWindow.webContents.openDevTools();
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// Handle navigation
ipcMain.on('navigate-to', (event, page) => {
  mainWindow.loadFile(page);
});

// Handle script execution
ipcMain.on('run-script', (event, { scriptPath, title, description, previousPage }) => {
  const params = new URLSearchParams({
    scriptPath: scriptPath,
    title: title,
    description: description,
    previousPage: previousPage || 'index.html'
  });
  
  mainWindow.loadFile('script_runner.html', {
    search: params.toString()
  });
});

// Handle script execution with admin privileges
ipcMain.on('run-powershell-script', (event, scriptPath) => {
  // Get the absolute paths
  const absoluteScriptPath = path.resolve(__dirname, scriptPath);
  const runAsAdminPath = path.resolve(__dirname, 'run_as_admin.ps1');
  
  console.log('Script Path:', absoluteScriptPath);
  console.log('Run As Admin Path:', runAsAdminPath);
  
  const powershell = spawn('powershell.exe', [
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', runAsAdminPath,
    '-ScriptPath', absoluteScriptPath
  ]);

  powershell.stdout.on('data', (data) => {
    const output = data.toString().trim();
    if (output) {
      mainWindow.webContents.send('script-output', output);
    }
  });

  powershell.stderr.on('data', (data) => {
    const error = data.toString().trim();
    if (error) {
      mainWindow.webContents.send('script-output', error);
    }
  });

  powershell.on('close', (code) => {
    if (code === 0) {
      mainWindow.webContents.send('script-completed');
    } else {
      mainWindow.webContents.send('script-output', `Script failed with exit code: ${code}`);
    }
  });
}); 