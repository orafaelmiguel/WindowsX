const { ipcRenderer } = require('electron');
        
        document.addEventListener('DOMContentLoaded', () => {
            const darkTheme = localStorage.getItem('darkTheme') === 'true';
            if (darkTheme) {
                document.body.classList.add('dark');
            }
        })
        document.addEventListener('DOMContentLoaded', () => {
            const sidebarExpanded = localStorage.getItem('sidebarExpanded') === 'true';
            const sidebar = document.querySelector('.sidebar');
            const mainContent = document.querySelector('.main-content');
            
            if (sidebarExpanded) {
                sidebar.classList.add('expanded');
                mainContent.classList.add('sidebar-expanded');
            }
        });
        
        // sidebar toggle
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