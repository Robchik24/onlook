# Onlook — Railway-совместимый Dockerfile
# Railway передаёт Variables как build args, создаём .env для сборки

FROM oven/bun:1

# Node.js для Next.js standalone server (bun server.js может давать "Module not found")
RUN apt-get update && apt-get install -y --no-install-recommends nodejs ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV STANDALONE_BUILD=true
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

# Build args — Railway передаёт Variables как build args
ARG CSB_API_KEY
ARG SUPABASE_DATABASE_URL
ARG SUPABASE_SERVICE_ROLE_KEY
ARG OPENROUTER_API_KEY
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
# URL приложения — задайте после Generate Domain (например https://xxx.up.railway.app)
ARG NEXT_PUBLIC_SITE_URL=""
ARG RAILWAY_PUBLIC_DOMAIN=""

COPY . .

# Создаём .env (Onlook проверяет переменные при сборке)
# NEXT_PUBLIC_SITE_URL: задайте в Variables или Railway подставит RAILWAY_PUBLIC_DOMAIN
RUN printf 'CSB_API_KEY=%s\nSUPABASE_DATABASE_URL=%s\nSUPABASE_SERVICE_ROLE_KEY=%s\nOPENROUTER_API_KEY=%s\nNEXT_PUBLIC_SUPABASE_URL=%s\nNEXT_PUBLIC_SUPABASE_ANON_KEY=%s\n' \
    "$CSB_API_KEY" "$SUPABASE_DATABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" \
    "$OPENROUTER_API_KEY" "$NEXT_PUBLIC_SUPABASE_URL" "$NEXT_PUBLIC_SUPABASE_ANON_KEY" \
    > apps/web/client/.env && \
    ( [ -n "$NEXT_PUBLIC_SITE_URL" ] && echo "NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL" >> apps/web/client/.env || \
      [ -n "$RAILWAY_PUBLIC_DOMAIN" ] && echo "NEXT_PUBLIC_SITE_URL=https://$RAILWAY_PUBLIC_DOMAIN" >> apps/web/client/.env || true )

# bun install без --frozen-lockfile (Railway использует другую версию Bun)
RUN bun install

RUN cd apps/web/client && bun run build:standalone

# Найти server.js и создать скрипт запуска (структура standalone может отличаться)
RUN SERVER=$(find /app -name "server.js" -path "*standalone*" -type f 2>/dev/null | head -1) && \
    if [ -z "$SERVER" ]; then \
      echo "=== server.js NOT FOUND ===" && \
      find /app/apps/web/client/.next -type f -name "*.js" 2>/dev/null | head -20 && \
      ls -la /app/apps/web/client/.next/standalone/ 2>/dev/null || true && \
      exit 1; \
    fi && \
    echo "Found: $SERVER" && \
    echo "#!/bin/sh" > /start-server.sh && \
    echo "cd $(dirname $SERVER)" >> /start-server.sh && \
    echo "export HOSTNAME=0.0.0.0" >> /start-server.sh && \
    echo "export PORT=\${PORT:-3000}" >> /start-server.sh && \
    echo "exec node server.js" >> /start-server.sh && \
    chmod +x /start-server.sh

EXPOSE 3000

# Healthcheck — bun fetch (start-period 60s даёт время на старт)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD bun -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/api/health').then(r=>r.ok?process.exit(0):process.exit(1)).catch(()=>process.exit(1))"

# Standalone server — 0.0.0.0:$PORT (Railway требует)
# /start-server.sh создаётся на этапе сборки с правильным путём к server.js
CMD ["/start-server.sh"]
