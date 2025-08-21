import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Slider } from "@/components/ui/slider";
import { ProgressBar } from "@/components/ui/progress-bar";
import { PasswordStrength } from "@/components/ui/password-strength";
import { Header } from "@/components/layout/Header";
import { 
  ArrowLeft, 
  ArrowRight, 
  User, 
  Mail, 
  Lock, 
  Upload, 
  Calendar,
  MapPin,
  BookOpen,
  DollarSign,
  AlertCircle,
  Phone,
  CreditCard,
  Loader2
} from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { emailRegex } from "@/lib/validation";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

interface TutorFormData {
  // Page 1: Basic Information
  title: string;
  fullName: string;
  mobileNumber: string;
  email: string;
  password: string;
  confirmPassword: string;
  dateOfBirth: string;
  gender: string;
  city: string;
  area: string;
  pinCode: string;
  termsAccepted: boolean;
  backgroundVerificationAccepted: boolean;

  // Page 2: Professional Details
  highestQualification: string;
  universityName: string;
  yearOfPassing: string;
  percentage: string;
  certificate: File | null;
  teachingExperience: string;
  previousExperience: string;
  currentlyTeaching: string;
  currentTeachingPlace: string;
  subjects: string[];
  studentLevels: string[];
  curriculum: string[];

  // Page 3: Service Information
  classType: string;
  maxTravelDistance: number;
  classSize: string[];
  availableDays: string[];
  timeSlots: Record<string, string[]>;
  individualFee: string;
  groupFee: string;
  homeTuitionFee: string;
  demoClass: string;
  demoClassFee: string;
  assignmentHelp: string;
  testPreparation: string;
  homeworkSupport: string;
  weekendClasses: string;

  // Page 4: Profile & Verification
  profilePhoto: File | null;
  profileHeadline: string;
  teachingMethodology: string;
  whyChooseMe: string;
  languages: string[];
  governmentId: File | null;
  addressProof: File | null;
  educationalCertificates: File[];
  experienceCertificates: File[];
  videoIntroduction: File | null;
}

interface ValidationErrors {
  [key: string]: string;
}

const initialFormData: TutorFormData = {
  title: "",
  fullName: "",
  mobileNumber: "",
  email: "",
  password: "",
  confirmPassword: "",
  dateOfBirth: "",
  gender: "",
  city: "",
  area: "",
  pinCode: "",
  termsAccepted: false,
  backgroundVerificationAccepted: false,
  highestQualification: "",
  universityName: "",
  yearOfPassing: "",
  percentage: "",
  certificate: null,
  teachingExperience: "",
  previousExperience: "",
  currentlyTeaching: "",
  currentTeachingPlace: "",
  subjects: [],
  studentLevels: [],
  curriculum: [],
  classType: "",
  maxTravelDistance: 10,
  classSize: [],
  availableDays: [],
  timeSlots: {},
  individualFee: "",
  groupFee: "",
  homeTuitionFee: "",
  demoClass: "",
  demoClassFee: "",
  assignmentHelp: "",
  testPreparation: "",
  homeworkSupport: "",
  weekendClasses: "",
  profilePhoto: null,
  profileHeadline: "",
  teachingMethodology: "",
  whyChooseMe: "",
  languages: [],
  governmentId: null,
  addressProof: null,
  educationalCertificates: [],
  experienceCertificates: [],
  videoIntroduction: null,
};

export default function TutorSignUp() {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<TutorFormData>(initialFormData);
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [touchedFields, setTouchedFields] = useState<Set<string>>(new Set());
  const [isSubmitting, setIsSubmitting] = useState(false);
  const totalSteps = 4;
  const navigate = useNavigate();
  const { toast } = useToast();

  const titles = ["Mr.", "Mrs.", "Ms.", "Dr."];
  const qualifications = ["10th", "12th", "Graduate", "Post-Graduate", "PhD"];
  const experienceLevels = ["Fresher", "1-2 years", "3-5 years", "5+ years"];
  const subjects = [
    "Mathematics", "Physics", "Chemistry", "Biology", "English", "Hindi",
    "History", "Geography", "Economics", "Computer Science", "Programming"
  ];
  const studentLevels = ["Primary", "Secondary", "Higher Secondary", "Graduate", "Professional"];
  const curriculums = ["CBSE", "ICSE", "State Board", "IB", "Cambridge", "NIOS"];
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const languages = ["English", "Hindi", "Bengali", "Tamil", "Telugu", "Marathi", "Gujarati"];

  const validateField = (field: keyof TutorFormData, value: any) => {
    const newErrors = { ...errors };
    
    switch (field) {
      case 'fullName':
        if (!value || value.trim().split(' ').length < 2) {
          newErrors.fullName = 'Full name must contain at least 2 words';
        } else {
          delete newErrors.fullName;
        }
        break;
        
      case 'mobileNumber':
        if (!value || !/^\d{10}$/.test(value)) {
          newErrors.mobileNumber = 'Mobile number must be exactly 10 digits';
        } else {
          delete newErrors.mobileNumber;
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
        
      case 'dateOfBirth':
        if (!value) {
          newErrors.dateOfBirth = 'Date of birth is required';
        } else {
          const birthDate = new Date(value);
          const today = new Date();
          const age = today.getFullYear() - birthDate.getFullYear();
          if (age < 18) {
            newErrors.dateOfBirth = 'You must be at least 18 years old';
          } else {
            delete newErrors.dateOfBirth;
          }
        }
        break;
        
      case 'pinCode':
        if (!value || !/^\d{6}$/.test(value)) {
          newErrors.pinCode = 'Pin code must be exactly 6 digits';
        } else {
          delete newErrors.pinCode;
        }
        break;
    }
    
    setErrors(newErrors);
  };

  const handleInputChange = (field: keyof TutorFormData, value: any) => {
    setFormData({ ...formData, [field]: value });
    setTouchedFields(prev => new Set(prev).add(field));
    validateField(field, value);
  };

  const handleArrayChange = (field: keyof TutorFormData, value: string, checked: boolean) => {
    const currentArray = (formData[field] as string[]) || [];
    const newArray = checked 
      ? [...currentArray, value]
      : currentArray.filter(item => item !== value);
    
    setFormData({ ...formData, [field]: newArray });
  };

  const validateStep = (step: number) => {
    // Basic validation for each step
    const requiredFields: Record<number, (keyof TutorFormData)[]> = {
      1: ['title', 'fullName', 'mobileNumber', 'email', 'password', 'confirmPassword', 'dateOfBirth', 'gender', 'city', 'area', 'pinCode'],
      2: ['highestQualification', 'universityName', 'yearOfPassing', 'percentage', 'teachingExperience'],
      3: ['classType', 'individualFee', 'groupFee', 'demoClass'],
      4: ['profileHeadline', 'teachingMethodology']
    };

    const fields = requiredFields[step] || [];
    let isValid = true;

    fields.forEach(field => {
      if (!formData[field] || (Array.isArray(formData[field]) && (formData[field] as any[]).length === 0)) {
        isValid = false;
      }
    });

    if (step === 1 && (!formData.termsAccepted || !formData.backgroundVerificationAccepted)) {
      isValid = false;
    }

    return isValid;
  };

  const handleNext = () => {
    if (validateStep(currentStep) && currentStep < totalSteps) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmit = async () => {
    if (!validateStep(4)) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields correctly.",
        variant: "destructive",
      });
      return;
    }

    setIsSubmitting(true);

    try {
      console.log('Starting tutor signup process...');
      
      // Step 1: Create user account with Supabase Auth
      console.log('Creating user account...');
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            full_name: formData.fullName,
            role: 'tutor',
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
      // RLS policies are likely blocking profile creation during signup
      console.log('Storing form data for profile creation after email verification...');
      
      // Store the complete form data and user info
      const profileData = {
        userId: authData.user.id,
        formData: formData,
        timestamp: Date.now(),
        email: formData.email
      };
      
      localStorage.setItem('pendingTutorProfile', JSON.stringify(profileData));
      
      console.log('Form data stored successfully');

      // Step 4: Upload profile photo if provided
      if (formData.profilePhoto) {
        try {
          const fileExt = formData.profilePhoto.name.split('.').pop();
          const fileName = `${authData.user.id}-profile.${fileExt}`;
          
          const { error: uploadError } = await supabase.storage
            .from('profile-photos')
            .upload(fileName, formData.profilePhoto);

          if (!uploadError) {
            // Update profile with photo URL
            const { data: photoData } = supabase.storage
              .from('profile-photos')
              .getPublicUrl(fileName);

            await supabase
              .from('profiles')
              .update({ profile_photo_url: photoData.publicUrl })
              .eq('user_id', authData.user.id);
          }
        } catch (uploadError) {
          console.warn('Profile photo upload failed:', uploadError);
          // Continue without photo upload - not critical for account creation
        }
      }

      // Store form data in localStorage for profile creation after email verification
      // Since we're not attempting profile creation during signup due to RLS, always store the data
      localStorage.setItem('pendingTutorProfile', JSON.stringify({
        userId: authData.user.id,
        formData: formData,
        timestamp: Date.now()
      }));
      
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

  const renderStep1 = () => (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Basic Information</h2>
        <p className="text-muted-foreground">Tell us about yourself to get started</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <Label>Title *</Label>
          <Select value={formData.title} onValueChange={(value) => handleInputChange("title", value)}>
            <SelectTrigger className="h-12">
              <SelectValue placeholder="Select title" />
            </SelectTrigger>
            <SelectContent>
              {titles.map((title) => (
                <SelectItem key={title} value={title}>{title}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

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
          <Label htmlFor="mobileNumber">Mobile Number *</Label>
          <div className="relative">
            <Phone className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              id="mobileNumber"
              placeholder="10-digit mobile number"
              value={formData.mobileNumber}
              onChange={(e) => handleInputChange("mobileNumber", e.target.value)}
              className={`pl-10 h-12 ${errors.mobileNumber && touchedFields.has('mobileNumber') ? 'border-destructive' : ''}`}
              required
            />
            {errors.mobileNumber && touchedFields.has('mobileNumber') && (
              <div className="flex items-center mt-1 text-destructive text-sm">
                <AlertCircle className="h-4 w-4 mr-1" />
                {errors.mobileNumber}
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
              className={`pl-10 h-12 ${errors.dateOfBirth && touchedFields.has('dateOfBirth') ? 'border-destructive' : ''}`}
              required
            />
            {errors.dateOfBirth && touchedFields.has('dateOfBirth') && (
              <div className="flex items-center mt-1 text-destructive text-sm">
                <AlertCircle className="h-4 w-4 mr-1" />
                {errors.dateOfBirth}
              </div>
            )}
          </div>
        </div>

        <div className="space-y-2">
          <Label>Gender *</Label>
          <RadioGroup value={formData.gender} onValueChange={(value) => handleInputChange("gender", value)}>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="male" id="male" />
              <Label htmlFor="male">Male</Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="female" id="female" />
              <Label htmlFor="female">Female</Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="other" id="other" />
              <Label htmlFor="other">Other</Label>
            </div>
          </RadioGroup>
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
          <Label htmlFor="pinCode">Pin Code *</Label>
          <div className="relative">
            <CreditCard className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              id="pinCode"
              placeholder="6-digit pin code"
              value={formData.pinCode}
              onChange={(e) => handleInputChange("pinCode", e.target.value)}
              className={`pl-10 h-12 ${errors.pinCode && touchedFields.has('pinCode') ? 'border-destructive' : ''}`}
              required
            />
            {errors.pinCode && touchedFields.has('pinCode') && (
              <div className="flex items-center mt-1 text-destructive text-sm">
                <AlertCircle className="h-4 w-4 mr-1" />
                {errors.pinCode}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <div className="flex items-start space-x-2">
          <Checkbox 
            id="termsAccepted"
            checked={formData.termsAccepted}
            onCheckedChange={(checked) => handleInputChange("termsAccepted", checked)}
          />
          <Label htmlFor="termsAccepted" className="text-sm leading-5">
            I agree to the{" "}
            <Link to="/terms" className="text-primary hover:underline">
              Terms and Conditions
            </Link>{" "}
            *
          </Label>
        </div>

        <div className="flex items-start space-x-2">
          <Checkbox 
            id="backgroundVerificationAccepted"
            checked={formData.backgroundVerificationAccepted}
            onCheckedChange={(checked) => handleInputChange("backgroundVerificationAccepted", checked)}
          />
          <Label htmlFor="backgroundVerificationAccepted" className="text-sm leading-5">
            I agree to Background Verification *
          </Label>
        </div>
      </div>
    </div>
  );

  const renderStep2 = () => (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Professional Details</h2>
        <p className="text-muted-foreground">Share your educational background and experience</p>
      </div>

      {/* Educational Qualifications */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Educational Qualifications</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label>Highest Qualification *</Label>
            <Select value={formData.highestQualification} onValueChange={(value) => handleInputChange("highestQualification", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Select qualification" />
              </SelectTrigger>
              <SelectContent>
                {qualifications.map((qual) => (
                  <SelectItem key={qual} value={qual}>{qual}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="universityName">University/Board Name *</Label>
            <Input
              id="universityName"
              placeholder="Enter university or board name"
              value={formData.universityName}
              onChange={(e) => handleInputChange("universityName", e.target.value)}
              className="h-12"
              required
            />
          </div>

          <div className="space-y-2">
            <Label>Year of Passing *</Label>
            <Select value={formData.yearOfPassing} onValueChange={(value) => handleInputChange("yearOfPassing", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Select year" />
              </SelectTrigger>
              <SelectContent>
                {Array.from({ length: 50 }, (_, i) => new Date().getFullYear() - i).map((year) => (
                  <SelectItem key={year} value={year.toString()}>{year}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="percentage">Percentage/CGPA *</Label>
            <Input
              id="percentage"
              placeholder="Enter percentage or CGPA"
              value={formData.percentage}
              onChange={(e) => handleInputChange("percentage", e.target.value)}
              className="h-12"
              required
            />
          </div>

          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="certificate">Upload Certificate *</Label>
            <Input
              id="certificate"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={(e) => handleInputChange("certificate", e.target.files?.[0] || null)}
              className="h-12"
              required
            />
            <p className="text-xs text-muted-foreground">PDF/JPG format, max 5MB</p>
          </div>
        </div>
      </div>

      {/* Teaching Experience */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Teaching Experience</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label>Total Teaching Experience *</Label>
            <Select value={formData.teachingExperience} onValueChange={(value) => handleInputChange("teachingExperience", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Select experience" />
              </SelectTrigger>
              <SelectContent>
                {experienceLevels.map((exp) => (
                  <SelectItem key={exp} value={exp}>{exp}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>Currently Teaching</Label>
            <RadioGroup value={formData.currentlyTeaching} onValueChange={(value) => handleInputChange("currentlyTeaching", value)}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="yes" id="teaching-yes" />
                <Label htmlFor="teaching-yes">Yes</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="no" id="teaching-no" />
                <Label htmlFor="teaching-no">No</Label>
              </div>
            </RadioGroup>
          </div>

          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="previousExperience">Previous Teaching Experience</Label>
            <Textarea
              id="previousExperience"
              placeholder="Describe your teaching experience (optional)"
              value={formData.previousExperience}
              onChange={(e) => handleInputChange("previousExperience", e.target.value)}
              className="min-h-20"
            />
          </div>

          {formData.currentlyTeaching === "yes" && (
            <div className="space-y-2 md:col-span-2">
              <Label htmlFor="currentTeachingPlace">Where are you currently teaching?</Label>
              <Input
                id="currentTeachingPlace"
                placeholder="Enter current teaching place"
                value={formData.currentTeachingPlace}
                onChange={(e) => handleInputChange("currentTeachingPlace", e.target.value)}
                className="h-12"
              />
            </div>
          )}
        </div>
      </div>

      {/* Specialization */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Specialization</h3>
        
        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Subjects/Skills to Teach *</Label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {subjects.map((subject) => (
                <div key={subject} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`subject-${subject}`}
                    checked={formData.subjects.includes(subject)}
                    onCheckedChange={(checked) => handleArrayChange("subjects", subject, checked as boolean)}
                  />
                  <Label htmlFor={`subject-${subject}`} className="text-sm">{subject}</Label>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label>Student Levels *</Label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {studentLevels.map((level) => (
                <div key={level} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`level-${level}`}
                    checked={formData.studentLevels.includes(level)}
                    onCheckedChange={(checked) => handleArrayChange("studentLevels", level, checked as boolean)}
                  />
                  <Label htmlFor={`level-${level}`} className="text-sm">{level}</Label>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label>Board/Curriculum *</Label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {curriculums.map((curriculum) => (
                <div key={curriculum} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`curriculum-${curriculum}`}
                    checked={formData.curriculum.includes(curriculum)}
                    onCheckedChange={(checked) => handleArrayChange("curriculum", curriculum, checked as boolean)}
                  />
                  <Label htmlFor={`curriculum-${curriculum}`} className="text-sm">{curriculum}</Label>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep3 = () => (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Service Information</h2>
        <p className="text-muted-foreground">Define your teaching preferences and pricing</p>
      </div>

      {/* Teaching Preferences */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Teaching Preferences</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label>Class Type *</Label>
            <RadioGroup value={formData.classType} onValueChange={(value) => handleInputChange("classType", value)}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="online" id="online" />
                <Label htmlFor="online">Online</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="offline" id="offline" />
                <Label htmlFor="offline">Offline</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="both" id="both" />
                <Label htmlFor="both">Both</Label>
              </div>
            </RadioGroup>
          </div>

          {(formData.classType === "offline" || formData.classType === "both") && (
            <div className="space-y-2">
              <Label>Maximum Travel Distance (km): {formData.maxTravelDistance}</Label>
              <Slider
                value={[formData.maxTravelDistance]}
                onValueChange={(value) => handleInputChange("maxTravelDistance", value[0])}
                max={50}
                min={0}
                step={5}
                className="w-full"
              />
            </div>
          )}

          <div className="space-y-2 md:col-span-2">
            <Label>Preferred Class Size</Label>
            <div className="flex space-x-4">
              {["Individual", "Group", "Both"].map((size) => (
                <div key={size} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`size-${size}`}
                    checked={formData.classSize.includes(size)}
                    onCheckedChange={(checked) => handleArrayChange("classSize", size, checked as boolean)}
                  />
                  <Label htmlFor={`size-${size}`}>{size}</Label>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2 md:col-span-2">
            <Label>Available Days *</Label>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
              {days.map((day) => (
                <div key={day} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`day-${day}`}
                    checked={formData.availableDays.includes(day)}
                    onCheckedChange={(checked) => handleArrayChange("availableDays", day, checked as boolean)}
                  />
                  <Label htmlFor={`day-${day}`} className="text-sm">{day}</Label>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Fee Structure */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Fee Structure</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label htmlFor="individualFee">Individual Class Fee (per hour) * ₹</Label>
            <div className="relative">
              <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="individualFee"
                placeholder="Enter hourly rate"
                value={formData.individualFee}
                onChange={(e) => handleInputChange("individualFee", e.target.value)}
                className="pl-10 h-12"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="groupFee">Group Class Fee (per hour) * ₹</Label>
            <div className="relative">
              <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="groupFee"
                placeholder="Enter hourly rate"
                value={formData.groupFee}
                onChange={(e) => handleInputChange("groupFee", e.target.value)}
                className="pl-10 h-12"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="homeTuitionFee">Home Tuition Fee (per hour) ₹</Label>
            <div className="relative">
              <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="homeTuitionFee"
                placeholder="Enter hourly rate (optional)"
                value={formData.homeTuitionFee}
                onChange={(e) => handleInputChange("homeTuitionFee", e.target.value)}
                className="pl-10 h-12"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Demo Class</Label>
            <RadioGroup value={formData.demoClass} onValueChange={(value) => handleInputChange("demoClass", value)}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="free" id="demo-free" />
                <Label htmlFor="demo-free">Free</Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="paid" id="demo-paid" />
                <Label htmlFor="demo-paid">Paid</Label>
              </div>
            </RadioGroup>
          </div>

          {formData.demoClass === "paid" && (
            <div className="space-y-2">
              <Label htmlFor="demoClassFee">Demo Class Fee ₹</Label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="demoClassFee"
                  placeholder="Enter demo class fee"
                  value={formData.demoClassFee}
                  onChange={(e) => handleInputChange("demoClassFee", e.target.value)}
                  className="pl-10 h-12"
                />
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Additional Services */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Additional Services</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {[
            { key: "assignmentHelp", label: "Assignment Help" },
            { key: "testPreparation", label: "Test/Exam Preparation" },
            { key: "homeworkSupport", label: "Homework Support" },
            { key: "weekendClasses", label: "Weekend Classes" }
          ].map(({ key, label }) => (
            <div key={key} className="space-y-2">
              <Label>{label}</Label>
              <RadioGroup 
                value={formData[key as keyof TutorFormData] as string} 
                onValueChange={(value) => handleInputChange(key as keyof TutorFormData, value)}
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="yes" id={`${key}-yes`} />
                  <Label htmlFor={`${key}-yes`}>Yes</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="no" id={`${key}-no`} />
                  <Label htmlFor={`${key}-no`}>No</Label>
                </div>
              </RadioGroup>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const renderStep4 = () => (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Profile & Verification</h2>
        <p className="text-muted-foreground">Complete your profile and upload verification documents</p>
      </div>

      {/* Profile Setup */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Profile Setup</h3>
        
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="profilePhoto">Profile Photo *</Label>
            <Input
              id="profilePhoto"
              type="file"
              accept="image/*"
              onChange={(e) => handleInputChange("profilePhoto", e.target.files?.[0] || null)}
              className="h-12"
              required
            />
            <p className="text-xs text-muted-foreground">Square image recommended, max 5MB</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="profileHeadline">Profile Headline * (100 chars max)</Label>
            <Input
              id="profileHeadline"
              placeholder="e.g., Experienced Math Tutor with 5+ years"
              value={formData.profileHeadline}
              onChange={(e) => handleInputChange("profileHeadline", e.target.value)}
              className="h-12"
              maxLength={100}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="teachingMethodology">Teaching Methodology * (500 words max)</Label>
            <Textarea
              id="teachingMethodology"
              placeholder="Describe your teaching approach and methodology"
              value={formData.teachingMethodology}
              onChange={(e) => handleInputChange("teachingMethodology", e.target.value)}
              className="min-h-32"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="whyChooseMe">Why Choose Me? (300 words max)</Label>
            <Textarea
              id="whyChooseMe"
              placeholder="What makes you unique as a tutor?"
              value={formData.whyChooseMe}
              onChange={(e) => handleInputChange("whyChooseMe", e.target.value)}
              className="min-h-24"
            />
          </div>

          <div className="space-y-2">
            <Label>Languages Known *</Label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {languages.map((language) => (
                <div key={language} className="flex items-center space-x-2">
                  <Checkbox 
                    id={`language-${language}`}
                    checked={formData.languages.includes(language)}
                    onCheckedChange={(checked) => handleArrayChange("languages", language, checked as boolean)}
                  />
                  <Label htmlFor={`language-${language}`} className="text-sm">{language}</Label>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Verification Documents */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Verification Documents</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label htmlFor="governmentId">Government ID * (Aadhaar/PAN/Passport)</Label>
            <Input
              id="governmentId"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={(e) => handleInputChange("governmentId", e.target.files?.[0] || null)}
              className="h-12"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="addressProof">Address Proof *</Label>
            <Input
              id="addressProof"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={(e) => handleInputChange("addressProof", e.target.files?.[0] || null)}
              className="h-12"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="educationalCertificates">Educational Certificates *</Label>
            <Input
              id="educationalCertificates"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              multiple
              onChange={(e) => handleInputChange("educationalCertificates", Array.from(e.target.files || []))}
              className="h-12"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="experienceCertificates">Experience Certificates</Label>
            <Input
              id="experienceCertificates"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png"
              multiple
              onChange={(e) => handleInputChange("experienceCertificates", Array.from(e.target.files || []))}
              className="h-12"
            />
          </div>
        </div>
      </div>

      {/* Video Introduction */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Video Introduction</h3>
        
        <div className="space-y-2">
          <Label htmlFor="videoIntroduction">Record/Upload Video (max 2 minutes)</Label>
          <Input
            id="videoIntroduction"
            type="file"
            accept="video/*"
            onChange={(e) => handleInputChange("videoIntroduction", e.target.files?.[0] || null)}
            className="h-12"
          />
          <div className="bg-muted p-4 rounded-lg">
            <h4 className="font-medium mb-2">Video Guidelines:</h4>
            <ul className="text-sm text-muted-foreground space-y-1">
              <li>• Introduce yourself clearly</li>
              <li>• Mention your teaching experience</li>
              <li>• Explain your teaching methodology</li>
              <li>• Keep it under 2 minutes</li>
              <li>• Ensure good lighting and audio</li>
            </ul>
          </div>
          <Button variant="outline" className="w-full">
            Skip for now
          </Button>
        </div>
      </div>

      {/* Final Steps */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Final Steps</h3>
        
        <div className="bg-info/10 p-4 rounded-lg">
          <h4 className="font-medium mb-2">What happens next?</h4>
          <ul className="text-sm space-y-1">
            <li>• Email verification will be sent to your email</li>
            <li>• Mobile OTP verification required</li>
            <li>• Profile will be submitted for admin review</li>
            <li>• Review process takes 24-48 hours</li>
            <li>• You'll be notified once approved</li>
          </ul>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-background">
      <Header />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <Card className="shadow-lg">
            <CardHeader className="text-center">
              <CardTitle className="text-3xl font-bold bg-gradient-primary bg-clip-text text-transparent">
                Join as a Tutor
              </CardTitle>
              <CardDescription className="text-lg">
                Share your knowledge and help students excel
              </CardDescription>
              
              <div className="mt-6">
                <ProgressBar currentStep={currentStep} totalSteps={totalSteps} />
              </div>
            </CardHeader>
            
            <CardContent>
              <div className="mb-8">
                {currentStep === 1 && renderStep1()}
                {currentStep === 2 && renderStep2()}
                {currentStep === 3 && renderStep3()}
                {currentStep === 4 && renderStep4()}
              </div>

              <div className="flex justify-between">
                <Button
                  variant="outline"
                  onClick={handlePrevious}
                  disabled={currentStep === 1}
                  className="flex items-center space-x-2"
                >
                  <ArrowLeft className="h-4 w-4" />
                  <span>Previous</span>
                </Button>

                {currentStep < totalSteps ? (
                  <Button
                    onClick={handleNext}
                    disabled={!validateStep(currentStep)}
                    className="flex items-center space-x-2"
                  >
                    <span>Next</span>
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                ) : (
                  <Button
                    onClick={handleSubmit}
                    disabled={!validateStep(4) || isSubmitting}
                    className="flex items-center space-x-2"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        <span>Creating Account...</span>
                      </>
                    ) : (
                      <>
                        <span>Submit for Review</span>
                        <ArrowRight className="h-4 w-4" />
                      </>
                    )}
                  </Button>
                )}
              </div>

              <div className="text-center mt-6">
                <p className="text-muted-foreground">
                  Already have an account?{" "}
                  <Link to="/login" className="text-primary hover:underline font-medium">
                    Sign in here
                  </Link>
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}