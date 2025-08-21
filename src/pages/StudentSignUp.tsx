import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { PasswordStrength } from "@/components/ui/password-strength";
import { Header } from "@/components/layout/Header";
import { 
  User, 
  Mail, 
  Lock, 
  Upload, 
  Calendar,
  MapPin,
  AlertCircle,
  Loader2
} from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { emailRegex } from "@/lib/validation";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

interface StudentFormData {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
  profilePhoto: File | null;
  dateOfBirth: string;
  educationLevel: string;
  city: string;
  area: string;
  primaryLanguage: string;
  termsAccepted: boolean;
}

interface ValidationErrors {
  [key: string]: string;
}

const initialFormData: StudentFormData = {
  fullName: "",
  email: "",
  password: "",
  confirmPassword: "",
  profilePhoto: null,
  dateOfBirth: "",
  educationLevel: "",
  city: "",
  area: "",
  primaryLanguage: "",
  termsAccepted: false,
};

export default function StudentSignUp() {
  const [formData, setFormData] = useState<StudentFormData>(initialFormData);
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [touchedFields, setTouchedFields] = useState<Set<string>>(new Set());
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const educationLevels = [
    "Class 1-5", "Class 6-8", "Class 9-10", "Class 11-12",
    "Undergraduate", "Graduate", "Professional", "Other"
  ];

  const validateField = (field: keyof StudentFormData, value: any) => {
    const newErrors = { ...errors };
    
    switch (field) {
      case 'fullName':
        if (!value || value.trim().length < 2) {
          newErrors.fullName = 'Full name must be at least 2 characters';
        } else if (value.length > 50) {
          newErrors.fullName = 'Full name must be less than 50 characters';
        } else if (!/^[a-zA-Z\s]+$/.test(value)) {
          newErrors.fullName = 'Full name can only contain letters and spaces';
        } else {
          delete newErrors.fullName;
        }
        break;
        
      case 'email':
        if (!value) {
          newErrors.email = 'Email is required';
        } else if (!emailRegex.test(value)) {
          newErrors.email = 'Please enter a valid email address';
        } else {
          delete newErrors.email;
        }
        break;
        
      case 'password':
        if (!value) {
          newErrors.password = 'Password is required';
        } else if (value.length < 8) {
          newErrors.password = 'Password must be at least 8 characters';
        } else if (!/[A-Z]/.test(value)) {
          newErrors.password = 'Password must contain at least one uppercase letter';
        } else if (!/[a-z]/.test(value)) {
          newErrors.password = 'Password must contain at least one lowercase letter';
        } else if (!/\d/.test(value)) {
          newErrors.password = 'Password must contain at least one number';
        } else if (!/[!@#$%^&*(),.?":{}|<>]/.test(value)) {
          newErrors.password = 'Password must contain at least one special character';
        } else {
          delete newErrors.password;
        }
        break;
        
      case 'confirmPassword':
        if (!value) {
          newErrors.confirmPassword = 'Please confirm your password';
        } else if (value !== formData.password) {
          newErrors.confirmPassword = "Passwords don't match";
        } else {
          delete newErrors.confirmPassword;
        }
        break;
        
      case 'termsAccepted':
        if (!value) {
          newErrors.termsAccepted = 'You must accept the terms and conditions';
        } else {
          delete newErrors.termsAccepted;
        }
        break;
    }
    
    setErrors(newErrors);
  };

  const handleInputChange = (field: keyof StudentFormData, value: any) => {
    setFormData({ ...formData, [field]: value });
    setTouchedFields(prev => new Set(prev).add(field));
    validateField(field, value);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate all fields
    Object.keys(formData).forEach(key => {
      validateField(key as keyof StudentFormData, formData[key as keyof StudentFormData]);
    });
    
    if (!formData.termsAccepted) {
      setErrors(prev => ({ ...prev, termsAccepted: 'You must accept the terms and conditions' }));
      return;
    }
    
    if (Object.keys(errors).length > 0) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields correctly.",
        variant: "destructive",
      });
      return;
    }

    setIsSubmitting(true);

    try {
      console.log('Starting student signup process...');
      
      // Step 1: Create user account with Supabase Auth
      console.log('Creating user account...');
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            full_name: formData.fullName,
            role: 'student',
          }
        }
      });

      console.log('Auth response:', { authData, authError });

      if (authError) {
        throw new Error(authError.message);
      }

      if (!authData.user) {
        throw new Error("Failed to create user account");
      }

      console.log('User created successfully:', authData.user.id);

      // Store form data for profile creation after email verification
      console.log('Storing form data for profile creation after email verification...');
      
      const profileData = {
        userId: authData.user.id,
        formData: formData,
        timestamp: Date.now(),
        email: formData.email
      };
      
      localStorage.setItem('pendingStudentProfile', JSON.stringify(profileData));
      
      console.log('Form data stored successfully');

      // Upload profile photo if provided
      if (formData.profilePhoto) {
        try {
          const fileExt = formData.profilePhoto.name.split('.').pop();
          const fileName = `${authData.user.id}-profile.${fileExt}`;
          
          const { error: uploadError } = await supabase.storage
            .from('profile-photos')
            .upload(fileName, formData.profilePhoto);

          if (!uploadError) {
            console.log('Profile photo uploaded successfully');
          }
        } catch (uploadError) {
          console.warn('Profile photo upload failed:', uploadError);
        }
      }

      toast({
        title: "Account Created Successfully!",
        description: "Please check your email to verify your account. Your profile will be created after verification.",
      });

      // Redirect to login page
      navigate('/login');

    } catch (error) {
      console.error('Signup error:', error);
      toast({
        title: "Signup Failed",
        description: error instanceof Error ? error.message : "An unexpected error occurred. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <Header />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <Card className="shadow-lg">
            <CardHeader className="text-center">
              <CardTitle className="text-3xl font-bold bg-gradient-primary bg-clip-text text-transparent">
                Join as a Student
              </CardTitle>
              <CardDescription className="text-lg">
                Start your learning journey with EduXperience
              </CardDescription>
            </CardHeader>
            
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="fullName">Full Name *</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="fullName"
                        placeholder="Enter your full name"
                        value={formData.fullName}
                        onChange={(e) => handleInputChange("fullName", e.target.value)}
                        className={`pl-10 h-12 ${errors.fullName && touchedFields.has('fullName') ? 'border-destructive' : ''}`}
                        required
                      />
                      {errors.fullName && touchedFields.has('fullName') && (
                        <div className="flex items-center mt-1 text-destructive text-sm">
                          <AlertCircle className="h-4 w-4 mr-1" />
                          {errors.fullName}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email">Email Address *</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="email"
                        type="email"
                        placeholder="your@email.com"
                        value={formData.email}
                        onChange={(e) => handleInputChange("email", e.target.value)}
                        className={`pl-10 h-12 ${errors.email && touchedFields.has('email') ? 'border-destructive' : ''}`}
                        required
                      />
                      {errors.email && touchedFields.has('email') && (
                        <div className="flex items-center mt-1 text-destructive text-sm">
                          <AlertCircle className="h-4 w-4 mr-1" />
                          {errors.email}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <Label htmlFor="password">Password *</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="password"
                        type="password"
                        placeholder="Create a strong password"
                        value={formData.password}
                        onChange={(e) => handleInputChange("password", e.target.value)}
                        className={`pl-10 h-12 ${errors.password && touchedFields.has('password') ? 'border-destructive' : ''}`}
                        required
                      />
                      {errors.password && touchedFields.has('password') && (
                        <div className="flex items-center mt-1 text-destructive text-sm">
                          <AlertCircle className="h-4 w-4 mr-1" />
                          {errors.password}
                        </div>
                      )}
                    </div>
                    {formData.password && (
                      <div className="mt-3">
                        <PasswordStrength password={formData.password} />
                      </div>
                    )}
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <Label htmlFor="confirmPassword">Confirm Password *</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="confirmPassword"
                        type="password"
                        placeholder="Confirm your password"
                        value={formData.confirmPassword}
                        onChange={(e) => handleInputChange("confirmPassword", e.target.value)}
                        className={`pl-10 h-12 ${errors.confirmPassword && touchedFields.has('confirmPassword') ? 'border-destructive' : ''}`}
                        required
                      />
                      {errors.confirmPassword && touchedFields.has('confirmPassword') && (
                        <div className="flex items-center mt-1 text-destructive text-sm">
                          <AlertCircle className="h-4 w-4 mr-1" />
                          {errors.confirmPassword}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="dateOfBirth">Date of Birth *</Label>
                    <div className="relative">
                      <Calendar className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="dateOfBirth"
                        type="date"
                        value={formData.dateOfBirth}
                        onChange={(e) => handleInputChange("dateOfBirth", e.target.value)}
                        className="pl-10 h-12"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Education Level *</Label>
                    <Select value={formData.educationLevel} onValueChange={(value) => handleInputChange("educationLevel", value)}>
                      <SelectTrigger className="h-12">
                        <SelectValue placeholder="Select your current level" />
                      </SelectTrigger>
                      <SelectContent>
                        {educationLevels.map((level) => (
                          <SelectItem key={level} value={level}>{level}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="city">City *</Label>
                    <div className="relative">
                      <MapPin className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="city"
                        placeholder="Enter your city"
                        value={formData.city}
                        onChange={(e) => handleInputChange("city", e.target.value)}
                        className="pl-10 h-12"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="area">Area/Locality *</Label>
                    <Input
                      id="area"
                      placeholder="Enter your area or locality"
                      value={formData.area}
                      onChange={(e) => handleInputChange("area", e.target.value)}
                      className="h-12"
                      required
                    />
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <Label>Primary Language *</Label>
                    <Select value={formData.primaryLanguage} onValueChange={(value) => handleInputChange("primaryLanguage", value)}>
                      <SelectTrigger className="h-12">
                        <SelectValue placeholder="Select your primary language" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="english">English</SelectItem>
                        <SelectItem value="hindi">Hindi</SelectItem>
                        <SelectItem value="bengali">Bengali</SelectItem>
                        <SelectItem value="tamil">Tamil</SelectItem>
                        <SelectItem value="telugu">Telugu</SelectItem>
                        <SelectItem value="marathi">Marathi</SelectItem>
                        <SelectItem value="gujarati">Gujarati</SelectItem>
                        <SelectItem value="kannada">Kannada</SelectItem>
                        <SelectItem value="malayalam">Malayalam</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <Label htmlFor="profilePhoto">Profile Photo (Optional)</Label>
                    <div className="flex items-center space-x-4">
                      <div className="flex-1">
                        <Input
                          id="profilePhoto"
                          type="file"
                          accept="image/*"
                          onChange={(e) => handleInputChange("profilePhoto", e.target.files?.[0] || null)}
                          className="h-12"
                        />
                      </div>
                      <Upload className="h-5 w-5 text-muted-foreground" />
                    </div>
                    <p className="text-xs text-muted-foreground">Recommended: Square image, max 5MB</p>
                  </div>
                </div>

                <div className="mt-6">
                  <div className="flex items-start space-x-2">
                    <Checkbox 
                      id="termsAccepted"
                      checked={formData.termsAccepted}
                      onCheckedChange={(checked) => handleInputChange("termsAccepted", checked)}
                      className={errors.termsAccepted ? 'border-destructive' : ''}
                    />
                    <Label htmlFor="termsAccepted" className="text-sm leading-5">
                      I agree to the{" "}
                      <Link to="/terms" className="text-primary hover:underline">
                        Terms and Conditions
                      </Link>{" "}
                      and{" "}
                      <Link to="/privacy" className="text-primary hover:underline">
                        Privacy Policy
                      </Link>
                      *
                    </Label>
                  </div>
                  {errors.termsAccepted && (
                    <div className="flex items-center mt-1 text-destructive text-sm">
                      <AlertCircle className="h-4 w-4 mr-1" />
                      {errors.termsAccepted}
                    </div>
                  )}
                </div>

                <Button 
                  type="submit" 
                  className="w-full h-12 text-lg font-semibold"
                  disabled={Object.keys(errors).length > 0 || !formData.termsAccepted || isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                      Creating Account...
                    </>
                  ) : (
                    "Create Student Account"
                  )}
                </Button>

                <div className="text-center">
                  <p className="text-muted-foreground">
                    Already have an account?{" "}
                    <Link to="/login" className="text-primary hover:underline font-medium">
                      Sign in here
                    </Link>
                  </p>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}