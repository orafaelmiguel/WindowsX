const { app, BrowserWindow, ipcMain, globalShortcut } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');
const { electron } = require('process');
const os = require('os'); // Para funções do sistema operacional

// Settings file path
const userDataPath = app.getPath('userData');
const settingsPath = path.join(userDataPath, 'settings.json');

// Default settings
const defaultSettings = {
  darkTheme: false,
  startFullscreen: true,
  runAtStartup: false
};

let mainWindow;
let settingsWindow = null;

// Load settings
function loadSettings() {
  try {
    if (fs.existsSync(settingsPath)) {
      const data = fs.readFileSync(settingsPath, 'utf8');
      return { ...defaultSettings, ...JSON.parse(data) };
    }
  } catch (error) {
    console.error('Error loading settings:', error);
  }
  return defaultSettings;
}

// Carrega as configurações após definir as constantes necessárias
let currentSettings = loadSettings();

// Save settings
function saveSettings(settings) {
  try {
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2), 'utf8');
  } catch (error) {
    console.error('Error saving settings:', error);
  }
}

// Configurar inicialização automática com o Windows
function setAutoLaunch(enable) {
  try {
    app.setLoginItemSettings({
      openAtLogin: enable,
      path: process.execPath
    });
    console.log('Auto-start ' + (enable ? 'enabled' : 'disabled'));
  } catch (error) {
    console.error('Error setting auto-launch:', error);
  }
}

// Definir ícone do aplicativo baseado na plataforma
if (process.platform === 'win32') {
  app.setAppUserModelId(process.execPath);
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    autoHideMenuBar: true,
    frame: true,
    icon: path.join(__dirname, '..', 'public', 'icon.png')
  });

  if (currentSettings.startFullscreen) {
    mainWindow.maximize();
  }

  mainWindow.loadFile(path.join(__dirname, 'pages', 'index.html'));
  mainWindow.setMenu(null);
  //devtools
  // mainWindow.webContents.openDevTools();
  
  // Register a shortcut for toggling fullscreen mode
  globalShortcut.register('F11', () => {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });
}

function createSettingsWindow() {
  // If settings window already exists, focus it
  if (settingsWindow) {
    settingsWindow.focus();
    return;
  }

  // Get main window size and position
  const mainWindowBounds = mainWindow.getBounds();
  const parentWidth = mainWindowBounds.width;
  const parentHeight = mainWindowBounds.height;

  // Calculate settings window size (slightly smaller than parent)
  const width = Math.min(800, parentWidth * 0.8);
  const height = Math.min(800, parentHeight * 0.8);

  // Calculate center position relative to parent
  const x = Math.round(mainWindowBounds.x + (parentWidth - width) / 2);
  const y = Math.round(mainWindowBounds.y + (parentHeight - height) / 2);

  settingsWindow = new BrowserWindow({
    width: width,
    height: height,
    x: x,
    y: y,
    parent: mainWindow,
    modal: true, // Make it modal to improve focus
    resizable: true,
    minimizable: true,
    maximizable: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    autoHideMenuBar: true,
    frame: true,
    title: 'WindowsX - Settings',
    show: false, // Don't show until ready
    icon: path.join(__dirname, '..', 'public', 'icon.png')
  });

  settingsWindow.loadFile(path.join(__dirname, 'pages', 'settings.html'));
  // settingsWindow.webContents.openDevTools();

  // Show window when ready to avoid flashing
  settingsWindow.once('ready-to-show', () => {
    settingsWindow.show();
  });

  // Handle window close
  settingsWindow.on('closed', () => {
    settingsWindow = null;
  });
}

// Aplicar tema a uma janela
function applyTheme(window, isDark) {
  if (window && !window.isDestroyed()) {
    window.webContents.executeJavaScript(`
      document.body.classList.${isDark ? 'add' : 'remove'}('dark');
      localStorage.setItem('darkTheme', ${isDark});
    `).catch(err => console.error('Error applying theme:', err));
  }
}

// Aplicar tema a todas as janelas
function applyThemeToAllWindows(isDark) {
  // Aplicar à janela principal
  applyTheme(mainWindow, isDark);
  
  // Aplicar à janela de configurações, se estiver aberta
  if (settingsWindow) {
    applyTheme(settingsWindow, isDark);
  }
}

app.whenReady().then(() => {
  // Configura inicialização automática
  setAutoLaunch(currentSettings.runAtStartup);
  
  // Cria a janela principal
  createWindow();
  
  // Aplica o tema inicial
  setTimeout(() => {
    applyThemeToAllWindows(currentSettings.darkTheme);
  }, 500); // pequeno atraso para garantir que a janela está pronta
});

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
  // Agora todas as páginas são carregadas na janela principal, incluindo settings
  mainWindow.loadFile(path.join(__dirname, 'pages', page));
});

// Handle script execution
ipcMain.on('run-script', (event, { scriptPath, title, description, previousPage }) => {
  const params = new URLSearchParams({
    scriptPath: scriptPath,
    title: title,
    description: description,
    previousPage: previousPage || 'index.html'
  });
  
  mainWindow.loadFile(path.join(__dirname, 'pages', 'script_runner.html'), {
    search: params.toString()
  });
});

// Handle script execution with admin privileges
ipcMain.on('run-powershell-script', (event, scriptPath) => {
  // Get the absolute paths
  const isPackaged = app.isPackaged;
  
  let absoluteScriptPath;
  let runAsAdminPath;
  let scriptParams = '';
  
  // Resolver os caminhos de forma mais robusta
  const appRoot = path.resolve(path.join(__dirname, '..'));
  console.log('App Root Directory:', appRoot);
  
  // Verificar se o scriptPath contém parâmetros
  let scriptFile = scriptPath;
  
  if (scriptPath.includes(' ')) {
    // Separar o caminho do script dos parâmetros
    const spaceIndex = scriptPath.indexOf(' ');
    scriptFile = scriptPath.substring(0, spaceIndex);
    scriptParams = scriptPath.substring(spaceIndex + 1);
  }
  
  // Normalizar o caminho do script (remover qualquer ../ ou ./ desnecessário)
  const normalizedScriptPath = scriptFile.replace(/^\.\.\/\.\.\//, '').replace(/^\.\.\//, '');
  console.log('Normalized Script Path:', normalizedScriptPath);
  
  if (isPackaged) {
    // When running in packaged app, use the extraResources path
    const resourcesPath = process.resourcesPath;
    absoluteScriptPath = path.join(resourcesPath, normalizedScriptPath);
    runAsAdminPath = path.join(resourcesPath, 'run_as_admin.ps1');
  } else {
    // When running in development mode
    absoluteScriptPath = path.join(appRoot, normalizedScriptPath);
    runAsAdminPath = path.join(__dirname, 'run_as_admin.ps1');
  }
  
  console.log('App is packaged:', isPackaged);
  console.log('Full Script Path:', absoluteScriptPath);
  console.log('Script Parameters:', scriptParams);
  console.log('Run As Admin Path:', runAsAdminPath);
  
  // Mostrar quais arquivos existem no diretório
  try {
    const dir = path.dirname(absoluteScriptPath);
    console.log('Diretório do script:', dir);
    if (fs.existsSync(dir)) {
      console.log('Conteúdo do diretório:');
      const files = fs.readdirSync(dir);
      files.forEach(file => {
        console.log(`- ${file}`);
      });
    } else {
      console.log('Diretório não encontrado:', dir);
    }
  } catch (error) {
    console.error('Erro ao listar diretório:', error);
  }
  
  // Verify if files exist before running
  if (!fs.existsSync(absoluteScriptPath)) {
    const errorMsg = `Error: Script file not found at ${absoluteScriptPath}`;
    console.error(errorMsg);
    event.sender.send('script-error', errorMsg);
    return;
  }
  
  if (!fs.existsSync(runAsAdminPath)) {
    const errorMsg = `Error: Admin script not found at ${runAsAdminPath}`;
    console.error(errorMsg);
    event.sender.send('script-error', errorMsg);
    return;
  }
  
  console.log('Executing PowerShell script...');
  
  // Se estamos rodando o script de análise de armazenamento real, vamos exibir uma mensagem de carregamento
  if (scriptPath.includes('real_storage_scan.ps1')) {
    event.sender.send('script-output', 'Scanning storage, this may take a few minutes...');
  }
  
  // Construir os argumentos para o PowerShell
  const psArgs = [
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', runAsAdminPath,
    '-ScriptPath', absoluteScriptPath
  ];
  
  // Adicionar parâmetros do script se existirem
  if (scriptParams) {
    psArgs.push('-ScriptParams', scriptParams);
  }
  
  console.log('PowerShell arguments:', psArgs);
  
  const powershell = spawn('powershell.exe', psArgs);

  powershell.stdout.on('data', (data) => {
    const output = data.toString().trim();
    if (output) {
      console.log('Script output:', output);
      
      // Split output by lines and send each line separately
      const lines = output.split('\n');
      lines.forEach(line => {
        const trimmedLine = line.trim();
        if (trimmedLine) {
          event.sender.send('script-output', trimmedLine);
        }
      });
    }
  });

  powershell.stderr.on('data', (data) => {
    const error = data.toString().trim();
    if (error) {
      console.error('Script error:', error);
      event.sender.send('script-error', error);
    }
  });

  powershell.on('close', (code) => {
    console.log(`PowerShell script exited with code ${code}`);
    if (code === 0) {
      event.sender.send('script-completed');
    } else {
      event.sender.send('script-output', `Script failed with exit code: ${code}`);
    }
  });
});

// Lista drives sem privilégios de administrador
ipcMain.on('list-drives', (event) => {
  console.log('Listing drives without admin privileges...');
  
  // Em Windows, podemos usar método nativo
  if (process.platform === 'win32') {
    try {
      // Lista letras de drive disponíveis sem precisar de PowerShell ou admin
      const drives = [];
      
      // Verifica cada letra possível de drive
      for (const letter of 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') {
        const drivePath = `${letter}:\\`;
        try {
          // Se conseguirmos acessar as estatísticas do drive, ele existe
          fs.statSync(drivePath);
          drives.push(`${letter}:`);
        } catch (err) {
          // Ignora erros - significa que o drive não existe
        }
      }
      
      console.log('Drives detected:', drives);
      event.sender.send('drives-detected', drives);
    } catch (error) {
      console.error('Error detecting drives:', error);
      event.sender.send('drives-error', error.message);
    }
  } else {
    // Para outros sistemas, usamos uma abordagem diferente
    try {
      const rootFs = os.platform() === 'darwin' ? '/Volumes' : '/';
      const drives = fs.readdirSync(rootFs)
        .filter(name => !name.startsWith('.'))
        .map(name => name);
      
      console.log('Drives detected:', drives);
      event.sender.send('drives-detected', drives);
    } catch (error) {
      console.error('Error detecting drives:', error);
      event.sender.send('drives-error', error.message);
    }
  }
});

// Settings window handlers - agora gerenciados pela página, não pela janela
ipcMain.on('open-settings-window', () => {
  // Carregar página de configurações na janela principal
  mainWindow.loadFile(path.join(__dirname, 'pages', 'settings.html'));
});

// Remover handle para fechar a janela de configurações, pois ela não existe mais
ipcMain.on('close-settings-window', () => {
  // Não é mais necessário
});

ipcMain.on('get-settings', (event) => {
  const settings = loadSettings();
  event.sender.send('init-settings', settings);
});

ipcMain.on('toggle-theme', (event, isDark) => {
  // Atualizar configurações
  currentSettings.darkTheme = isDark;
  saveSettings(currentSettings);
  
  // Aplicar tema a todas as janelas
  applyThemeToAllWindows(isDark);
});

ipcMain.on('save-settings', (event, newSettings) => {
  // Salva as configurações atualizadas
  saveSettings(newSettings);
  
  // Verifica se o tema mudou
  const themeChanged = currentSettings.darkTheme !== newSettings.darkTheme;
  
  // Atualiza a variável de configurações atuais
  currentSettings = newSettings;
  
  // Aplica a configuração de maximizado, se a janela principal existir
  if (mainWindow) {
    if (newSettings.startFullscreen) {
      mainWindow.maximize();
    } else {
      mainWindow.unmaximize();
    }
  }
  
  // Aplicar o novo tema, se mudou
  if (themeChanged) {
    applyThemeToAllWindows(newSettings.darkTheme);
  }
  
  // Configurar inicialização automática
  setAutoLaunch(newSettings.runAtStartup);
});

ipcMain.on('reset-settings', () => {
  // Reseta para as configurações padrão
  saveSettings(defaultSettings);
  
  // Atualiza a variável de configurações atuais
  currentSettings = {...defaultSettings};
  
  // Aplica a configuração de maximizado, se a janela principal existir
  if (mainWindow) {
    if (defaultSettings.startFullscreen) {
      mainWindow.maximize();
    } else {
      mainWindow.unmaximize();
    }
  }
  
  // Configurar inicialização automática
  setAutoLaunch(defaultSettings.runAtStartup);
  
  // Atualiza a janela de configurações, se estiver aberta
  if (settingsWindow) {
    settingsWindow.webContents.send('init-settings', currentSettings);
  }
});

// Unregister all shortcuts when app is closing
app.on('will-quit', () => {
  globalShortcut.unregisterAll();
}); 