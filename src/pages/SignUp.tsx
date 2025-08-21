import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
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
  Target,
  Clock,
  DollarSign,
  Users,
  Heart,
  CheckCircle,
  AlertCircle
} from "lucide-react";
import { Link } from "react-router-dom";
import { validateStep1, validateStep2, validateStep3, validateStep4, emailRegex } from "@/lib/validation";

interface FormData {
  // Step 1: Basic Information
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

  // Step 2: Learning Goals
  subjectInterests: string[];
  proficiencyLevels: Record<string, string>;
  learningObjectives: string[];
  timeline: string;

  // Step 3: Class Preferences
  learningMode: string;
  offlineRadius: string;
  budgetRange: [number, number];
  schedule: Record<string, string[]>;
  classDuration: string;
  frequency: string;

  // Step 4: Additional Preferences
  tutorGender: string;
  instructionLanguage: string;
  specialRequirements: string;
  teachingMethodology: string;
  classType: string;
}

interface ValidationErrors {
  [key: string]: string;
}

const initialFormData: FormData = {
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
  subjectInterests: [],
  proficiencyLevels: {},
  learningObjectives: [],
  timeline: "",
  learningMode: "",
  offlineRadius: "",
  budgetRange: [500, 2000],
  schedule: {},
  classDuration: "",
  frequency: "",
  tutorGender: "",
  instructionLanguage: "",
  specialRequirements: "",
  teachingMethodology: "",
  classType: "",
};

export default function SignUp() {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [touchedFields, setTouchedFields] = useState<Set<string>>(new Set());
  const totalSteps = 4;

  const educationLevels = [
    "Class 1-5", "Class 6-8", "Class 9-10", "Class 11-12",
    "Undergraduate", "Graduate", "Professional", "Other"
  ];

  const subjectCategories = {
    academic: [
      "Mathematics", "Physics", "Chemistry", "Biology", "English", 
      "Hindi", "History", "Geography", "Economics", "Political Science"
    ],
    professional: [
      "Programming", "Web Development", "Data Science", "Digital Marketing",
      "Graphic Design", "UI/UX Design", "Business Analytics", "Finance"
    ],
    creative: [
      "Music", "Dance", "Painting", "Photography", "Cooking", 
      "Creative Writing", "Theatre", "Yoga", "Meditation"
    ],
    testPrep: [
      "JEE Main/Advanced", "NEET", "CAT", "GATE", "UPSC", 
      "IELTS", "TOEFL", "GRE", "GMAT", "SSC"
    ]
  };

  // Real-time validation function
  const validateField = (field: keyof FormData, value: any) => {
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
        
      case 'dateOfBirth':
        if (!value) {
          newErrors.dateOfBirth = 'Date of birth is required';
        } else {
          delete newErrors.dateOfBirth;
        }
        break;
        
      case 'educationLevel':
        if (!value) {
          newErrors.educationLevel = 'Education level is required';
        } else {
          delete newErrors.educationLevel;
        }
        break;
        
      case 'city':
        if (!value || value.trim().length < 2) {
          newErrors.city = 'City is required';
        } else {
          delete newErrors.city;
        }
        break;
        
      case 'area':
        if (!value || value.trim().length < 2) {
          newErrors.area = 'Area is required';
        } else {
          delete newErrors.area;
        }
        break;
        
      case 'primaryLanguage':
        if (!value) {
          newErrors.primaryLanguage = 'Primary language is required';
        } else {
          delete newErrors.primaryLanguage;
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

  const handleInputChange = (field: keyof FormData, value: any) => {
    setFormData({ ...formData, [field]: value });
    setTouchedFields(prev => new Set(prev).add(field));
    
    // Real-time validation
    validateField(field, value);
  };

  const validateStep = (step: number) => {
    const currentData = formData;
    let validation;
    
    switch (step) {
      case 1:
        validation = validateStep1({ ...currentData });
        break;
      case 2:
        validation = validateStep2({ ...currentData });
        break;
      case 3:
        validation = validateStep3({ ...currentData });
        break;
      case 4:
        validation = validateStep4({ ...currentData });
        break;
      default:
        return true;
    }
    
    if (!validation.success) {
      const newErrors: ValidationErrors = {};
      validation.error.errors.forEach(err => {
        newErrors[err.path[0]] = err.message;
      });
      setErrors(newErrors);
      return false;
    }
    
    return true;
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

  const handleSubmit = () => {
    if (!validateStep(4) || !formData.termsAccepted) {
      return;
    }
    // Form submission logic will be implemented when Supabase is connected
    console.log("Form submitted:", formData);
  };

  const renderStep1 = () => (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Let's Get Started</h2>
        <p className="text-muted-foreground">Tell us about yourself to create your learning profile</p>
      </div>

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

        <div className="mt-6">
          <div className="flex items-start space-x-2">
            <Checkbox 
              id="termsAccepted"
              checked={formData.termsAccepted}
              onCheckedChange={(checked) => handleInputChange("termsAccepted", checked)}
              className={errors.termsAccepted ? 'border-destructive' : ''}
            />
            <div className="space-y-1">
              <Label htmlFor="termsAccepted" className="text-sm font-normal cursor-pointer">
                I agree to the <Link to="/terms" className="text-primary hover:text-primary-soft underline">Terms of Service</Link> and <Link to="/privacy" className="text-primary hover:text-primary-soft underline">Privacy Policy</Link> *
              </Label>
              {errors.termsAccepted && (
                <div className="flex items-center text-destructive text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.termsAccepted}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep2 = () => (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Learning Goals</h2>
        <p className="text-muted-foreground">Help us understand what you want to learn and achieve</p>
      </div>

      <div className="space-y-6">
        <div>
          <Label className="text-lg font-semibold mb-4 block">What subjects or skills interest you? *</Label>
          {Object.entries(subjectCategories).map(([category, subjects]) => (
            <div key={category} className="mb-6">
              <h4 className="font-medium text-primary capitalize mb-3">{category.replace(/([A-Z])/g, ' $1')} Subjects</h4>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {subjects.map((subject) => (
                  <div key={subject} className="flex items-center space-x-2">
                    <Checkbox 
                      id={subject}
                      checked={formData.subjectInterests.includes(subject)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          handleInputChange("subjectInterests", [...formData.subjectInterests, subject]);
                        } else {
                          handleInputChange("subjectInterests", formData.subjectInterests.filter(s => s !== subject));
                        }
                      }}
                    />
                    <Label htmlFor={subject} className="text-sm font-normal cursor-pointer">{subject}</Label>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div>
          <Label className="text-lg font-semibold mb-4 block">Learning Objectives *</Label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {["Exam Preparation", "Skill Building", "Career Advancement", "Personal Interest", "Academic Support", "Professional Certification"].map((objective) => (
              <div key={objective} className="flex items-center space-x-2">
                <Checkbox 
                  id={objective}
                  checked={formData.learningObjectives.includes(objective)}
                  onCheckedChange={(checked) => {
                    if (checked) {
                      handleInputChange("learningObjectives", [...formData.learningObjectives, objective]);
                    } else {
                      handleInputChange("learningObjectives", formData.learningObjectives.filter(o => o !== objective));
                    }
                  }}
                />
                <Label htmlFor={objective} className="text-sm font-normal cursor-pointer">{objective}</Label>
              </div>
            ))}
          </div>
        </div>

        <div>
          <Label className="text-lg font-semibold mb-4 block">Expected Learning Timeline *</Label>
          <Select value={formData.timeline} onValueChange={(value) => handleInputChange("timeline", value)}>
            <SelectTrigger className="h-12">
              <SelectValue placeholder="When do you want to achieve your goals?" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="immediate">Immediate (Within 2 weeks)</SelectItem>
              <SelectItem value="1month">Within 1 month</SelectItem>
              <SelectItem value="3months">Within 3 months</SelectItem>
              <SelectItem value="6months">Within 6 months</SelectItem>
              <SelectItem value="1year">Within 1 year</SelectItem>
              <SelectItem value="longterm">Long-term (1+ years)</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
  );

  const renderStep3 = () => (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Class Preferences</h2>
        <p className="text-muted-foreground">Tell us how you prefer to learn</p>
      </div>

      <div className="space-y-6">
        <div>
          <Label className="text-lg font-semibold mb-4 block">Learning Mode *</Label>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {[
              { value: "online", label: "Online Only", desc: "Learn from anywhere" },
              { value: "offline", label: "Offline Only", desc: "In-person classes" },
              { value: "both", label: "Both", desc: "Flexible options" }
            ].map((mode) => (
              <Card 
                key={mode.value} 
                className={`cursor-pointer transition-all ${formData.learningMode === mode.value ? 'ring-2 ring-primary bg-primary/5' : 'hover:shadow-medium'}`}
                onClick={() => handleInputChange("learningMode", mode.value)}
              >
                <CardContent className="p-4 text-center">
                  <h4 className="font-medium mb-1">{mode.label}</h4>
                  <p className="text-sm text-muted-foreground">{mode.desc}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        <div>
          <Label className="text-lg font-semibold mb-4 block">Budget Range (₹/hour) *</Label>
          <div className="space-y-4">
            <div className="flex items-center justify-between text-sm text-muted-foreground">
              <span>₹{formData.budgetRange[0]}</span>
              <span>₹{formData.budgetRange[1]}</span>
            </div>
            <input
              type="range"
              min="200"
              max="5000"
              step="100"
              value={formData.budgetRange[1]}
              onChange={(e) => handleInputChange("budgetRange", [formData.budgetRange[0], parseInt(e.target.value)])}
              className="w-full"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <Label className="text-lg font-semibold mb-4 block">Class Duration *</Label>
            <Select value={formData.classDuration} onValueChange={(value) => handleInputChange("classDuration", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Preferred duration" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="30min">30 minutes</SelectItem>
                <SelectItem value="45min">45 minutes</SelectItem>
                <SelectItem value="60min">60 minutes</SelectItem>
                <SelectItem value="90min">90 minutes</SelectItem>
                <SelectItem value="120min">2 hours</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label className="text-lg font-semibold mb-4 block">Frequency *</Label>
            <Select value={formData.frequency} onValueChange={(value) => handleInputChange("frequency", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="How often?" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1-2">1-2 times per week</SelectItem>
                <SelectItem value="3-4">3-4 times per week</SelectItem>
                <SelectItem value="daily">Daily</SelectItem>
                <SelectItem value="weekend">Weekends only</SelectItem>
                <SelectItem value="flexible">Flexible schedule</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>
    </div>
  );

  const renderStep4 = () => (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Additional Preferences</h2>
        <p className="text-muted-foreground">Final details to personalize your experience</p>
      </div>

      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <Label className="text-lg font-semibold mb-4 block">Tutor Gender Preference</Label>
            <Select value={formData.tutorGender} onValueChange={(value) => handleInputChange("tutorGender", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Select preference" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="male">Male</SelectItem>
                <SelectItem value="female">Female</SelectItem>
                <SelectItem value="no-preference">No Preference</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label className="text-lg font-semibold mb-4 block">Class Type</Label>
            <Select value={formData.classType} onValueChange={(value) => handleInputChange("classType", value)}>
              <SelectTrigger className="h-12">
                <SelectValue placeholder="Select preference" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="individual">Individual (1-on-1)</SelectItem>
                <SelectItem value="small-group">Small Group (2-5 students)</SelectItem>
                <SelectItem value="group">Group Classes (6+ students)</SelectItem>
                <SelectItem value="no-preference">No Preference</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <div>
          <Label className="text-lg font-semibold mb-4 block">Teaching Methodology Preference</Label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { value: "structured", label: "Structured", desc: "Systematic curriculum approach" },
              { value: "flexible", label: "Flexible", desc: "Adaptive to learning pace" },
              { value: "interactive", label: "Interactive", desc: "Discussion-based learning" },
              { value: "traditional", label: "Traditional", desc: "Lecture-style teaching" }
            ].map((method) => (
              <Card 
                key={method.value} 
                className={`cursor-pointer transition-all ${formData.teachingMethodology === method.value ? 'ring-2 ring-primary bg-primary/5' : 'hover:shadow-medium'}`}
                onClick={() => handleInputChange("teachingMethodology", method.value)}
              >
                <CardContent className="p-4">
                  <h4 className="font-medium mb-1">{method.label}</h4>
                  <p className="text-sm text-muted-foreground">{method.desc}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        <div>
          <Label htmlFor="specialRequirements" className="text-lg font-semibold mb-4 block">
            Special Requirements or Learning Needs
          </Label>
          <Textarea
            id="specialRequirements"
            placeholder="Any specific learning disabilities, accessibility needs, or special requirements..."
            value={formData.specialRequirements}
            onChange={(e) => handleInputChange("specialRequirements", e.target.value)}
            className="min-h-[100px]"
          />
        </div>

        <div className="bg-gradient-subtle p-6 rounded-lg">
          <div className="flex items-start space-x-3">
            <CheckCircle className="h-5 w-5 text-secondary mt-0.5" />
            <div>
              <h4 className="font-medium mb-2">Almost Done!</h4>
              <p className="text-sm text-muted-foreground">
                You're about to join thousands of learners who are achieving their goals with EduXperience. 
                After submission, you'll receive an email to verify your account.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-subtle">
      <Header />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <Link 
            to="/" 
            className="inline-flex items-center text-muted-foreground hover:text-primary transition-colors mb-8"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Home
          </Link>

          <Card className="shadow-medium border-none">
            <CardHeader className="pb-4">
              <ProgressBar currentStep={currentStep} totalSteps={totalSteps} />
            </CardHeader>

            <CardContent className="p-8">
              {currentStep === 1 && renderStep1()}
              {currentStep === 2 && renderStep2()}
              {currentStep === 3 && renderStep3()}
              {currentStep === 4 && renderStep4()}

              <div className="flex justify-between pt-8 border-t mt-8">
                <Button
                  variant="outline"
                  onClick={handlePrevious}
                  disabled={currentStep === 1}
                  className="h-12 px-6"
                >
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Previous
                </Button>

                {currentStep < totalSteps ? (
                  <Button
                    onClick={handleNext}
                    className="bg-gradient-primary shadow-soft hover:shadow-medium h-12 px-6"
                  >
                    Next Step
                    <ArrowRight className="h-4 w-4 ml-2" />
                  </Button>
                ) : (
                  <Button
                    onClick={handleSubmit}
                    className="bg-gradient-primary shadow-soft hover:shadow-medium h-12 px-6"
                  >
                    Complete Registration
                    <CheckCircle className="h-4 w-4 ml-2" />
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          <div className="mt-8 text-center">
            <p className="text-xs text-muted-foreground">
              By creating an account, you agree to our{" "}
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