import type { QRToken, QRScanResult } from '../types';

/**
 * PsillyOps QR URL pattern
 * Format: https://ops.originalpsilly.com/qr/qr_[22 alphanumeric chars]
 */
const PSILLYOPS_BASE_URL = 'https://ops.originalpsilly.com/qr/';
const TOKEN_PATTERN = /^qr_[a-zA-Z0-9]{20,30}$/;

/**
 * Extract token from a PsillyOps QR URL
 * 
 * CRITICAL: This function extracts the token WITHOUT navigating to the URL.
 * The browser should NEVER be opened when scanning in-app.
 * 
 * @param scannedData - Raw data from QR scanner (should be a URL)
 * @returns QRScanResult with token or error
 */
export function extractQRToken(scannedData: string): QRScanResult {
  // Trim whitespace
  const data = scannedData.trim();

  // Validate URL starts with PsillyOps base
  if (!data.startsWith(PSILLYOPS_BASE_URL)) {
    return {
      success: false,
      error: 'Invalid QR code. Please scan a Psilly product bottle.',
    };
  }

  // Extract token (everything after /qr/)
  const token = data.slice(PSILLYOPS_BASE_URL.length);

  // Validate token format
  if (!token || token.length === 0) {
    return {
      success: false,
      error: 'Invalid QR code format - missing token.',
    };
  }

  if (!TOKEN_PATTERN.test(token)) {
    return {
      success: false,
      error: 'Invalid QR code format - malformed token.',
    };
  }

  return {
    success: true,
    token: token as QRToken,
  };
}

/**
 * Validate a token string matches expected format
 */
export function isValidToken(token: string): token is QRToken {
  return TOKEN_PATTERN.test(token);
}

/**
 * Extract token from a deep link URL
 * Format: https://journal.originalpsilly.com/bottle/{token}
 * or: psillyjournal://bottle/{token}
 */
export function extractTokenFromDeepLink(url: string): QRScanResult {
  const universalPattern = /^https:\/\/journal\.originalpsilly\.com\/bottle\/(.+)$/;
  const schemePattern = /^psillyjournal:\/\/bottle\/(.+)$/;

  let match = url.match(universalPattern) || url.match(schemePattern);

  if (!match || !match[1]) {
    return {
      success: false,
      error: 'Invalid deep link format.',
    };
  }

  const token = match[1];

  if (!TOKEN_PATTERN.test(token)) {
    return {
      success: false,
      error: 'Invalid token in deep link.',
    };
  }

  return {
    success: true,
    token: token as QRToken,
  };
}

/**
 * Build the full PsillyOps URL from a token
 * (For display/debugging only - never navigate to this)
 */
export function buildPsillyOpsUrl(token: QRToken): string {
  return `${PSILLYOPS_BASE_URL}${token}`;
}
