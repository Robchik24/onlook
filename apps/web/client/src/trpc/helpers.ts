import { httpBatchStreamLink, loggerLink } from '@trpc/client';
import SuperJSON from 'superjson';

export function getBaseUrl() {
    if (typeof window !== 'undefined') return window.location.origin;
    if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`;
    if (process.env.RAILWAY_PUBLIC_DOMAIN) return `https://${process.env.RAILWAY_PUBLIC_DOMAIN}`;
    if (process.env.NEXT_PUBLIC_SITE_URL) return process.env.NEXT_PUBLIC_SITE_URL;
    return `http://localhost:${process.env.PORT ?? 3000}`;
}

export const links = [
    loggerLink({
        enabled: (op) =>
            process.env.NODE_ENV === 'development' ||
            (op.direction === 'down' && op.result instanceof Error),
    }),
    httpBatchStreamLink({
        transformer: SuperJSON,
        url: getBaseUrl() + '/api/trpc',
        headers: () => {
            const headers = new Headers();
            headers.set('x-trpc-source', 'vanilla-client');
            return headers;
        },
    }),
];
