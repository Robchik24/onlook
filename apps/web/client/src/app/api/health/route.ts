/** Лёгкий endpoint для Railway/Docker healthcheck — без зависимостей, быстрый ответ */
export async function GET() {
    return Response.json({ ok: true }, { status: 200 });
}
