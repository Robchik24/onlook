#!/bin/sh
# Railway: сервер должен слушать 0.0.0.0:$PORT
# Next.js standalone: server.js в .next/standalone/... (структура зависит от монорепо)

export HOSTNAME=0.0.0.0
export PORT=${PORT:-3000}

STANDALONE="/app/apps/web/client/.next/standalone"

# Ищем server.js (Next.js monorepo: apps/web/client/server.js)
# Используем node — Next.js standalone лучше совместим с Node
SERVER="$STANDALONE/apps/web/client/server.js"
if [ -f "$SERVER" ]; then
  cd "$STANDALONE/apps/web/client" && exec node server.js
elif [ -f "$STANDALONE/server.js" ]; then
  cd "$STANDALONE" && exec node server.js
else
  echo "ERROR: server.js not found. Checked: $SERVER and $STANDALONE/server.js"
  ls -la "$STANDALONE" 2>/dev/null || true
  ls -la "$STANDALONE/apps/web/client" 2>/dev/null || true
  exit 1
fi
