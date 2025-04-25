// Define a página atual para ser usada nas funções
const currentPage = 'storage.html';

// Função específica para executar scripts da página storage
function runStorageScript(scriptPath, title, description) {
    ipcRenderer.send('run-script', {
        scriptPath: scriptPath,
        title: title,
        description: description,
        previousPage: 'storage.html'
    });
}

// Inicializar listeners específicos da página, se necessário
document.addEventListener('DOMContentLoaded', () => {
    // Adicionar quaisquer inicializações específicas da página storage aqui
}); 