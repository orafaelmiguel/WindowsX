const { ipcRenderer } = require('electron');
        
document.addEventListener('DOMContentLoaded', () => {
    const darkTheme = localStorage.getItem('darkTheme') === 'true';
    if (darkTheme) {
        document.body.classList.add('dark');
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const sidebarExpanded = localStorage.getItem('sidebarExpanded') === 'true';
    const sidebar = document.querySelector('.sidebar');
    const mainContent = document.querySelector('.main-content');
    
    if (sidebarExpanded) {
        sidebar.classList.add('expanded');
        mainContent.classList.add('sidebar-expanded');
    }
});

document.getElementById('sidebarToggle').addEventListener('click', () => {
    const sidebar = document.querySelector('.sidebar');
    const mainContent = document.querySelector('.main-content');
    sidebar.classList.toggle('expanded');
    mainContent.classList.toggle('sidebar-expanded');
    
    localStorage.setItem('sidebarExpanded', sidebar.classList.contains('expanded'));
});

const themeSwitch = document.getElementById('themeSwitch');
const saveButton = document.getElementById('saveButton');
const resetButton = document.getElementById('resetButton');

themeSwitch.addEventListener('change', () => {
    const isDark = themeSwitch.checked;
    
    if (isDark) {
        document.body.classList.add('dark');
    } else {
        document.body.classList.remove('dark');
    }
    
    ipcRenderer.send('toggle-theme', isDark);
});

saveButton.addEventListener('click', () => {
    const settings = {
        darkTheme: themeSwitch.checked,
        startFullscreen: document.getElementById('fullscreenSwitch').checked,
        runAtStartup: document.getElementById('startupSwitch').checked
    };
    
    ipcRenderer.send('save-settings', settings);
    
    alert('Settings saved successfully!');
});

resetButton.addEventListener('click', () => {
    if (confirm('Are you sure you want to reset all settings to default?')) {
        themeSwitch.checked = false;
        document.getElementById('fullscreenSwitch').checked = true;
        document.getElementById('startupSwitch').checked = false;
        
        document.body.classList.remove('dark');
        
        ipcRenderer.send('reset-settings');
    }
});

ipcRenderer.on('init-settings', (event, settings) => {
    if (settings) {
        themeSwitch.checked = settings.darkTheme || false;
        document.getElementById('fullscreenSwitch').checked = settings.startFullscreen !== undefined ? settings.startFullscreen : true;
        document.getElementById('startupSwitch').checked = settings.runAtStartup || false;
        
        if (settings.darkTheme) {
            document.body.classList.add('dark');
        }
    }
});

document.addEventListener('DOMContentLoaded', () => {
    ipcRenderer.send('get-settings');
});

function navigateTo(page) {
    ipcRenderer.send('navigate-to', page);
}