const { app, BrowserWindow, ipcMain } = require('electron');
const { spawn } = require('child_process');
const path = require('path');

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

ipcMain.on('navigate-to', (event, page) => {
  mainWindow.loadFile(page);
});

ipcMain.on('run-powershell-script', (event, scriptPath) => {
  const adminScriptPath = path.join(__dirname, 'run_as_admin.ps1');
  const absoluteScriptPath = path.resolve(scriptPath);
  
  const powershell = spawn('powershell.exe', [
    '-ExecutionPolicy', 'Bypass',
    '-File', adminScriptPath,
    '-ScriptPath', absoluteScriptPath
  ]);
  
  powershell.stdout.on('data', (data) => {
    const output = data.toString();
    if (output.includes('SCRIPT_COMPLETED')) {
      mainWindow.webContents.send('script-complete', 0);
    } else if (output.includes('SCRIPT_FAILED')) {
      mainWindow.webContents.send('script-error', 'O script falhou ao executar');
    } else {
      mainWindow.webContents.send('script-output', output);
    }
  });

  powershell.stderr.on('data', (data) => {
    mainWindow.webContents.send('script-error', data.toString());
  });

  powershell.on('close', (code) => {
    if (code !== 0) {
      mainWindow.webContents.send('script-error', `Processo encerrado com código ${code}`);
    }
  });
}); 