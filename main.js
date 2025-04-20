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
  
  // Descomente a linha abaixo para abrir o DevTools
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

// Manipulador para executar scripts PowerShell
ipcMain.on('run-powershell-script', (event, scriptPath) => {
  const powershell = spawn('powershell.exe', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath]);
  
  powershell.stdout.on('data', (data) => {
    mainWindow.webContents.send('script-output', data.toString());
  });

  powershell.stderr.on('data', (data) => {
    mainWindow.webContents.send('script-error', data.toString());
  });

  powershell.on('close', (code) => {
    mainWindow.webContents.send('script-complete', code);
  });
}); 