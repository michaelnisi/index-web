/**
 * Respect OS appearance
 */

function applySystemTheme() {
  if (window.matchMedia('(prefers-color-scheme: light)').matches) {
    document.documentElement.classList
      .add('light');
  } else {
    document.documentElement.classList
      .remove('light');
  }

  hljs.highlightAll();
}

window
  .matchMedia('(prefers-color-scheme: light)')
  .addEventListener('change', applySystemTheme);

applySystemTheme();
