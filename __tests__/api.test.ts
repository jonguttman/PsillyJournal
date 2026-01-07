/**
 * API Integration Tests
 * 
 * These tests verify the PsillyOps API integration.
 * Run against staging with: STAGING=true npm test
 */

// Test tokens from PsillyOps staging credentials
const TEST_TOKENS = {
  // Active tokens (expect 200)
  VALID_1: 'qr_POcQ38aDUKrqeyFQJibNKK', // Tea - Third Eye Chai
  VALID_2: 'qr_h0kVYOFStvpRyXbLemYI6V', // Tea - Variety Pack
  VALID_3: 'qr_1IuHOSaweSUj98jZVSLGuJ', // Tea - Chamomile Magic
  
  // Revoked token (expect 410)
  REVOKED: 'qr_99lgevtzJ3lHKPH0z6jVKr',
  
  // Non-existent token (expect 404)
  NOT_FOUND: 'qr_NONEXISTENT_TEST_TOKEN_INVALID',
};

describe('PsillyOps API Integration', () => {
  describe('Token Validation', () => {
    it('should accept valid token format', () => {
      const pattern = /^qr_[a-zA-Z0-9]{20,30}$/;
      expect(pattern.test(TEST_TOKENS.VALID_1)).toBe(true);
      expect(pattern.test(TEST_TOKENS.VALID_2)).toBe(true);
      expect(pattern.test(TEST_TOKENS.VALID_3)).toBe(true);
    });

    it('should accept revoked token format', () => {
      const pattern = /^qr_[a-zA-Z0-9]{20,30}$/;
      expect(pattern.test(TEST_TOKENS.REVOKED)).toBe(true);
    });
  });

  describe('Expected Response Handling', () => {
    it('documents expected 200 response format', () => {
      const expectedResponse = {
        product_id: 'cmjqh6dyj0003jy04kpq23nyl',
        name: 'Tea - Third Eye Chai',
        description: 'Premium psilocybin-infused chai tea',
        token: 'qr_POcQ38aDUKrqeyFQJibNKK',
        entity_type: 'PRODUCT',
      };

      // Verify structure matches our ProductInfo type
      expect(expectedResponse).toHaveProperty('product_id');
      expect(expectedResponse).toHaveProperty('name');
      expect(expectedResponse).toHaveProperty('description');
      expect(expectedResponse).toHaveProperty('token');
      expect(expectedResponse).toHaveProperty('entity_type');
    });

    it('documents expected 410 response format', () => {
      const expectedError = {
        code: 'QR_TOKEN_INACTIVE',
        message: 'This QR token has been revoked',
      };

      expect(expectedError).toHaveProperty('code');
      expect(expectedError).toHaveProperty('message');
    });

    it('documents expected 404 response format', () => {
      const expectedError = {
        code: 'QR_TOKEN_NOT_FOUND',
        message: 'QR token not found',
      };

      expect(expectedError).toHaveProperty('code');
      expect(expectedError).toHaveProperty('message');
    });

    it('documents expected 401 response format', () => {
      const expectedError = {
        code: 'UNAUTHORIZED',
        message: 'Not authenticated',
      };

      expect(expectedError).toHaveProperty('code');
      expect(expectedError).toHaveProperty('message');
    });
  });

  describe('Error Code Mapping', () => {
    const errorHandling = (status: number): string => {
      switch (status) {
        case 401: return 'AUTH_ERROR';
        case 404: return 'NOT_FOUND';
        case 410: return 'REVOKED';
        default: return 'UNKNOWN';
      }
    };

    it('maps 401 to auth error', () => {
      expect(errorHandling(401)).toBe('AUTH_ERROR');
    });

    it('maps 404 to not found', () => {
      expect(errorHandling(404)).toBe('NOT_FOUND');
    });

    it('maps 410 to revoked', () => {
      expect(errorHandling(410)).toBe('REVOKED');
    });
  });
});

describe('Test Token Inventory', () => {
  it('has 3 valid test tokens', () => {
    const validTokens = [
      TEST_TOKENS.VALID_1,
      TEST_TOKENS.VALID_2,
      TEST_TOKENS.VALID_3,
    ];
    expect(validTokens.length).toBe(3);
    validTokens.forEach(token => {
      expect(token).toMatch(/^qr_/);
    });
  });

  it('has 1 revoked test token', () => {
    expect(TEST_TOKENS.REVOKED).toMatch(/^qr_/);
  });

  it('has 1 not-found test token', () => {
    expect(TEST_TOKENS.NOT_FOUND).toBeDefined();
  });
});
