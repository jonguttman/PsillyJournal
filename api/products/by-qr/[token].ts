/**
 * API Route: GET /api/products/by-qr/[token]
 * 
 * Proxies requests to PsillyOps Internal API.
 * Adds INTERNAL_SERVICE_TOKEN server-side so it's never exposed to client.
 * 
 * This is a Vercel serverless function.
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';

// PsillyOps API configuration
// Using production URL with staging-scoped token for testing
const PSILLYOPS_API_BASE = process.env.PSILLYOPS_API_URL || 'https://ops.originalpsilly.com';
const INTERNAL_SERVICE_TOKEN = process.env.PSILLYOPS_SERVICE_TOKEN;

// Token format validation
const TOKEN_PATTERN = /^qr_[a-zA-Z0-9]{20,30}$/;

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // Only allow GET
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Extract token from URL
  const { token } = req.query;
  
  if (!token || typeof token !== 'string') {
    return res.status(400).json({ error: 'Missing token parameter' });
  }

  // Validate token format
  if (!TOKEN_PATTERN.test(token)) {
    return res.status(400).json({ error: 'Invalid token format' });
  }

  // Check service token is configured
  if (!INTERNAL_SERVICE_TOKEN) {
    console.error('[API] PSILLYOPS_SERVICE_TOKEN not configured');
    return res.status(500).json({ error: 'Service configuration error' });
  }

  try {
    // Call PsillyOps Internal API
    const response = await fetch(
      `${PSILLYOPS_API_BASE}/api/internal/products/by-qr/${token}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${INTERNAL_SERVICE_TOKEN}`,
          'Content-Type': 'application/json',
        },
      }
    );

    // Forward error status codes
    if (!response.ok) {
      const status = response.status;
      
      switch (status) {
        case 401:
          console.error('[API] PsillyOps auth failed - check service token');
          return res.status(401).json({ error: 'Authentication failed' });
        case 404:
          return res.status(404).json({ error: 'Product not found' });
        case 410:
          return res.status(410).json({ error: 'Token revoked or expired' });
        default:
          console.error('[API] PsillyOps error:', status);
          return res.status(status).json({ error: 'Upstream error' });
      }
    }

    // Forward successful response
    const data = await response.json();
    
    // Set cache headers (adjust TTL as confirmed by PsillyOps)
    res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate');
    
    return res.status(200).json(data);
    
  } catch (error) {
    console.error('[API] Failed to fetch from PsillyOps:', error);
    return res.status(502).json({ error: 'Failed to reach product service' });
  }
}
