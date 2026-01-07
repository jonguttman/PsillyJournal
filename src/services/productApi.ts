import { API_CONFIG } from '../config';
import type { QRToken } from '../types';
import type { PsillyOpsProductResponse, ProductInfo } from '../types/api';

/**
 * Mock product data for development
 * Using real test tokens from PsillyOps staging
 */
const MOCK_PRODUCTS: Record<string, PsillyOpsProductResponse> = {
  // Token 1: Tea - Third Eye Chai
  'qr_POcQ38aDUKrqeyFQJibNKK': {
    product_id: 'cmjqh6dyj0003jy04kpq23nyl',
    name: 'Tea - Third Eye Chai',
    sku: 'G779424',
    token: 'qr_POcQ38aDUKrqeyFQJibNKK',
    entity_type: 'PRODUCT',
  },
  // Token 2: Tea - Variety Pack - 6 Pack
  'qr_h0kVYOFStvpRyXbLemYI6V': {
    product_id: 'cmjqgyqvh0003lg04u61qo59e',
    name: 'Tea - Variety Pack - 6 Pack',
    sku: 'G779425',
    token: 'qr_h0kVYOFStvpRyXbLemYI6V',
    entity_type: 'PRODUCT',
  },
  // Token 3: Tea - Chamomile Magic - 2 Pack
  'qr_1IuHOSaweSUj98jZVSLGuJ': {
    product_id: 'cmjqgw8t70001jy04wgvvy5x6',
    name: 'Tea - Chamomile Magic - 2 Pack',
    sku: 'G779426',
    token: 'qr_1IuHOSaweSUj98jZVSLGuJ',
    entity_type: 'PRODUCT',
  },
};

// Simple in-memory cache for product info
const productCache = new Map<string, { data: ProductInfo; timestamp: number }>();

/**
 * Check if cached data is still valid
 */
function getCachedProduct(token: string): ProductInfo | null {
  const cached = productCache.get(token);
  if (!cached) return null;
  
  const isExpired = Date.now() - cached.timestamp > API_CONFIG.PRODUCT_CACHE_TTL;
  if (isExpired) {
    productCache.delete(token);
    return null;
  }
  
  return cached.data;
}

/**
 * Cache product info
 */
function cacheProduct(token: string, data: ProductInfo): void {
  productCache.set(token, { data, timestamp: Date.now() });
}

/**
 * Fetch product information from PsillyOps API
 * 
 * NOTE: In production, this calls OUR backend proxy,
 * which then calls PsillyOps with the service token.
 * The INTERNAL_SERVICE_TOKEN should never be in client code.
 * 
 * @param token - QR token from scanned bottle
 * @returns ProductInfo or null if not found
 */
export async function fetchProductInfo(token: QRToken): Promise<ProductInfo | null> {
  // Check cache first
  const cached = getCachedProduct(token);
  if (cached) {
    console.log('[ProductAPI] Cache hit for token:', token);
    return cached;
  }

  // In development, use mock data
  if (__DEV__) {
    console.log('[ProductAPI] Using mock data for token:', token);
    
    // Simulate network delay
    await new Promise((resolve) => setTimeout(resolve, 500));
    
    // Check mock data
    const mockResponse = MOCK_PRODUCTS[token];
    if (mockResponse) {
      const productInfo: ProductInfo = {
        product_id: mockResponse.product_id,
        name: mockResponse.name,
        sku: mockResponse.sku,
        description: mockResponse.description ?? null,
        batch_id: mockResponse.batch_id ?? null,
        entity_type: mockResponse.entity_type,
      };
      cacheProduct(token, productInfo);
      return productInfo;
    }
    
    // Generate mock product for unknown tokens (dev only)
    const devProduct: ProductInfo = {
      product_id: `prod_dev_${token.slice(3, 10)}`,
      name: 'Development Product',
      description: 'Mock product for development testing',
      batch_id: null,
      entity_type: 'PRODUCT',
    };
    cacheProduct(token, devProduct);
    return devProduct;
  }

  // Production: call our backend proxy
  // Our backend will add the INTERNAL_SERVICE_TOKEN and call PsillyOps
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), API_CONFIG.TIMEOUT);

    const response = await fetch(
      `${API_CONFIG.PSILLYOPS_INTERNAL_API}/by-qr/${token}`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: controller.signal,
      }
    );

    clearTimeout(timeoutId);

    // Handle error responses per API spec
    if (!response.ok) {
      switch (response.status) {
        case 401:
          console.error('[ProductAPI] Auth error - check service token');
          return null;
        case 404:
          console.warn('[ProductAPI] Token not found:', token);
          return null;
        case 410:
          console.warn('[ProductAPI] Token revoked or expired:', token);
          return null;
        default:
          console.error('[ProductAPI] Unexpected error:', response.status);
          return null;
      }
    }

    const data: PsillyOpsProductResponse = await response.json();
    
    // Map to our internal format
    const productInfo: ProductInfo = {
      product_id: data.product_id,
      name: data.name,
      sku: data.sku,
      description: data.description ?? null,
      batch_id: data.batch_id ?? null,
      entity_type: data.entity_type,
    };
    
    // Cache the result
    cacheProduct(token, productInfo);
    
    return productInfo;
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      console.error('[ProductAPI] Request timeout');
    } else {
      console.error('[ProductAPI] Failed to fetch product:', error);
    }
    return null;
  }
}

/**
 * Validate a product exists (lightweight check)
 */
export async function validateProduct(token: QRToken): Promise<boolean> {
  const product = await fetchProductInfo(token);
  return product !== null;
}

/**
 * Check if we can reach the product API
 */
export async function checkApiHealth(): Promise<boolean> {
  if (__DEV__) {
    return true;
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(`${API_CONFIG.BASE_URL}/health`, {
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Clear the product cache (useful for testing or forced refresh)
 */
export function clearProductCache(): void {
  productCache.clear();
}
