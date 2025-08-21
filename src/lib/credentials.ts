// Constants for localStorage keys
const REMEMBER_ME_KEY = 'eduxperience_remember_me';
const SAVED_CREDENTIALS_KEY = 'eduxperience_saved_credentials';
const CREDENTIALS_VERSION = 'eduxperience_credentials_version';

// Simple encryption key (in production, this would be more sophisticated)
const ENCRYPTION_KEY = 'eduxperience_secure_key_2024';

/**
 * Check if localStorage is available and working
 */
const isLocalStorageAvailable = (): boolean => {
  try {
    const test = '__localStorage_test__';
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
};

/**
 * Simple encryption function (basic obfuscation for local storage)
 */
const encrypt = (text: string): string => {
  try {
    // Simple XOR encryption with the key
    let result = '';
    for (let i = 0; i < text.length; i++) {
      const charCode = text.charCodeAt(i) ^ ENCRYPTION_KEY.charCodeAt(i % ENCRYPTION_KEY.length);
      result += String.fromCharCode(charCode);
    }
    return btoa(result); // Base64 encode
  } catch (error) {
    console.error('Encryption failed:', error);
    return text; // Fallback to plain text
  }
};

/**
 * Simple decryption function
 */
const decrypt = (encryptedText: string): string => {
  try {
    // Base64 decode then XOR decrypt
    const decoded = atob(encryptedText);
    let result = '';
    for (let i = 0; i < decoded.length; i++) {
      const charCode = decoded.charCodeAt(i) ^ ENCRYPTION_KEY.charCodeAt(i % ENCRYPTION_KEY.length);
      result += String.fromCharCode(charCode);
    }
    return result;
  } catch (error) {
    console.error('Decryption failed:', error);
    return encryptedText; // Fallback to encrypted text
  }
};

/**
 * Interface for stored credentials
 */
interface StoredCredential {
  email: string;
  password: string;
  lastUsed: string;
  createdAt: string;
}

/**
 * Interface for the credentials storage structure
 */
interface CredentialsStorage {
  version: string;
  credentials: StoredCredential[];
  lastUpdated: string;
}

/**
 * Save user credentials to localStorage (multi-account support)
 * @param email - User's email address
 * @param password - User's password
 */
export const saveCredentials = (email: string, password: string): void => {
  if (!isLocalStorageAvailable()) {
    throw new Error('localStorage is not available in this browser/environment');
  }
  
  try {
    console.log('=== SAVING CREDENTIALS ===');
    console.log('Email to save:', email);
    console.log('Password to save:', password ? 'EXISTS' : 'NOT FOUND');
    
    // Get existing credentials
    const existingStorage = localStorage.getItem(SAVED_CREDENTIALS_KEY);
    let credentialsStorage: CredentialsStorage;
    
    if (existingStorage) {
      try {
        const decrypted = decrypt(existingStorage);
        credentialsStorage = JSON.parse(decrypted);
        
        // Check if this email already exists
        const existingIndex = credentialsStorage.credentials.findIndex(
          cred => cred.email.toLowerCase() === email.toLowerCase()
        );
        
        if (existingIndex !== -1) {
          // Update existing credential
          credentialsStorage.credentials[existingIndex] = {
            email,
            password,
            lastUsed: new Date().toISOString(),
            createdAt: credentialsStorage.credentials[existingIndex].createdAt
          };
          console.log('✅ Updated existing credentials for:', email);
        } else {
          // Add new credential
          credentialsStorage.credentials.push({
            email,
            password,
            lastUsed: new Date().toISOString(),
            createdAt: new Date().toISOString()
          });
          console.log('✅ Added new credentials for:', email);
        }
      } catch (parseError) {
        console.warn('Failed to parse existing credentials, creating new storage');
        credentialsStorage = {
          version: CREDENTIALS_VERSION,
          credentials: [{
            email,
            password,
            lastUsed: new Date().toISOString(),
            createdAt: new Date().toISOString()
          }],
          lastUpdated: new Date().toISOString()
        };
      }
    } else {
      // Create new storage
      credentialsStorage = {
        version: CREDENTIALS_VERSION,
        credentials: [{
          email,
          password,
          lastUsed: new Date().toISOString(),
          createdAt: new Date().toISOString()
        }],
        lastUpdated: new Date().toISOString()
      };
    }
    
    // Update timestamp
    credentialsStorage.lastUpdated = new Date().toISOString();
    
    // Encrypt and save
    const encrypted = encrypt(JSON.stringify(credentialsStorage));
    localStorage.setItem(SAVED_CREDENTIALS_KEY, encrypted);
    localStorage.setItem(REMEMBER_ME_KEY, 'true');
    
    // Verify what was saved
    const verifyRememberMe = localStorage.getItem(REMEMBER_ME_KEY);
    const verifyCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
    
    console.log('=== VERIFICATION AFTER SAVE ===');
    console.log('- REMEMBER_ME_KEY saved as:', verifyRememberMe);
    console.log('- SAVED_CREDENTIALS_KEY saved as:', verifyCredentials ? 'EXISTS' : 'NOT FOUND');
    console.log('- Total saved accounts:', credentialsStorage.credentials.length);
    
    console.log('✅ Credentials saved successfully');
  } catch (error) {
    console.error('❌ Error saving credentials:', error);
    throw new Error('Could not save credentials. Please check your browser settings.');
  }
};

/**
 * Load saved credentials from localStorage (multi-account support)
 * @param email - Optional email to load specific credentials
 * @returns Object containing saved credentials or null if none exist
 */
export const loadSavedCredentials = (email?: string): { email: string; password: string } | null => {
  try {
    console.log('=== LOADING SAVED CREDENTIALS ===');
    
    const savedRememberMe = localStorage.getItem(REMEMBER_ME_KEY);
    console.log('- REMEMBER_ME_KEY value:', savedRememberMe);
    
    if (savedRememberMe === 'true') {
      console.log('✅ Remember me is enabled, checking for saved credentials...');
      
      const encryptedCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
      if (!encryptedCredentials) {
        console.log('❌ No encrypted credentials found');
        return null;
      }
      
      try {
        const decrypted = decrypt(encryptedCredentials);
        const credentialsStorage: CredentialsStorage = JSON.parse(decrypted);
        
        console.log('- Total saved accounts:', credentialsStorage.credentials.length);
        
        if (email) {
          // Load specific email credentials
          const specificCredential = credentialsStorage.credentials.find(
            cred => cred.email.toLowerCase() === email.toLowerCase()
          );
          
          if (specificCredential) {
            console.log('✅ Found credentials for specific email:', email);
            return { email: specificCredential.email, password: specificCredential.password };
          } else {
            console.log('❌ No credentials found for specific email:', email);
            return null;
          }
        } else {
          // Load most recently used credentials
          if (credentialsStorage.credentials.length > 0) {
            const mostRecent = credentialsStorage.credentials.reduce((latest, current) => {
              return new Date(current.lastUsed) > new Date(latest.lastUsed) ? current : latest;
            });
            
            console.log('✅ Found most recent credentials for:', mostRecent.email);
            return { email: mostRecent.email, password: mostRecent.password };
          }
        }
      } catch (parseError) {
        console.error('❌ Error parsing encrypted credentials:', parseError);
        return null;
      }
    } else {
      console.log('❌ Remember me is not enabled');
    }
    
    console.log('❌ No valid credentials found, returning null');
    return null;
  } catch (error) {
    console.error('❌ Error loading saved credentials:', error);
    return null;
  }
};

/**
 * Get all saved email addresses
 * @returns Array of saved email addresses
 */
export const getSavedEmails = (): string[] => {
  try {
    const encryptedCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
    if (!encryptedCredentials) return [];
    
    const decrypted = decrypt(encryptedCredentials);
    const credentialsStorage: CredentialsStorage = JSON.parse(decrypted);
    
    return credentialsStorage.credentials.map(cred => cred.email);
  } catch (error) {
    console.error('Error getting saved emails:', error);
    return [];
  }
};

/**
 * Get all saved credentials (for management purposes)
 * @returns Array of all saved credentials
 */
export const getAllSavedCredentials = (): StoredCredential[] => {
  try {
    const encryptedCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
    if (!encryptedCredentials) return [];
    
    const decrypted = decrypt(encryptedCredentials);
    const credentialsStorage: CredentialsStorage = JSON.parse(decrypted);
    
    return credentialsStorage.credentials;
  } catch (error) {
    console.error('Error getting all saved credentials:', error);
    return [];
  }
};

/**
 * Clear specific saved credentials
 * @param email - Email address to clear (if not provided, clears all)
 */
export const clearSavedCredentials = (email?: string): void => {
  try {
    console.log('=== CLEARING SAVED CREDENTIALS ===');
    
    if (email) {
      // Clear specific email credentials
      const encryptedCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
      if (encryptedCredentials) {
        try {
          const decrypted = decrypt(encryptedCredentials);
          const credentialsStorage: CredentialsStorage = JSON.parse(decrypted);
          
          credentialsStorage.credentials = credentialsStorage.credentials.filter(
            cred => cred.email.toLowerCase() !== email.toLowerCase()
          );
          
          if (credentialsStorage.credentials.length === 0) {
            // No more credentials, clear everything
            localStorage.removeItem(REMEMBER_ME_KEY);
            localStorage.removeItem(SAVED_CREDENTIALS_KEY);
            console.log('✅ Cleared all credentials (last one removed)');
          } else {
            // Update storage with remaining credentials
            credentialsStorage.lastUpdated = new Date().toISOString();
            const encrypted = encrypt(JSON.stringify(credentialsStorage));
            localStorage.setItem(SAVED_CREDENTIALS_KEY, encrypted);
            console.log('✅ Cleared credentials for:', email);
          }
        } catch (parseError) {
          console.error('Error parsing credentials for removal:', parseError);
          // Fallback: clear everything
          localStorage.removeItem(REMEMBER_ME_KEY);
          localStorage.removeItem(SAVED_CREDENTIALS_KEY);
        }
      }
    } else {
      // Clear all credentials
      localStorage.removeItem(REMEMBER_ME_KEY);
      localStorage.removeItem(SAVED_CREDENTIALS_KEY);
      console.log('✅ All credentials cleared successfully');
    }
  } catch (error) {
    console.error('❌ Error clearing credentials:', error);
  }
};

/**
 * Check if remember me is enabled
 * @returns boolean indicating if remember me is enabled
 */
export const isRememberMeEnabled = (): boolean => {
  try {
    const result = localStorage.getItem(REMEMBER_ME_KEY) === 'true';
    console.log('=== CHECKING REMEMBER ME STATUS ===');
    console.log('Remember me enabled:', result);
    return result;
  } catch (error) {
    console.error('❌ Error checking remember me status:', error);
    return false;
  }
};

/**
 * Get credential statistics
 * @returns Object with credential statistics
 */
export const getCredentialStats = () => {
  try {
    const encryptedCredentials = localStorage.getItem(SAVED_CREDENTIALS_KEY);
    if (!encryptedCredentials) {
      return { totalAccounts: 0, lastUpdated: null };
    }
    
    const decrypted = decrypt(encryptedCredentials);
    const credentialsStorage: CredentialsStorage = JSON.parse(decrypted);
    
    return {
      totalAccounts: credentialsStorage.credentials.length,
      lastUpdated: credentialsStorage.lastUpdated,
      version: credentialsStorage.version
    };
  } catch (error) {
    console.error('Error getting credential stats:', error);
    return { totalAccounts: 0, lastUpdated: null };
  }
};
