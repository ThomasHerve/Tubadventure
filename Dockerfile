# Stage final - serveur web
FROM nginx:alpine

# Configuration NGINX pour WebGL Unity
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;

    # Gzip compression pour les fichiers WebGL
    gzip on;
    gzip_types text/plain text/css text/javascript application/json application/javascript;
    gzip_min_length 1000;

    # Headers nécessaires pour WebGL et les .wasm
    add_header Cross-Origin-Opener-Policy same-origin;
    add_header Cross-Origin-Embedder-Policy require-corp;
    add_header Cache-Control "public, max-age=3600";

    root /usr/share/nginx/html;
    index index.html;

    # Configuration pour les fichiers .wasm.br (WebAssembly compressé Brotli)
    location ~ \.wasm\.br$ {
        default_type application/wasm;
        add_header Content-Encoding "br" always;
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        expires 1h;
    }

    # Configuration pour les fichiers .wasm avec le bon MIME type
    location ~ \.wasm$ {
        default_type application/wasm;
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        expires 1h;
    }

    # Configuration pour les fichiers .data.br (Data compressé)
    location ~ \.data\.br$ {
        add_header Content-Encoding "br" always;
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        expires 1h;
    }

    # Configuration pour les fichiers .framework.js.br (Framework compressé)
    location ~ \.framework\.js\.br$ {
        default_type text/javascript;
        add_header Content-Encoding "br" always;
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        expires 1h;
    }

    # Fichiers JavaScript
    location ~ \.js$ {
        add_header Cache-Control "public, max-age=3600";
        expires 1h;
    }

    # Fichiers HTML - pas de cache
    location ~ \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires -1;
    }

    # Fallback vers index.html pour le routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF

# Copier les fichiers de la build WebGL
COPY Tubadventure-Web/ /usr/share/nginx/html/

EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
