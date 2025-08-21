import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Header } from "@/components/layout/Header";
import { Building2, Mail, Phone, MapPin, FileText, Users, Target, CheckCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface InstitutionFormData {
  organization_name: string;
  email: string;
  password: string;
  confirmPassword: string;
  phone: string;
  country: string;
  state: string;
  city: string;
  address: string;
  institution_type: string;
  established_year: string;
  description: string;
  contact_person_name: string;
  contact_person_title: string;
  agreeToTerms: boolean;
  agreeToPrivacy: boolean;
}

const INSTITUTION_TYPES = [
  "School",
  "College",
  "University",
  "Training Center",
  "Language Institute",
  "Online Academy",
  "Tutoring Center",
  "Other"
];

export default function InstitutionSignUp() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState<InstitutionFormData>({
    organization_name: "",
    email: "",
    password: "",
    confirmPassword: "",
    phone: "",
    country: "",
    state: "",
    city: "",
    address: "",
    institution_type: "",
    established_year: "",
    description: "",
    contact_person_name: "",
    contact_person_title: "",
    agreeToTerms: false,
    agreeToPrivacy: false
  });

  const handleInputChange = (field: keyof InstitutionFormData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const validateForm = (): boolean => {
    return !!(
      formData.organization_name &&
      formData.email &&
      formData.password &&
      formData.password === formData.confirmPassword &&
      formData.phone &&
      formData.country &&
      formData.state &&
      formData.city &&
      formData.address &&
      formData.institution_type &&
      formData.established_year &&
      formData.contact_person_name &&
      formData.contact_person_title &&
      formData.agreeToTerms &&
      formData.agreeToPrivacy
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields correctly.",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);

    try {
      // 1. Create auth user
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            organization_name: formData.organization_name,
            role: 'institution'
          }
        }
      });

      if (authError) throw authError;

             if (authData.user) {
         // 2. Create profile (or update if exists)
         const { error: profileError } = await supabase
           .from('profiles')
           .upsert({
             user_id: authData.user.id,
             full_name: formData.organization_name,
             email: formData.email,
             role: 'institution',
             phone: formData.phone,
             bio: formData.description
           }, {
             onConflict: 'user_id',
             ignoreDuplicates: false
           });

         if (profileError) throw profileError;

         // 3. Create institution profile (or update if exists)
         try {
           const { error: institutionError } = await supabase
             .from('institution_profiles')
             .upsert({
               user_id: authData.user.id,
               institution_name: formData.organization_name,
               institution_type: formData.institution_type,
               established_year: parseInt(formData.established_year),
               description: formData.description,
               contact_person_name: formData.contact_person_name,
               contact_person_title: formData.contact_person_title,
               country: formData.country,
               state: formData.state,
               city: formData.city,
               address: formData.address,
               verified: false // Start as unverified
             }, {
               onConflict: 'user_id',
               ignoreDuplicates: false
             });

           if (institutionError) {
             console.warn('Could not create institution profile:', institutionError);
           }
         } catch (error) {
           console.warn('Institution profiles table might not exist yet:', error);
         }

        toast({
          title: "Success!",
          description: "Institution account created successfully! Basic profile and institution profile created. Please check your email for verification.",
        });

        navigate('/login');
      }
    } catch (error: any) {
      console.error('Error creating institution account:', error);
      
      let errorMessage = "Failed to create institution account. Please try again.";
      
      if (error.message) {
        if (error.message.includes("For security purposes")) {
          errorMessage = "Please wait a moment before trying again (rate limit protection).";
        } else if (error.message.includes("already registered")) {
          errorMessage = "This email is already registered. Please use a different email or try logging in.";
        } else if (error.message.includes("Invalid email")) {
          errorMessage = "Please enter a valid email address.";
        } else if (error.message.includes("Password")) {
          errorMessage = "Password must be at least 6 characters long.";
        } else {
          errorMessage = error.message;
        }
      }
      
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <Header />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <Card className="w-full">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-4">
                <Building2 className="h-8 w-8 text-primary" />
              </div>
              <CardTitle className="text-3xl font-bold">Institution Registration</CardTitle>
              <CardDescription>
                Join EduXperience as an educational institution and start offering your services
              </CardDescription>
            </CardHeader>
            
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Basic Information */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold flex items-center">
                    <Building2 className="h-5 w-5 mr-2" />
                    Basic Information
                  </h3>
                  
                  <div>
                    <Label htmlFor="organization_name">Institution Name *</Label>
                    <Input
                      id="organization_name"
                      value={formData.organization_name}
                      onChange={(e) => handleInputChange('organization_name', e.target.value)}
                      placeholder="Enter your institution name"
                    />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="email">Email Address *</Label>
                      <Input
                        id="email"
                        type="email"
                        value={formData.email}
                        onChange={(e) => handleInputChange('email', e.target.value)}
                        placeholder="institution@example.com"
                      />
                    </div>

                    <div>
                      <Label htmlFor="phone">Phone Number *</Label>
                      <Input
                        id="phone"
                        value={formData.phone}
                        onChange={(e) => handleInputChange('phone', e.target.value)}
                        placeholder="+1 (555) 123-4567"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="password">Password *</Label>
                      <Input
                        id="password"
                        type="password"
                        value={formData.password}
                        onChange={(e) => handleInputChange('password', e.target.value)}
                        placeholder="Create a strong password"
                      />
                    </div>

                    <div>
                      <Label htmlFor="confirmPassword">Confirm Password *</Label>
                      <Input
                        id="confirmPassword"
                        type="password"
                        value={formData.confirmPassword}
                        onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
                        placeholder="Confirm your password"
                      />
                    </div>
                  </div>
                </div>

                {/* Address Information */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold flex items-center">
                    <MapPin className="h-5 w-5 mr-2" />
                    Address Information
                  </h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="country">Country *</Label>
                      <Input
                        id="country"
                        value={formData.country}
                        onChange={(e) => handleInputChange('country', e.target.value)}
                        placeholder="United States"
                      />
                    </div>

                    <div>
                      <Label htmlFor="state">State/Province *</Label>
                      <Input
                        id="state"
                        value={formData.state}
                        onChange={(e) => handleInputChange('state', e.target.value)}
                        placeholder="California"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="city">City *</Label>
                      <Input
                        id="city"
                        value={formData.city}
                        onChange={(e) => handleInputChange('city', e.target.value)}
                        placeholder="Los Angeles"
                      />
                    </div>

                    <div>
                      <Label htmlFor="address">Street Address *</Label>
                      <Input
                        id="address"
                        value={formData.address}
                        onChange={(e) => handleInputChange('address', e.target.value)}
                        placeholder="123 Main Street"
                      />
                    </div>
                  </div>
                </div>

                {/* Institution Details */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold flex items-center">
                    <Target className="h-5 w-5 mr-2" />
                    Institution Details
                  </h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="institution_type">Institution Type *</Label>
                      <Select value={formData.institution_type} onValueChange={(value) => handleInputChange('institution_type', value)}>
                        <SelectTrigger>
                          <SelectValue placeholder="Select institution type" />
                        </SelectTrigger>
                        <SelectContent>
                          {INSTITUTION_TYPES.map(type => (
                            <SelectItem key={type} value={type}>{type}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    <div>
                      <Label htmlFor="established_year">Established Year *</Label>
                      <Input
                        id="established_year"
                        type="number"
                        value={formData.established_year}
                        onChange={(e) => handleInputChange('established_year', e.target.value)}
                        placeholder="2020"
                        min="1900"
                        max={new Date().getFullYear()}
                      />
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="description">Institution Description</Label>
                    <Textarea
                      id="description"
                      value={formData.description}
                      onChange={(e) => handleInputChange('description', e.target.value)}
                      placeholder="Tell us about your institution, mission, and values..."
                      rows={4}
                    />
                  </div>
                </div>

                {/* Contact Person */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold flex items-center">
                    <Users className="h-5 w-5 mr-2" />
                    Contact Person
                  </h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="contact_person_name">Contact Person Name *</Label>
                      <Input
                        id="contact_person_name"
                        value={formData.contact_person_name}
                        onChange={(e) => handleInputChange('contact_person_name', e.target.value)}
                        placeholder="John Doe"
                      />
                    </div>

                    <div>
                      <Label htmlFor="contact_person_title">Title/Position *</Label>
                      <Input
                        id="contact_person_title"
                        value={formData.contact_person_title}
                        onChange={(e) => handleInputChange('contact_person_title', e.target.value)}
                        placeholder="Director, Principal, Manager"
                      />
                    </div>
                  </div>
                </div>

                {/* Terms and Conditions */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold flex items-center">
                    <CheckCircle className="h-5 w-5 mr-2" />
                    Terms and Conditions
                  </h3>
                  
                  <div className="space-y-3">
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="agreeToTerms"
                        checked={formData.agreeToTerms}
                        onCheckedChange={(checked) => handleInputChange('agreeToTerms', checked)}
                      />
                      <Label htmlFor="agreeToTerms" className="text-sm">
                        I agree to the <a href="#" className="text-primary hover:underline">Terms of Service</a> *
                      </Label>
                    </div>

                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="agreeToPrivacy"
                        checked={formData.agreeToPrivacy}
                        onCheckedChange={(checked) => handleInputChange('agreeToPrivacy', checked)}
                      />
                      <Label htmlFor="agreeToPrivacy" className="text-sm">
                        I agree to the <a href="#" className="text-primary hover:underline">Privacy Policy</a> *
                      </Label>
                    </div>
                  </div>
                </div>

                <Button 
                  type="submit" 
                  className="w-full h-12 text-lg font-semibold"
                  disabled={isLoading}
                >
                  {isLoading ? "Creating Account..." : "Create Institution Account"}
                </Button>
              </form>

              <div className="text-center mt-6">
                <p className="text-muted-foreground">
                  Already have an account?{" "}
                  <a href="/login" className="text-primary hover:underline font-medium">
                    Sign in here
                  </a>
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
