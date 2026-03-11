import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
    return {
        rules: [
            {
                userAgent: '*',
                allow: '/',
                disallow: '/private/',
            },
            {
                userAgent: 'Googlebot',
                allow: '/',
            },
            {
                userAgent: 'Bingbot',
                allow: '/',
            },
            {
                userAgent: 'GPTBot',
                allow: '/',
            },
            {
                userAgent: 'ChatGPT-User',
                allow: '/',
            },
            {
                userAgent: 'Google-Extended',
                allow: '/',
            },
            {
                userAgent: 'PerplexityBot',
                allow: '/',
            },
            {
                userAgent: 'Amazonbot',
                allow: '/',
            },
            {
                userAgent: 'anthropic-ai',
                allow: '/',
            },
            {
                userAgent: 'cohere-ai',
                allow: '/',
            },
        ],
        sitemap: [
            'https://www.wanderwith.online/sitemap.xml',
        ],
    }
}
