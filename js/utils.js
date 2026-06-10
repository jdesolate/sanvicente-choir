export function formatDate(dateStr) {}

export function showAlert(message, type = 'info') {}

export function clearAlerts() {}

export function hidePageLoader() {
  const loader = document.getElementById('page-loader');
  if (!loader) return;
  loader.classList.add('fade-out');
  setTimeout(() => loader.remove(), 320);
}
