const { ipcRenderer } = require('electron');
        
let availableDrives = [];
let selectedDrives = [];

document.addEventListener('DOMContentLoaded', () => {
    const darkTheme = localStorage.getItem('darkTheme') === 'true';
    if (darkTheme) {
        document.body.classList.add('dark');
    }
    
    detectAvailableDrives();
    
    document.getElementById('refreshButton').style.display = 'none';
    
    document.getElementById('scanStorageButton').addEventListener('click', () => {
        if (availableDrives.length > 1) {
            showDriveSelectionInterface();
        } else {
            document.getElementById('success-message').style.display = 'none';
            document.getElementById('logs-section').style.display = 'none';
        
            document.getElementById('refreshButton').style.display = 'none';
        
            getDriveInfo();
        }
    });
    
    document.getElementById('scanSelectedButton').addEventListener('click', () => {
        if (selectedDrives.length === 0) {
            alert('Please select at least one drive to scan.');
            return;
        }
        
        document.getElementById('success-message').style.display = 'none';
        document.getElementById('logs-section').style.display = 'none';
        document.getElementById('driveSelectionContainer').style.display = 'none';
        
        document.getElementById('refreshButton').style.display = 'none';
        
        getDriveInfo(selectedDrives);
    });
    
    document.getElementById('refreshButton').addEventListener('click', () => {
        document.getElementById('success-message').style.display = 'none';
        document.getElementById('logs-section').style.display = 'none';
        document.getElementById('driveSelectionContainer').style.display = 'none';
        
        document.getElementById('refreshButton').style.display = 'none';
        
        const driveCards = document.querySelectorAll('.drive-card');
        
        const driveLetters = Array.from(driveCards).map(card => {
            const driveId = card.id.replace('drive-card-', '');
            return `${driveId}:`;
        });
        
        if (driveLetters.length === 0) {
            detectAvailableDrives();
            getDriveInfo();
        } else {
            getDriveInfo(driveLetters);
        }
    });
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
    document.getElementById('loading').style.display = 'block';
    document.getElementById('progress-text').innerText = "Scanning storage, please wait...";
    document.getElementById('success-message').style.display = 'none';
    document.getElementById('logs-section').style.display = 'none';
    document.getElementById('output').innerHTML = '';
    
    ipcRenderer.send('run-script', {
        scriptPath: scriptPath,
        title: title,
        description: description,
        previousPage: 'storage.html'
    });
}

function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

function getDriveInfo(drivesToScan = null) {
    console.log('Gathering storage information...', drivesToScan ? `for drives: ${drivesToScan.join(', ')}` : 'for all drives');
     
    document.getElementById('loading').style.display = 'flex';
    document.getElementById('progress-text').innerText = "Scanning storage, please wait...";
    
    document.querySelector('.scan-storage-container').style.display = 'none';
    
    document.getElementById('refreshButton').style.display = 'none';
    
    const progressBar = document.getElementById('scan-progress-bar');
    progressBar.style.width = '0%';
    
    let progress = 0;
    const progressInterval = setInterval(() => {
        if (progress < 90) {
            const increment = Math.random() * 5 + 1;
            progress += increment;
            if (progress > 90) progress = 90;
            progressBar.style.width = progress + '%';
            
            if (progress < 30) {
                document.getElementById('progress-text').innerText = "Analyzing drives...";
            } else if (progress < 60) {
                document.getElementById('progress-text').innerText = "Scanning file types...";
            } else if (progress < 85) {
                document.getElementById('progress-text').innerText = "Finalizing analysis...";
            }
        }
    }, 800);
    
    window.currentProgressInterval = progressInterval;
    
    const scanButton = document.getElementById('scanStorageButton');
    scanButton.disabled = true;
    
    const drivesContainer = document.getElementById('drives-container');
    drivesContainer.innerHTML = '';
    
    document.getElementById('storage-analysis-section').style.display = 'none';
    
    document.getElementById('images-size').innerText = "Scanning...";
    document.getElementById('videos-size').innerText = "Scanning...";
    document.getElementById('audio-size').innerText = "Scanning...";
    document.getElementById('documents-size').innerText = "Scanning...";
    document.getElementById('apps-size').innerText = "Scanning...";
    
    const timeoutId = setTimeout(() => {
        document.getElementById('progress-text').innerText = "Scanning is taking longer than expected. This may require administrator privileges...";
    }, 60000); // 60 seconds

    window.systemDetails = {
        systemFilesSize: 0,
        downloadsSize: 0,
        recycleBinSize: 0,
        tempFilesSize: 0
    };
    
    // Use our new C executable instead of PowerShell
    let scriptPath = './windows/storage/storage_scan';
    let args = [];
    
    if (drivesToScan && drivesToScan.length > 0) {
        const drivesParam = drivesToScan.join(',');
        args = [drivesParam];
    }
    
    ipcRenderer.send('run-executable', {
        scriptPath: scriptPath,
        args: args
    });
    
    ipcRenderer.removeAllListeners('script-output');
    ipcRenderer.removeAllListeners('script-error');
    ipcRenderer.removeAllListeners('script-completed');
    
    ipcRenderer.on('script-output', (event, data) => {
        console.log("Received script output:", data);
        
        if (data.includes('|')) {
            const parts = data.split('|');
            const dataType = parts[0];
            
            console.log("Processing data type:", dataType);
            
            switch (dataType) {
                case 'DRIVE_INFO':
                    const driveLetter = parts[1];
                    const totalSpace = parseInt(parts[2]) || 0;
                    const freeSpace = parseInt(parts[3]) || 0;
                    const usedSpace = parseInt(parts[4]) || 0;
                    const usedPercentage = parseFloat(parts[5]) || 0;
                    
                    console.log(`Drive info (${driveLetter}):`, totalSpace, freeSpace, usedSpace, usedPercentage);
                    
                    createOrUpdateDriveCard(driveLetter, totalSpace, freeSpace, usedSpace, usedPercentage);
                    break;
                
                case 'SYSTEM_FILES_SIZE':
                    const systemFilesSize = parseInt(parts[1]) || 0;
                    console.log("System files size:", systemFilesSize);
                    window.systemDetails.systemFilesSize = systemFilesSize;
                    updateSystemDetailsCard();
                    break;
                
                case 'DOWNLOADS_SIZE':
                    const downloadsSize = parseInt(parts[1]) || 0;
                    console.log("Downloads size:", downloadsSize);
                    window.systemDetails.downloadsSize = downloadsSize;
                    updateSystemDetailsCard();
                    break;
                
                case 'RECYCLE_BIN_SIZE':
                    const recycleBinSize = parseInt(parts[1]) || 0;
                    console.log("Recycle bin size:", recycleBinSize);
                    window.systemDetails.recycleBinSize = recycleBinSize;
                    updateSystemDetailsCard();
                    break;
                
                case 'TEMP_FILES_SIZE':
                    const tempFilesSize = parseInt(parts[1]) || 0;
                    console.log("Temp files size:", tempFilesSize);
                    window.systemDetails.tempFilesSize = tempFilesSize;
                    updateSystemDetailsCard();
                    break;
                
                case 'IMAGES_SIZE':
                    const imagesSize = parseInt(parts[1]) || 0;
                    console.log("Images size:", imagesSize);
                    document.getElementById('images-size').textContent = formatBytes(imagesSize);
                    break;
                
                case 'VIDEOS_SIZE':
                    const videosSize = parseInt(parts[1]) || 0;
                    console.log("Videos size:", videosSize);
                    document.getElementById('videos-size').textContent = formatBytes(videosSize);
                    break;
                
                case 'AUDIO_SIZE':
                    const audioSize = parseInt(parts[1]) || 0;
                    console.log("Audio size:", audioSize);
                    document.getElementById('audio-size').textContent = formatBytes(audioSize);
                    break;
                
                case 'DOCUMENTS_SIZE':
                    const documentsSize = parseInt(parts[1]) || 0;
                    console.log("Documents size:", documentsSize);
                    document.getElementById('documents-size').textContent = formatBytes(documentsSize);
                    break;
                
                case 'APPS_SIZE':
                    const appsSize = parseInt(parts[1]) || 0;
                    console.log("Apps size:", appsSize);
                    document.getElementById('apps-size').textContent = formatBytes(appsSize);
                    break;
                    
                case 'SCRIPT_COMPLETED':
                    console.log("Script completion message received");
                    // O próprio main.js já dispara o evento script-completed quando o processo termina
                    break;
            }
        }
    });
    
    ipcRenderer.on('script-error', (event, error) => {
        if (window.currentProgressInterval) {
            clearInterval(window.currentProgressInterval);
        }
        clearTimeout(timeoutId);
        
        document.getElementById('scan-progress-bar').style.width = '80%';
        document.getElementById('progress-text').innerText = "Scan failed";
        
        scanButton.disabled = false;
        scanButton.innerHTML = '<i class="fas fa-hdd"></i> Scan Storage';
        
        console.error('Storage scan error:', error);
        
        const elements = document.querySelectorAll('[id$="-size"]');
        elements.forEach(element => {
            if (element.innerText === "Scanning...") {
                element.innerText = "Data unavailable";
            }
        });
        
        document.getElementById('success-message').style.display = 'block';
        document.getElementById('success-message').className = 'error-message';
        document.getElementById('success-message').innerText = "Error: Could not execute storage scan. This may require administrator privileges.";
        
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            document.querySelector('.scan-storage-container').style.display = 'flex';
            if (document.querySelector('.drive-card')) {
                document.getElementById('refreshButton').style.display = 'flex';
            }
        }, 1500);
    });

    ipcRenderer.on('script-completed', (event) => {
        clearTimeout(timeoutId);
        
        if (window.currentProgressInterval) {
            clearInterval(window.currentProgressInterval);
        }
        document.getElementById('scan-progress-bar').style.width = '100%';
        document.getElementById('progress-text').innerText = "Scan completed!";
        
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            document.querySelector('.scan-storage-container').style.display = 'flex';
            if (document.querySelector('.drive-card')) {
                document.getElementById('refreshButton').style.display = 'flex';
            }
        }, 1500);
        
        // Mostrar cartão de análise de armazenamento após o scan
        document.getElementById('storage-analysis-section').style.display = 'block';
        
        scanButton.disabled = false;
        scanButton.innerHTML = '<i class="fas fa-hdd"></i> Scan Storage';
        
        const elements = document.querySelectorAll('[id$="-size"]');
        const hasIncompleteData = Array.from(elements).some(el => el.textContent === 'Scanning...');
        
        if (hasIncompleteData) {
            document.getElementById('success-message').style.display = 'block';
            document.getElementById('success-message').className = 'warning-message';
            document.getElementById('success-message').innerText = "Some storage data could not be retrieved. This might be due to permission issues.";
        } else {
            document.getElementById('success-message').style.display = 'block';
            document.getElementById('success-message').className = 'success-message';
            document.getElementById('success-message').innerText = "Storage scan completed successfully!";
        }
        
        console.log("Storage scan completed");
    });
}

function getStorageBreakdown() {
}

function addOutputLine(text, type = 'info') {
    const output = document.getElementById('output');
    const line = document.createElement('div');
    line.className = `output-line ${type}`;
    line.textContent = text;
    output.appendChild(line);
    output.scrollTop = output.scrollHeight;
}

function createOrUpdateDriveCard(driveLetter, totalSpace, freeSpace, usedSpace, usedPercentage) {
    const drivesContainer = document.getElementById('drives-container');
    const driveId = `drive-card-${driveLetter.replace(':', '')}`;
    
    if (!drivesContainer.classList.contains('drives-grid')) {
        drivesContainer.classList.add('drives-grid');
    }
    
    let driveCard = document.getElementById(driveId);
    
    if (!driveCard) {
        driveCard = document.createElement('div');
        driveCard.id = driveId;
        driveCard.className = 'drive-card';
        
        const isDriveC = driveLetter === 'C:';
        const driveIcon = isDriveC ? 'fa-desktop' : 'fa-hdd';
        const driveTitle = isDriveC ? 'System Drive' : 'Drive';
        
        driveCard.innerHTML = `
            <h3><i class="fas ${driveIcon}"></i> ${driveTitle} ${driveLetter}</h3>
            <div class="drive-card-details">
                <span>${formatBytes(freeSpace)} free</span>
                <span>${formatBytes(totalSpace)} total</span>
            </div>
            <div class="storage-chart">
                <div class="storage-chart-fill" id="${driveId}-usage" style="width: 0%;"></div>
            </div>
            <div class="storage-info">
                <span>${formatBytes(usedSpace)} used (${usedPercentage}%)</span>
            </div>
        `;
        
        drivesContainer.appendChild(driveCard);
    } else {
        const usageBar = document.getElementById(`${driveId}-usage`);
        if (usageBar) {
            usageBar.style.width = `${usedPercentage}%`;
        }
        
        driveCard.querySelector('.drive-card-details').innerHTML = `
            <span>${formatBytes(freeSpace)} free</span>
            <span>${formatBytes(totalSpace)} total</span>
        `;
        
        driveCard.querySelector('.storage-info').innerHTML = `
            <span>${formatBytes(usedSpace)} used (${usedPercentage}%)</span>
        `;
    }
    
    setTimeout(() => {
        const usageBar = document.getElementById(`${driveId}-usage`);
        if (usageBar) {
            usageBar.style.width = `${usedPercentage}%`;
        }
    }, 50);
    
    if (driveLetter === 'C:') {
        ensureSystemDetailsCard();
    }
}

function ensureSystemDetailsCard() {
    const drivesContainer = document.getElementById('drives-container');
    let detailsCard = document.getElementById('system-details-card');
    
    if (!detailsCard) {
        detailsCard = document.createElement('div');
        detailsCard.id = 'system-details-card';
        detailsCard.className = 'drive-card system-details';
        
        detailsCard.innerHTML = `
            <h3><i class="fas fa-info-circle"></i> System Details</h3>
            <div class="storage-detail">
                <div class="storage-type">
                    <i class="fas fa-file-alt"></i>
                    <span>System Files</span>
                </div>
                <div class="storage-value" id="system-files-size">Scanning...</div>
            </div>
            <div class="storage-detail">
                <div class="storage-type">
                    <i class="fas fa-file-download"></i>
                    <span>Downloads</span>
                </div>
                <div class="storage-value" id="downloads-size">Scanning...</div>
            </div>
            <div class="storage-detail">
                <div class="storage-type">
                    <i class="fas fa-trash"></i>
                    <span>Recycle Bin</span>
                </div>
                <div class="storage-value" id="recyclebin-size">Scanning...</div>
            </div>
            <div class="storage-detail">
                <div class="storage-type">
                    <i class="fas fa-broom"></i>
                    <span>Temporary Files</span>
                </div>
                <div class="storage-value" id="temp-files-size">Scanning...</div>
            </div>
        `;
        
        drivesContainer.appendChild(detailsCard);
    }
}

function updateSystemDetailsCard() {
    if (!window.systemDetails) return;
    
    const details = window.systemDetails;
    
    if (document.getElementById('system-files-size')) {
        document.getElementById('system-files-size').textContent = formatBytes(details.systemFilesSize);
    }
    
    if (document.getElementById('downloads-size')) {
        document.getElementById('downloads-size').textContent = formatBytes(details.downloadsSize);
    }
    
    if (document.getElementById('recyclebin-size')) {
        document.getElementById('recyclebin-size').textContent = formatBytes(details.recycleBinSize);
    }
    
    if (document.getElementById('temp-files-size')) {
        document.getElementById('temp-files-size').textContent = formatBytes(details.tempFilesSize);
    }
}

function detectAvailableDrives() {
    console.log('Detecting available drives...');
    
    availableDrives = [];
    selectedDrives = [];
    
    ipcRenderer.send('list-drives');

    ipcRenderer.removeAllListeners('drives-detected');
    ipcRenderer.removeAllListeners('drives-error');

    ipcRenderer.on('drives-detected', (event, drives) => {
        console.log("Drives detected:", drives);
        availableDrives = drives;
        
        if (availableDrives.length === 0) {
            availableDrives = ['C:'];
        }
        
        if (availableDrives.length === 1) {
            selectedDrives = [...availableDrives];
        }
    });
    
    ipcRenderer.on('drives-error', (event, error) => {
        console.error('Drive detection error:', error);
        availableDrives = ['C:'];
        selectedDrives = ['C:'];
    });
}

function showDriveSelectionInterface() {
    const container = document.getElementById('driveSelectionContainer');
    const chipsContainer = document.getElementById('driveChips');
    const counter = document.getElementById('selectedCounter');
    
    chipsContainer.innerHTML = '';
    selectedDrives = [];
    updateSelectedCounter();
    
    availableDrives.forEach(drive => {
        const chip = document.createElement('div');
        chip.className = 'drive-chip';
        chip.textContent = drive;
        chip.addEventListener('click', () => {
            chip.classList.toggle('selected');
            
            if (chip.classList.contains('selected')) {
                if (!selectedDrives.includes(drive)) {
                    selectedDrives.push(drive);
                }
            } else {
                const index = selectedDrives.indexOf(drive);
                if (index !== -1) {
                    selectedDrives.splice(index, 1);
                }
            }
            
            updateSelectedCounter();
        });
        
        chipsContainer.appendChild(chip);
    });
    
    container.style.display = 'block';
}

function updateSelectedCounter() {
    const counter = document.getElementById('selectedCounter');
    counter.textContent = selectedDrives.length;
}