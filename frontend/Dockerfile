# Étape 1 : Build de l'app React
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --frozen-lockfile
COPY . .
RUN npm run build

# Étape 2 : Serveur nginx
FROM nginx:alpine

# Supprimer la config par défaut de nginx
RUN rm -rf /usr/share/nginx/html/*

# Copier les fichiers buildés dans nginx
COPY --from=build /app/build /usr/share/nginx/html

# Exposer le port
EXPOSE 80

# Lancer nginx
CMD ["nginx", "-g", "daemon off;"]
