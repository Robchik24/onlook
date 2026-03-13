# Деплой Onlook на Railway

Этот репозиторий адаптирован для развёртывания на [Railway](https://railway.app).

## Отличия от оригинального Onlook

- **Dockerfile**: ARG для build-time переменных, создание `.env`, `bun install` без `--frozen-lockfile`
- **Supabase**: используйте **Connection Pooler** (не Direct) — Railway не поддерживает IPv6

## Быстрый старт

### 1. Создайте проект в Railway

1. [railway.app](https://railway.app) → New Project
2. Deploy from GitHub repo → выберите этот репозиторий (или свой fork)

### 2. Добавьте переменные (Variables)

Обязательные:

| Переменная | Описание |
|------------|----------|
| `CSB_API_KEY` | CodeSandbox API token |
| `SUPABASE_DATABASE_URL` | Connection string из Supabase (Pooler, порт 6543) |
| `SUPABASE_SERVICE_ROLE_KEY` | service_role из Supabase |
| `OPENROUTER_API_KEY` | Ключ OpenRouter |
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL из Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | anon public из Supabase |

Опциональные:

| Переменная | Описание |
|------------|----------|
| `RELACE_API_KEY` | Relace (Fast Apply) |
| `MORPH_API_KEY` | Morph (Fast Apply) |
| `NEXT_PUBLIC_SITE_URL` | URL приложения (например `https://xxx.up.railway.app`). Если не задать — используется `RAILWAY_PUBLIC_DOMAIN` (Railway подставляет автоматически) |

### 3. URL приложения (вместо localhost)

По умолчанию приложение использует `localhost`. Для Railway:

- **Вариант А**: Сначала **Generate Domain** → Railway задаст `RAILWAY_PUBLIC_DOMAIN` → при сборке подставится `https://ваш-домен.up.railway.app`
- **Вариант Б**: Задайте `NEXT_PUBLIC_SITE_URL` в Variables вручную (например `https://onlook-xxx.up.railway.app`)

В Supabase Dashboard → Authentication → URL Configuration добавьте ваш Railway URL в **Redirect URLs**.

### 4. SUPABASE_DATABASE_URL — важно

- Используйте **Connection Pooler** (Supabase Dashboard → Database → Connection string)
- Формат: `postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true`
- Символ `#` в пароле замените на `%23`
- Railway не поддерживает IPv6 — Direct connection (`db.xxx.supabase.co`) не работает

### 5. Custom Start Command (миграции)

Settings → Deploy → Custom Start Command:

```
bun db:push && /start-server.sh
```

> **Если таблицы уже применены** — уберите Custom Start Command, чтобы использовался стандартный CMD (`/start-server.sh`).

### 6. Generate Domain

Settings → Networking → Generate Domain (сделайте это до первого деплоя, чтобы `RAILWAY_PUBLIC_DOMAIN` попал в сборку)

### 7. Target Port (при 502)

Settings → Networking → ваш домен → **Port** должен быть `3000` (или значение `PORT` из Variables). Если порт неверный — будет `connection dial timeout`.

## Troubleshooting

| Ошибка | Решение |
|--------|---------|
| `lockfile had changes, but lockfile is frozen` | Уже исправлено — используется `bun install` без `--frozen-lockfile` |
| `Invalid environment variables` | Добавьте все 6 обязательных переменных с точными именами |
| `ECONNREFUSED` / IPv6 | Используйте Supabase Connection Pooler, не Direct |
| `password authentication failed` | Username для pooler: `postgres.[project-ref]`, не `postgres` |
| `Tenant or user not found` | Проверьте формат connection string, используйте pooler |
| **502 Bad Gateway** / **connection dial timeout** | 1) **View Logs** — проверьте, что сервер запустился без ошибок. 2) **Target Port**: Settings → Networking → ваш домен → **Port** = 3000. 3) Сервер слушает `0.0.0.0:$PORT` через `/start-server.sh`. 4) Уберите Custom Start Command для теста. |
| **Module not found server.js** | Исправлено: при сборке `find` ищет server.js и создаёт `/start-server.sh` с правильным путём. Если сборка падает — смотрите логи build на строку "server.js NOT FOUND" и вывод `find`/`ls`. |
| **sitemap.xml / response.blob** | `sitemap.ts` удалён (баг Next.js 16 + Bun). Используется статический `public/sitemap.xml`. Для своего домена замените `https://onlook.com` в нём на ваш URL. |
