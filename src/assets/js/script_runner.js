const { ipcRenderer } = require('electron');
    
document.addEventListener('DOMContentLoaded', () => {
    const darkTheme = localStorage.getItem('darkTheme') === 'true';
    if (darkTheme) {
        document.body.classList.add('dark');
    }
    const sidebarExpanded = localStorage.getItem('sidebarExpanded') === 'true';
    const sidebar = document.querySelector('.sidebar');
    const container = document.querySelector('.container');
    
    if (sidebarExpanded) {
        sidebar.classList.add('expanded');
        container.classList.add('sidebar-expanded');
    }
});

const urlParams = new URLSearchParams(window.location.search);
const scriptPath = urlParams.get('scriptPath');
const title = urlParams.get('title');
const description = urlParams.get('description');

document.getElementById('scriptTitle').textContent = title;
document.getElementById('scriptDescription').textContent = description;
document.getElementById('backButton').addEventListener('click', () => {
    const urlParams = new URLSearchParams(window.location.search);
    const previousPage = urlParams.get('previousPage') || 'index.html';
    ipcRenderer.send('navigate-to', previousPage);
});

document.getElementById('sidebarToggle').addEventListener('click', () => {
    const sidebar = document.querySelector('.sidebar');
    const container = document.querySelector('.container');
    sidebar.classList.toggle('expanded');
    container.classList.toggle('sidebar-expanded');
    
    localStorage.setItem('sidebarExpanded', sidebar.classList.contains('expanded'));
});
function navigateTo(page) {
    ipcRenderer.send('navigate-to', page);
}

ipcRenderer.on('script-output', (event, data) => {
    const logs = document.getElementById('logs');
    const line = document.createElement('p');
    line.className = 'log-line';
    line.textContent = data;
    logs.appendChild(line);
    logs.scrollTop = logs.scrollHeight;
});
ipcRenderer.on('script-completed', () => {
    document.getElementById('loadingIndicator').style.display = 'none';
    document.getElementById('successMessage').style.display = 'block';
});
ipcRenderer.send('run-powershell-script', scriptPath);