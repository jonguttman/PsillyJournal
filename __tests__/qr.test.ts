import { extractQRToken, extractTokenFromDeepLink, isValidToken } from '../src/utils/qr';

// Real test tokens from PsillyOps staging
const TEST_TOKENS = {
  VALID_1: 'qr_POcQ38aDUKrqeyFQJibNKK', // Tea - Third Eye Chai
  VALID_2: 'qr_h0kVYOFStvpRyXbLemYI6V', // Tea - Variety Pack
  VALID_3: 'qr_1IuHOSaweSUj98jZVSLGuJ', // Tea - Chamomile Magic
};

describe('QR Token Extraction', () => {
  describe('extractQRToken', () => {
    it('extracts token from valid PsillyOps URL', () => {
      const url = `https://ops.originalpsilly.com/qr/${TEST_TOKENS.VALID_1}`;
      const result = extractQRToken(url);
      
      expect(result.success).toBe(true);
      expect(result.token).toBe(TEST_TOKENS.VALID_1);
      expect(result.error).toBeUndefined();
    });

    it('extracts token from URL with different token', () => {
      const url = `https://ops.originalpsilly.com/qr/${TEST_TOKENS.VALID_2}`;
      const result = extractQRToken(url);
      
      expect(result.success).toBe(true);
      expect(result.token).toBe(TEST_TOKENS.VALID_2);
    });

    it('rejects URL from wrong domain', () => {
      const url = 'https://example.com/qr/qr_yGg4unBIVbsr7ezUs40UKb';
      const result = extractQRToken(url);
      
      expect(result.success).toBe(false);
      expect(result.token).toBeUndefined();
      expect(result.error).toContain('Invalid QR code');
    });

    it('rejects URL with missing token', () => {
      const url = 'https://ops.originalpsilly.com/qr/';
      const result = extractQRToken(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('missing token');
    });

    it('rejects URL with malformed token (too short)', () => {
      const url = 'https://ops.originalpsilly.com/qr/qr_short';
      const result = extractQRToken(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('malformed token');
    });

    it('rejects URL with token missing qr_ prefix', () => {
      const url = 'https://ops.originalpsilly.com/qr/yGg4unBIVbsr7ezUs40UKb';
      const result = extractQRToken(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('malformed token');
    });

    it('rejects plain text that is not a URL', () => {
      const data = 'This is not a URL';
      const result = extractQRToken(data);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('Invalid QR code');
    });

    it('handles URL with trailing whitespace', () => {
      const url = `https://ops.originalpsilly.com/qr/${TEST_TOKENS.VALID_3}   `;
      const result = extractQRToken(url);
      
      expect(result.success).toBe(true);
      expect(result.token).toBe(TEST_TOKENS.VALID_3);
    });

    it('rejects non-PsillyOps product QR code', () => {
      const url = 'https://www.amazon.com/product/B0123456789';
      const result = extractQRToken(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('Please scan a Psilly product');
    });
  });

  describe('extractTokenFromDeepLink', () => {
    it('extracts token from universal link', () => {
      const url = `https://journal.originalpsilly.com/bottle/${TEST_TOKENS.VALID_1}`;
      const result = extractTokenFromDeepLink(url);
      
      expect(result.success).toBe(true);
      expect(result.token).toBe(TEST_TOKENS.VALID_1);
    });

    it('extracts token from URL scheme', () => {
      const url = `psillyjournal://bottle/${TEST_TOKENS.VALID_2}`;
      const result = extractTokenFromDeepLink(url);
      
      expect(result.success).toBe(true);
      expect(result.token).toBe(TEST_TOKENS.VALID_2);
    });

    it('rejects deep link from wrong domain', () => {
      const url = `https://example.com/bottle/${TEST_TOKENS.VALID_1}`;
      const result = extractTokenFromDeepLink(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('Invalid deep link');
    });

    it('rejects deep link with invalid token', () => {
      const url = 'https://journal.originalpsilly.com/bottle/invalid';
      const result = extractTokenFromDeepLink(url);
      
      expect(result.success).toBe(false);
      expect(result.error).toContain('Invalid token');
    });
  });

  describe('isValidToken', () => {
    it('validates correct token format', () => {
      expect(isValidToken(TEST_TOKENS.VALID_1)).toBe(true);
      expect(isValidToken(TEST_TOKENS.VALID_2)).toBe(true);
      expect(isValidToken(TEST_TOKENS.VALID_3)).toBe(true);
    });

    it('rejects invalid token formats', () => {
      expect(isValidToken('invalid')).toBe(false);
      expect(isValidToken('qr_short')).toBe(false);
      expect(isValidToken('yGg4unBIVbsr7ezUs40UKb')).toBe(false);
      expect(isValidToken('')).toBe(false);
    });
  });
});

describe('QR Scanner Behavior', () => {
  it('should NOT navigate to URL when scanning', () => {
    // This is a documentation test - the QRScanner component
    // must extract tokens without opening the browser
    const url = `https://ops.originalpsilly.com/qr/${TEST_TOKENS.VALID_1}`;
    const result = extractQRToken(url);
    
    // Verify we get a token, not a navigation action
    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
    
    // The token should be used for local processing
    // NOT for Linking.openURL or similar
  });

  it('should handle rapid consecutive scans', () => {
    // Simulate rapid scanning
    const url = `https://ops.originalpsilly.com/qr/${TEST_TOKENS.VALID_1}`;
    
    const result1 = extractQRToken(url);
    const result2 = extractQRToken(url);
    const result3 = extractQRToken(url);
    
    // All should succeed (component handles debouncing)
    expect(result1.success).toBe(true);
    expect(result2.success).toBe(true);
    expect(result3.success).toBe(true);
    expect(result1.token).toBe(result2.token);
  });
});
