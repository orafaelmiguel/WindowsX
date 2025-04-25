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

function navigateTo(page) {
    ipcRenderer.send('navigate-to', page);
}

function runScript(scriptPath, title, description) {
    ipcRenderer.send('run-script', {
        scriptPath: scriptPath,
        title: title,
        description: description,
        previousPage: 'network.html'
    });
}

function addOutputLine(text, type = 'info') {
    const output = document.getElementById('output');
    const line = document.createElement('div');
    line.className = `output-line ${type}`;
    line.textContent = text;
    output.appendChild(line);
    output.scrollTop = output.scrollHeight;
}

ipcRenderer.on('script-output', (event, data) => {
    const loading = document.getElementById('loading');
    const successMessage = document.getElementById('success-message');
    const logsSection = document.getElementById('logs-section');
    
    loading.style.display = 'none';
    logsSection.style.display = 'block';
    successMessage.style.display = 'block';
    
    addOutputLine(data);
});

ipcRenderer.on('script-error', (event, data) => {
    const loading = document.getElementById('loading');
    const logsSection = document.getElementById('logs-section');
    
    loading.style.display = 'none';
    logsSection.style.display = 'block';
    
    addOutputLine(data, 'error');
});

ipcRenderer.on('script-complete', (event, code) => {
    const loading = document.getElementById('loading');
    const successMessage = document.getElementById('success-message');
    const logsSection = document.getElementById('logs-section');
    
    loading.style.display = 'none';
    logsSection.style.display = 'block';
    
    if (code === 0) {
        successMessage.style.display = 'block';
    }
    
    addOutputLine(`Script completed with exit code: ${code}`);
});

document.getElementById('runTcpIpBoost').addEventListener('click', () => {
    runScript('windows/network/tcp_ip_boost.ps1', 'TCP/IP Optimization', 'Optimizing network settings for better performance...');
});

// Navigation
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const page = e.target.getAttribute('data-page');
        ipcRenderer.send('navigate-to', page);
    });
});