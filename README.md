# Getting Started with Create React App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: [https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here: [https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here: [https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here: [https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here: [https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)

### `npm run build` fails to minify

This section has moved here: [https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify](https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify)
..
name: Build and Deploy Fullstack App

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Build React Frontend Docker image
        run: docker build -t react-frontend:${{ github.sha }} .
        working-directory: ./frontend

      - name: Build Backend API Docker  image
        run: docker build -t backend-api:${{ github.sha }} .
        working-directory: ./backend

      - name: Save and compress React Frontend image
        run: |
          docker save react-frontend:${{ github.sha }} -o react-frontend.tar
          gzip react-frontend.tar

      - name: Save and compress Backend API image
        run: |
          docker save backend-api:${{ github.sha }} -o backend-api.tar
          gzip backend-api.tar

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: docker-images
          path: |
            react-frontend.tar.gz
            backend-api.tar.gz

  deploy-vm1:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: docker-images
          path: .

      - name: Copy Docker images to VM1
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.VM1_IP }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
           source:react-frontend.tar.gz
          target: ~/
         

      - name: Deploy containers on VM1
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.VM1_IP }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
           mkdir -p ~/react-app/dist
           tar -xzf ~/react-frontend.tar.gz -C ~/react-app/dist
           rm ~/react-frontend.tar.gz
           sudo systemctl restart nginx
            set -e
            cd /home/${{ secrets.SSH_USER }}

            # Charger les images
            gunzip -c react-frontend.tar.gz | docker load
            gunzip -c backend-api.tar.gz | docker load

            # Supprimer anciens conteneurs si existent
            docker rm -f react-frontend || true
            docker rm -f backend-api || true

            # Lancer les containers
            docker run -d --name react-frontend -p 80:80 react-frontend:${{ github.sha }}
            docker run -d --name backend-api -p 3000:3000 backend-api:${{ github.sha }}

  deploy-vm2:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: docker-images
          path: .

      - name: Copy Docker images to VM2
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.VM2_IP }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: "*.tar.gz"
          target: /home/${{ secrets.SSH_USER }}/

      - name: Deploy containers on VM2
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.VM2_IP }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            set -e
            cd /home/${{ secrets.SSH_USER }}

            # Charger les images
            gunzip -c react-frontend.tar.gz | docker load
            gunzip -c backend-api.tar.gz | docker load

            # Supprimer anciens conteneurs si existent
            docker rm -f react-frontend || true
            docker rm -f backend-api || true

            # Lancer les containers
            docker run -d --name react-frontend -p 80:80 react-frontend:${{ github.sha }}
            docker run -d --name backend-api -p 3000:3000 backend-api:${{ github.sha }}