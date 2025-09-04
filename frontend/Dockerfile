# frontend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

ENV REACT_APP_BACKEND_URL=http://localhost:8000/api

EXPOSE 3000

CMD ["npm", "start"]
