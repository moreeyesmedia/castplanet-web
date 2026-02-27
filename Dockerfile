# Fixed CastPlanet Web Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy and install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source and build for web
COPY . .
RUN npx expo export --platform web

# Production stage
FROM nginx:alpine

# Copy the built web app (Expo creates 'dist' directory)
COPY --from=builder /app/dist /usr/share/nginx/html

# Create nginx config that serves all files properly
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Main route \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Static assets \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|json)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
        try_files $uri =404; \
    } \
    \
    # Expo assets \
    location /_expo/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
        try_files $uri =404; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]