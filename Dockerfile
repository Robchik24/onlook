FROM oven/bun:1

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV STANDALONE_BUILD=true
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

ARG CSB_API_KEY
ARG SUPABASE_DATABASE_URL
ARG SUPABASE_SERVICE_ROLE_KEY
ARG OPENROUTER_API_KEY
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY

COPY . .

RUN printf 'CSB_API_KEY=%s\nSUPABASE_DATABASE_URL=%s\nSUPABASE_SERVICE_ROLE_KEY=%s\nOPENROUTER_API_KEY=%s\nNEXT_PUBLIC_SUPABASE_URL=%s\nNEXT_PUBLIC_SUPABASE_ANON_KEY=%s\n' \
    "$CSB_API_KEY" "$SUPABASE_DATABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" \
    "$OPENROUTER_API_KEY" "$NEXT_PUBLIC_SUPABASE_URL" "$NEXT_PUBLIC_SUPABASE_ANON_KEY" \
    > apps/web/client/.env

RUN bun install
RUN cd apps/web/client && bun run build:standalone

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bun -e "fetch('http://localhost:3000').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["bun", "apps/web/client/server.js"]
