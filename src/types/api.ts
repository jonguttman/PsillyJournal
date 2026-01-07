// PsillyOps Internal API Types
// Based on API spec from PsillyOps team

/**
 * Entity type for QR token resolution
 */
export type EntityType = 'PRODUCT' | 'BATCH' | 'INVENTORY';

/**
 * Response from GET /api/internal/products/by-qr/{qr_token}
 */
export interface PsillyOpsProductResponse {
  product_id: string;
  name: string;
  sku?: string;
  description?: string | null;
  batch_id?: string | null;
  token: string; // qr_xxxxxxxxxxxxxxxxxxxxxx
  entity_type: EntityType;
}

/**
 * Error response from PsillyOps API
 */
export interface PsillyOpsErrorResponse {
  code: string;
  message: string;
}

/**
 * API Error codes
 * 401 - missing/invalid auth (UNAUTHORIZED)
 * 404 - token not found (QR_TOKEN_NOT_FOUND)
 * 410 - token revoked or expired (QR_TOKEN_INACTIVE)
 */
export type PsillyOpsErrorCode = 401 | 404 | 410;

/**
 * Mapped product info for app use
 * Transforms API response to our internal format
 */
export interface ProductInfo {
  product_id: string;
  name: string;
  sku?: string;
  description?: string | null;
  batch_id?: string | null;
  entity_type: EntityType;
}

/**
 * Convert API response to app ProductInfo
 */
export function mapApiResponseToProductInfo(
  response: PsillyOpsProductResponse
): ProductInfo {
  return {
    product_id: response.product_id,
    name: response.name,
    sku: response.sku,
    description: response.description,
    batch_id: response.batch_id,
    entity_type: response.entity_type,
  };
}
