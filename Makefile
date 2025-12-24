.PHONY: install serve build clean

# Installation des dépendances
install:
	pip install -r requirements.txt

# Lancer le serveur de développement local
serve:
	mkdocs serve

# Construire le site statique (dans le dossier site/)
build:
	mkdocs build

# Nettoyer le dossier de build
clean:
	rm -rf site/
