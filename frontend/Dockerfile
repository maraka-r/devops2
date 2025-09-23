# ---------- Stage 1: Build React ----------
FROM node:18-alpine AS build

# Définir le dossier de travail
WORKDIR /app

# Copier seulement les fichiers de dépendances pour utiliser le cache Docker
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm ci --cache /tmp/npm-cache

# Copier tout le code source
COPY . .

# Builder l'application React pour la production
RUN npm run build

# ---------- Stage 2: Serve avec Nginx ----------
FROM nginx:alpine

# Supprimer la config Nginx par défaut
RUN rm -rf /usr/share/nginx/html/*

# Copier les fichiers build de React dans Nginx
COPY --from=build /app/build /usr/share/nginx/html

# Copier un fichier de config Nginx personnalisé (optionnel)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Lancer Nginx en mode foreground
CMD ["nginx", "-g", "daemon off;"]
