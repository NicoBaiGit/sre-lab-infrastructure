document$.subscribe(() => {
  // Fonction pour initialiser Mermaid
  const initMermaid = () => {
    const body = document.querySelector("body");
    const theme = body.getAttribute("data-md-color-scheme") === "slate" ? "dark" : "default";
    mermaid.initialize({
      startOnLoad: true,
      theme: theme,
      securityLevel: 'loose',
    });
  };

  initMermaid();

  // Observer pour recharger la page au changement de thème
  // (Nécessaire car Mermaid génère du SVG statique qui ne s'adapte pas dynamiquement)
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === "attributes" && mutation.attributeName === "data-md-color-scheme") {
        location.reload();
      }
    });
  });

  observer.observe(document.querySelector("body"), {
    attributes: true,
    attributeFilter: ["data-md-color-scheme"]
  });
});