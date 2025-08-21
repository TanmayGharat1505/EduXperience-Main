import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { saveCredentials, loadSavedCredentials, clearSavedCredentials, getSavedEmails, getCredentialStats } from "@/lib/credentials";
import { getPendingTutorProfile, getPendingStudentProfile, createTutorProfileAfterVerification, createStudentProfileAfterVerification, clearPendingTutorProfile, clearPendingStudentProfile } from "@/lib/profile-creation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Eye, EyeOff, Mail, Lock, ArrowLeft, Loader2 } from "lucide-react";
import { Header } from "@/components/layout/Header";
import { Badge } from "@/components/ui/badge";

export default function Login() {
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
  });
  const [savedEmails, setSavedEmails] = useState<string[]>([]);
  const [selectedSavedEmail, setSelectedSavedEmail] = useState<string>("");
  const { toast } = useToast();
  const navigate = useNavigate();

  // Test localStorage functionality immediately
  useEffect(() => {
    console.log('=== TESTING LOCALSTORAGE ===');
    try {
      const testKey = '__test_localStorage__';
      localStorage.setItem(testKey, 'test_value');
      const testValue = localStorage.getItem(testKey);
      localStorage.removeItem(testKey);
      console.log('localStorage test:', testValue === 'test_value' ? 'PASSED' : 'FAILED');
      console.log('localStorage available:', typeof localStorage !== 'undefined');
    } catch (error) {
      console.error('localStorage test failed:', error);
    }
  }, []);

  // Check for saved credentials and pending profile creation on component mount
  useEffect(() => {
    console.log('=== COMPONENT MOUNT - CHECKING FOR SAVED CREDENTIALS ===');
    
    // Load saved emails for the dropdown
    const emails = getSavedEmails();
    setSavedEmails(emails);
    console.log('Saved emails found:', emails);
    
    // Load most recent credentials if any exist
    const savedCredentials = loadSavedCredentials();
    if (savedCredentials) {
      console.log('=== FOUND SAVED CREDENTIALS ===');
      console.log('Auto-filling form with most recent credentials...');
      
      // Update React state
      setFormData({
        email: savedCredentials.email,
        password: savedCredentials.password,
      });
      setRememberMe(true);
      setSelectedSavedEmail(savedCredentials.email);
      
      console.log('✅ Form auto-filled successfully');
      console.log('Form data after auto-fill:', { email: savedCredentials.email, password: savedCredentials.password });
      console.log('Remember me after auto-fill:', true);
      console.log('Selected saved email:', savedCredentials.email);
          } else {
      console.log('❌ No saved credentials found');
      console.log('This means either:');
      console.log('1. No credentials were ever saved');
      console.log('2. Credentials were cleared (e.g., during logout)');
      console.log('3. There was an error loading them');
    }
  }, []); // Empty dependency array - runs only on mount

  // Debug: watch for formData changes
  useEffect(() => {
    console.log('=== FORM DATA CHANGED ===');
    console.log('New formData:', formData);
    console.log('New rememberMe:', rememberMe);
  }, [formData, rememberMe]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    console.log(`=== INPUT CHANGE: ${name} ===`);
    console.log('Previous value:', formData[name as keyof typeof formData]);
    console.log('New value:', value);
    console.log('Value type:', typeof value);
    console.log('Value length:', value.length);
    
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    
    console.log('Form data after update:', { ...formData, [name]: value });
  };

  // Handle account selection from dropdown
  const handleAccountSelection = (email: string) => {
    console.log('=== ACCOUNT SELECTION ===');
    console.log('Selected email:', email);
    
    if (email === "new") {
      // Clear form for new account
      setFormData({ email: "", password: "" });
      setSelectedSavedEmail("");
      console.log('✅ Form cleared for new account');
    } else {
      // Load selected account credentials
      const selectedCredentials = loadSavedCredentials(email);
      if (selectedCredentials) {
    setFormData({
          email: selectedCredentials.email,
          password: selectedCredentials.password,
        });
        setSelectedSavedEmail(email);
        setRememberMe(true);
        console.log('✅ Loaded credentials for:', email);
      } else {
        console.log('❌ No credentials found for:', email);
      }
    }
  };

  // Clear specific account credentials
  const handleClearAccount = (email: string) => {
    console.log('=== CLEARING ACCOUNT ===');
    console.log('Clearing credentials for:', email);
    
    clearSavedCredentials(email);
    
    // Update saved emails list
    const updatedEmails = getSavedEmails();
    setSavedEmails(updatedEmails);
    
    // If we cleared the currently selected account, clear the form
    if (selectedSavedEmail === email) {
      setFormData({ email: "", password: "" });
      setSelectedSavedEmail("");
      setRememberMe(false);
    }
    
    toast({
      title: "Account Cleared",
      description: `Credentials for ${email} have been removed.`,
    });
    
    console.log('✅ Account cleared successfully');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    console.log('=== FORM SUBMISSION START ===');
    console.log('Remember me checkbox checked:', rememberMe);
    console.log('Form data:', formData);
    console.log('Form data email:', formData.email);
    console.log('Form data password exists:', !!formData.password);
    console.log('Form data password length:', formData.password?.length || 0);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: formData.email,
        password: formData.password,
      });

      if (error) {
        throw new Error(error.message);
      }

      if (data.user) {
        console.log('=== LOGIN SUCCESSFUL ===');
        console.log('User logged in successfully');
        console.log('User email:', data.user.email);
        
        // Handle remember me functionality
        if (rememberMe) {
          console.log('✅ Remember me is checked - saving credentials...');
          console.log('About to call saveCredentials with:', formData.email, formData.password ? 'PASSWORD_EXISTS' : 'NO_PASSWORD');
          console.log('Password value type:', typeof formData.password);
          console.log('Password value:', formData.password);
          
          try {
            saveCredentials(formData.email, formData.password);
            console.log('✅ saveCredentials function completed successfully');
            
            // Immediately verify what was saved
            const verifyRememberMe = localStorage.getItem('eduxperience_remember_me');
            const verifyEmail = localStorage.getItem('eduxperience_saved_email');
            const verifyPassword = localStorage.getItem('eduxperience_saved_password');
            
            console.log('=== IMMEDIATE VERIFICATION ===');
            console.log('- REMEMBER_ME_KEY:', verifyRememberMe);
            console.log('- SAVED_EMAIL_KEY:', verifyEmail);
            console.log('- SAVED_PASSWORD_KEY:', verifyPassword ? 'EXISTS' : 'NOT FOUND');
            
            toast({
              title: "Credentials Saved",
              description: "Your login information has been saved for future use.",
            });
          } catch (error) {
            console.error('❌ Error saving credentials:', error);
            toast({
              title: "Warning",
              description: "Could not save credentials. Please check your browser settings.",
              variant: "destructive",
            });
          }
        } else {
          console.log('❌ Remember me is not checked - clearing saved credentials...');
          clearSavedCredentials();
        }

        toast({
          title: "Login Successful!",
          description: "Welcome back to EduXperience.",
        });

        // Add a delay to ensure credentials are saved before any redirect
        console.log('=== WAITING BEFORE REDIRECT ===');
        await new Promise(resolve => setTimeout(resolve, 1000));
        console.log('=== REDIRECT DELAY COMPLETE ===');
        
        // Check for pending profile creation
        const pendingTutor = getPendingTutorProfile();
        if (pendingTutor && data.user.email_confirmed_at) {
          console.log('=== CREATING TUTOR PROFILE ===');
          const result = await createTutorProfileAfterVerification(data.user.id, pendingTutor.formData);
          if (result.success) {
            clearPendingTutorProfile();
            toast({
              title: "Profile Created Successfully!",
              description: result.message,
            });
          }
          console.log('=== TUTOR PROFILE CREATION COMPLETE ===');
        }

        const pendingStudent = getPendingStudentProfile();
        if (pendingStudent && data.user.email_confirmed_at) {
          console.log('=== CREATING STUDENT PROFILE ===');
          const result = await createStudentProfileAfterVerification(data.user.id, pendingStudent.formData);
          if (result.success) {
            clearPendingStudentProfile();
            toast({
              title: "Profile Created Successfully!",
              description: result.message,
            });
          }
          console.log('=== STUDENT PROFILE CREATION COMPLETE ===');
        }
        
        // Check credentials before profile fetch
        console.log('=== CHECKING CREDENTIALS BEFORE PROFILE FETCH ===');
        const beforeProfileCheck = localStorage.getItem('eduxperience_remember_me');
        console.log('Credentials before profile fetch:', beforeProfileCheck ? 'EXIST' : 'NOT FOUND');
        
        // Get user's role and redirect accordingly
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', data.user.id)
          .single();

        if (profileError) {
          console.error('Error fetching user profile:', profileError);
          // If profile doesn't exist, redirect to home page
          console.log('Redirecting to home page due to profile error...');
          console.log('=== FINAL CREDENTIAL CHECK BEFORE REDIRECT ===');
          const finalCheck = localStorage.getItem('eduxperience_remember_me');
          console.log('Final credentials check:', finalCheck ? 'EXIST' : 'NOT FOUND');
          window.location.href = '/';
        } else if (profileData) {
          // Redirect based on user role
          console.log('Redirecting based on user role:', profileData.role);
          console.log('=== FINAL CREDENTIAL CHECK BEFORE REDIRECT ===');
          const finalCheck = localStorage.getItem('eduxperience_remember_me');
          console.log('Final credentials check:', finalCheck ? 'EXIST' : 'NOT FOUND');
          
          switch (profileData.role) {
            case 'student':
              window.location.href = '/student-dashboard';
              break;
            case 'tutor':
              window.location.href = '/tutor-dashboard';
              break;
            case 'institution':
              // TODO: Add institution dashboard route when available
              window.location.href = '/';
              break;
            case 'admin':
              // TODO: Add admin dashboard route when available
              window.location.href = '/';
              break;
            default:
              window.location.href = '/';
          }
        } else {
          // No profile found, redirect to home page
          console.log('No profile found, redirecting to home page...');
          console.log('=== FINAL CREDENTIAL CHECK BEFORE REDIRECT ===');
          const finalCheck = localStorage.getItem('eduxperience_remember_me');
          console.log('Final credentials check:', finalCheck ? 'EXIST' : 'NOT FOUND');
          window.location.href = '/';
        }
      }
    } catch (error) {
      console.error('Login error:', error);
      toast({
        title: "Login Failed",
        description: error instanceof Error ? error.message : "An unexpected error occurred.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-subtle">
      <Header />
      
      <div className="container mx-auto px-4 py-20">
        <div className="max-w-md mx-auto">
          <Link 
            to="/" 
            className="inline-flex items-center text-muted-foreground hover:text-primary transition-colors mb-8"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Home
          </Link>

          <Card className="shadow-medium border-none">
            <CardHeader className="space-y-4 text-center">
              <CardTitle className="text-2xl font-bold">Welcome Back</CardTitle>
              <CardDescription className="text-base">
                Sign in to your EduXperience account to continue your learning journey
              </CardDescription>
            </CardHeader>

            <form onSubmit={handleSubmit}>
              <CardContent className="space-y-6">
                <div className="space-y-4">
                  {/* Account Selection Dropdown */}
                  {savedEmails.length > 0 && (
                    <div className="space-y-2">
                      <Label htmlFor="account-select" className="text-sm font-medium text-gray-700">
                        Choose Saved Account
                      </Label>
                      <Select value={selectedSavedEmail} onValueChange={handleAccountSelection}>
                        <SelectTrigger>
                          <SelectValue placeholder="Select an account or add new" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="new">➕ Add New Account</SelectItem>
                          {savedEmails.map((email) => (
                            <SelectItem key={email} value={email}>
                              {email}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  )}

                  {/* Email Field */}
                <div className="space-y-2">
                    <Label htmlFor="email" className="text-sm font-medium text-gray-700">
                      Email
                  </Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      placeholder="your@email.com"
                      value={formData.email}
                      onChange={handleInputChange}
                      className="pl-10 h-12"
                      required
                    />
                  </div>
                  </div>
                  
                  {/* Show saved emails if available */}
                  {/* This section was removed as per the new_code */}
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password" className="text-sm font-medium">
                    Password
                  </Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="password"
                      name="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter your password"
                      value={formData.password}
                      onChange={handleInputChange}
                      className="pl-10 pr-10 h-12"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-3 text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id="remember"
                      checked={rememberMe}
                      onChange={(e) => {
                        const checked = e.target.checked;
                        console.log('=== CHECKBOX CHANGE ===');
                        console.log('Remember me checkbox changed to:', checked);
                        console.log('Previous state:', rememberMe);
                        console.log('Event target checked:', e.target.checked);
                        console.log('Event target type:', e.target.type);
                        
                        setRememberMe(checked);
                        
                        console.log('New state set to:', checked);
                        console.log('State after setState (will be updated in next render):', checked);
                        
                        // If unchecking, clear saved credentials
                        if (!checked) {
                          console.log('Clearing saved credentials due to checkbox uncheck');
                          clearSavedCredentials();
                        }
                      }}
                      className="rounded border-border text-primary focus:ring-primary"
                    />
                    <label
                      htmlFor="remember"
                      className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                    >
                      Remember me
                  </label>
                  </div>
                  
                  {/* Note about credential persistence */}
                  {rememberMe && (
                    <div className="text-xs text-muted-foreground bg-muted p-2 rounded">
                      💡 Your login information will be saved and auto-filled on future visits, even after logging out.
                    </div>
                  )}
                  <Link 
                    to="/forgot-password" 
                    className="text-sm text-primary hover:text-primary-soft transition-colors"
                  >
                    Forgot password?
                  </Link>
                </div>
                
                {rememberMe && (
                  <div className="text-xs text-muted-foreground bg-muted/50 p-3 rounded-md">
                    <p className="flex items-start">
                      <span className="mr-2">🔒</span>
                      <span>
                        Your credentials will be saved locally on this device. 
                        Only use this feature on your personal, secure device.
                      </span>
                    </p>
                    <button
                      type="button"
                      onClick={() => {
                        clearSavedCredentials();
                        setRememberMe(false);
                        setFormData({ email: "", password: "" });
                        toast({
                          title: "Credentials Cleared",
                          description: "Your saved login information has been removed.",
                        });
                      }}
                      className="mt-2 text-primary hover:text-primary-soft text-xs underline"
                    >
                      Clear saved credentials
                    </button>
                  </div>
                )}

                {/* Saved Accounts Management */}
                {savedEmails.length > 0 && (
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-medium text-gray-700">Saved Accounts</h4>
                      <div className="text-xs text-gray-500">
                        {savedEmails.length} account{savedEmails.length !== 1 ? 's' : ''} saved
                      </div>
                    </div>
                    
                    <div className="space-y-2">
                      {savedEmails.map((email) => (
                        <div key={email} className="flex items-center justify-between p-2 bg-gray-50 rounded-lg">
                          <div className="flex items-center space-x-2">
                            <Mail className="h-4 w-4 text-gray-500" />
                            <span className="text-sm text-gray-700">{email}</span>
                            {selectedSavedEmail === email && (
                              <Badge variant="secondary" className="text-xs">Current</Badge>
                            )}
                          </div>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => handleClearAccount(email)}
                            className="text-red-600 hover:text-red-700 hover:bg-red-50"
                          >
                            Remove
                          </Button>
                        </div>
                      ))}
                    </div>
                    
                    <div className="text-xs text-gray-500">
                      💡 Your login information is encrypted and stored locally for convenience.
                    </div>
                  </div>
                )}
              </CardContent>

              <CardFooter className="flex flex-col space-y-4">
                <Button 
                  type="submit" 
                  disabled={isLoading}
                  className="w-full bg-gradient-primary shadow-soft hover:shadow-medium h-12 text-base"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                      Signing In...
                    </>
                  ) : (
                    "Sign In"
                  )}
                </Button>

                <div className="relative">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t border-border" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-background px-2 text-muted-foreground">Or continue with</span>
                  </div>
                </div>

                <Button 
                  type="button" 
                  variant="outline" 
                  className="w-full h-12 text-base border-border hover:bg-muted"
                >
                  <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
                    <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                    <path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                    <path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                    <path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                  </svg>
                  Continue with Google
                </Button>

                <p className="text-center text-sm text-muted-foreground">
                  Don't have an account?{" "}
                  <Link to="/signup" className="text-primary hover:text-primary-soft font-medium transition-colors">
                    Sign up here
                  </Link>
                </p>
              </CardFooter>
            </form>
          </Card>

          <div className="mt-8 text-center">
            <p className="text-xs text-muted-foreground">
              By signing in, you agree to our{" "}
              <Link to="/terms" className="text-primary hover:text-primary-soft">Terms of Service</Link>
              {" "}and{" "}
              <Link to="/privacy" className="text-primary hover:text-primary-soft">Privacy Policy</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}