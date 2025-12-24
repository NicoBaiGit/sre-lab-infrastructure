# SRE Lab Infrastructure Documentation

Ce dépôt contient la documentation et les configurations pour mon laboratoire SRE personnel.

Le site est généré avec [MkDocs](https://www.mkdocs.org/) et le thème [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## Structure

*   `docs/` : Contient les fichiers sources Markdown de la documentation.
*   `mkdocs.yml` : Configuration du site.
*   `Makefile` : Commandes utilitaires.

## Utilisation

### Prérequis

*   Python 3.x
*   pip

### Installation

```bash
make install
```

### Lancer le serveur local

Pour visualiser la documentation en direct pendant l'édition :

```bash
make serve
```
Le site sera accessible sur `http://127.0.0.1:8000`.

### Générer le site

Pour construire les fichiers HTML statiques :

```bash
make build
```
