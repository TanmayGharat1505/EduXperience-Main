// Admin authentication utilities
import { supabase } from "@/integrations/supabase/client";

// Admin credentials (in production, these would be stored securely in environment variables)
const ADMIN_CREDENTIALS = {
  username: 'admin',
  password: 'EduXperience2024!', // Strong password for admin access
  email: 'admin@eduxperience.com'
};

// Admin session storage key
const ADMIN_SESSION_KEY = 'eduxperience_admin_session';

/**
 * Admin login function
 * @param username - Admin username
 * @param password - Admin password
 * @returns Promise<boolean> - Success status
 */
export const adminLogin = async (username: string, password: string): Promise<boolean> => {
  try {
    console.log('=== ADMIN LOGIN ATTEMPT ===');
    console.log('Username:', username);
    
    // Check credentials
    if (username === ADMIN_CREDENTIALS.username && password === ADMIN_CREDENTIALS.password) {
      // Create admin session
      const adminSession = {
        username: ADMIN_CREDENTIALS.username,
        email: ADMIN_CREDENTIALS.email,
        role: 'admin',
        loginTime: new Date().toISOString(),
        isAuthenticated: true
      };
      
      // Store admin session
      localStorage.setItem(ADMIN_SESSION_KEY, JSON.stringify(adminSession));
      
      console.log('✅ Admin login successful');
      return true;
    } else {
      console.log('❌ Admin login failed: Invalid credentials');
      return false;
    }
  } catch (error) {
    console.error('❌ Admin login error:', error);
    return false;
  }
};

/**
 * Check if admin is authenticated
 * @returns boolean - Authentication status
 */
export const isAdminAuthenticated = (): boolean => {
  try {
    const adminSession = localStorage.getItem(ADMIN_SESSION_KEY);
    if (!adminSession) return false;
    
    const session = JSON.parse(adminSession);
    return session.isAuthenticated === true;
  } catch (error) {
    console.error('Error checking admin authentication:', error);
    return false;
  }
};

/**
 * Get admin session data
 * @returns Admin session object or null
 */
export const getAdminSession = () => {
  try {
    const adminSession = localStorage.getItem(ADMIN_SESSION_KEY);
    if (!adminSession) return null;
    
    return JSON.parse(adminSession);
  } catch (error) {
    console.error('Error getting admin session:', error);
    return null;
  }
};

/**
 * Admin logout function
 */
export const adminLogout = (): void => {
  try {
    localStorage.removeItem(ADMIN_SESSION_KEY);
    console.log('✅ Admin logged out successfully');
  } catch (error) {
    console.error('Error during admin logout:', error);
  }
};

/**
 * Validate admin session (check if session is still valid)
 * @returns boolean - Session validity
 */
export const validateAdminSession = (): boolean => {
  try {
    const session = getAdminSession();
    if (!session) return false;
    
    // Check if session is not expired (24 hours)
    const loginTime = new Date(session.loginTime);
    const now = new Date();
    const hoursDiff = (now.getTime() - loginTime.getTime()) / (1000 * 60 * 60);
    
    if (hoursDiff > 24) {
      // Session expired, clear it
      adminLogout();
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Error validating admin session:', error);
    return false;
  }
};
