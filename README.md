## WindowsX – Windows Optimization Suite

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)  [![GitHub stars](https://img.shields.io/github/stars/orafaelmiguel/WindowsX?style=social)](https://github.com/orafaelmiguel/WindowsX/stargazers)  [![GitHub issues](https://img.shields.io/github/issues/orafaelmiguel/WindowsX)](https://github.com/orafaelmiguel/WindowsX/issues)

> **WindowsX** is an Electron‑based desktop app that unifies powerful optimization, cleanup, monitoring, and maintenance tools for Windows.

---

### 📌 Table of Contents
1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Usage](#usage)
   - [Sidebar Navigation](#sidebar-navigation)
   - [Storage Management](#storage-management)
   - [Boot Optimization](#boot-optimization)
   - [Network Tools](#network-tools)
   - [Driver Management](#driver-management)
   - [Settings](#settings)
5. [Development](#development)
6. [Directory Structure](#directory-structure)
7. [Contributing](#contributing)
8. [License](#license)

---

## ✨ Features
- **Cross‑Platform**: Windows 10+ & macOS (Electron)
- **Modular Sidebar**: Home, Network, Boot, Drivers, Storage, Settings
- **Storage Analysis**:
  - Scan all or selected drives
  - Breakdown by file types: Images, Videos, Audio, Documents, Applications
  - Smart "Installed Applications" scanner (games, third‑party, registry installs)
  - Incremental "Refresh Data" rescanning
- **PowerShell Scripts**:
  - Disk Cleanup, Large Files Finder, Cache Cleaner, Duplicate Finder
- **Boot Optimizer**: Manage startup apps & services, performance profiles
- **Real‑time Monitoring**: CPU, RAM, Disk, Network metrics & charts
- **Driver Updater**: Detect and install latest hardware drivers
- **Settings**: Dark/light theme, fullscreen toggle, reset to defaults

---

## 🛠 Prerequisites
- **Node.js** ≥ 14.x & **npm** ≥ 6.x (or Yarn)  
- **PowerShell** 5.1+ (Windows only)

---

## 🚀 Installation
```bash
# Clone repository
git clone https://github.com/yourusername/WindowsX.git
cd WindowsX

# Install dependencies
npm install

# Launch in development mode
npm start

# Build for production
npm run dist
```  
*Artifacts will be generated under `dist/` by `electron-builder`.*

---

## 🎮 Usage
### Sidebar Navigation
Use the collapsible sidebar to switch between modules:
- **Home**: Overview dashboard
- **Network**: Real‑time charts & TCP/IP tuning
- **Boot**: Startup apps & Windows services
- **Drivers**: Scan and update drivers
- **Storage**: Disk analysis and cleanup scripts
- **Settings**: App preferences

### Storage Management
1. **Scan Storage**: Click to analyze all drives (or select specific drives when prompted).  
2. **Refresh Data**: After a scan, re‑scan only displayed drives.  
3. **Analysis**: View size breakdown by file type and installed applications.  
4. **Cleanup Scripts**: Run Disk Cleanup, Large Files Scanner, Cache Cleaner, Duplicate Finder.

### Boot Optimization
- Enable/disable startup programs and Windows services.  
- Pre‑configured performance profiles (e.g. Gaming, Work).

### Network Tools
- Live resource graphs (CPU, RAM, Disk, Network).  
- Adjust MTU, QoS, DNS cache.  
- Speed & latency testing.

### Driver Management
- List installed drivers and available updates.  
- One‑click download & installation.

### Settings
- Toggle dark/light theme.  
- Launch in fullscreen.  
- Show/hide taskbar/dock icon.  
- Reset to default preferences.

---

## 🏗 Development
- **Main Process**: `src/main.js` handles windows, IPC & script execution.  
- **Renderer Pages**: `src/pages/*.html` (inline JS & CSS).  
- **Scripts**: PowerShell scripts under `windows/storage/`

**Scripts**:
```bash
npm start      # Start dev mode
npm run dist   # Package app
```

---

## 📁 Directory Structure
```
WindowsX/
├─ src/
│  ├─ pages/          # HTML + JS for each view
│  └─ main.js         # Electron main process
├─ windows/
│  └─ storage/        # PowerShell scripts
├─ package.json
├─ electron-builder.yml
└─ README.md
```

---

## 🤝 Contributing
1. Fork the repo  
2. Create your branch (`git checkout -b feature/YourFeature`)  
3. Commit your changes (`git commit -m 'Add YourFeature'`)  
4. Push to the branch (`git push origin feature/YourFeature`)  
5. Open a Pull Request

Please run `npm start` to verify functionality before opening a PR.

---

## 📄 License
This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

*Happy optimizing!*

























