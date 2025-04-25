// Define a página atual para ser usada nas funções
const currentPage = 'boot.html';

// Função específica para executar scripts da página boot
function runBootScript(scriptPath, title, description) {
    ipcRenderer.send('run-script', {
        scriptPath: scriptPath,
        title: title,
        description: description,
        previousPage: 'boot.html'
    });
}

// Inicializar listeners específicos da página, se necessário
document.addEventListener('DOMContentLoaded', () => {
    // Adicionar quaisquer inicializações específicas da página boot aqui
}); 