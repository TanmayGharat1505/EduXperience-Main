import { z } from "zod";

// Email validation regex
export const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

// Password strength validation
export const passwordValidation = z
  .string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[A-Z]/, "Password must contain at least one uppercase letter")
  .regex(/[a-z]/, "Password must contain at least one lowercase letter")
  .regex(/\d/, "Password must contain at least one number")
  .regex(/[!@#$%^&*(),.?":{}|<>]/, "Password must contain at least one special character");

// Step 1 validation schema
export const step1Schema = z.object({
  fullName: z.string()
    .min(2, "Full name must be at least 2 characters")
    .max(50, "Full name must be less than 50 characters")
    .regex(/^[a-zA-Z\s]+$/, "Full name can only contain letters and spaces"),
  
  email: z.string()
    .email("Please enter a valid email address")
    .regex(emailRegex, "Please enter a valid email format"),
  
  password: passwordValidation,
  
  confirmPassword: z.string(),
  
  dateOfBirth: z.string()
    .min(1, "Date of birth is required"),
  
  educationLevel: z.string()
    .min(1, "Education level is required"),
  
  city: z.string()
    .min(2, "City is required"),
  
  area: z.string()
    .min(2, "Area is required"),
  
  primaryLanguage: z.string()
    .min(1, "Primary language is required"),
    
  termsAccepted: z.boolean()
    .refine(val => val === true, "You must accept the terms and conditions")
    
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
});

// Step 2 validation schema
export const step2Schema = z.object({
  subjectInterests: z.array(z.string())
    .min(1, "Please select at least one subject of interest"),
  
  learningObjectives: z.array(z.string())
    .min(1, "Please select at least one learning objective"),
  
  timeline: z.string()
    .min(1, "Please select your expected timeline"),
});

// Step 3 validation schema
export const step3Schema = z.object({
  learningMode: z.string()
    .min(1, "Please select your preferred learning mode"),
  
  classDuration: z.string()
    .min(1, "Please select your preferred class duration"),
  
  frequency: z.string()
    .min(1, "Please select your preferred frequency"),
});

// Step 4 validation schema
export const step4Schema = z.object({
  tutorGender: z.string()
    .min(1, "Please select your tutor gender preference"),
  
  instructionLanguage: z.string()
    .min(1, "Please select your instruction language preference"),
  
  teachingMethodology: z.string()
    .min(1, "Please select your teaching methodology preference"),
  
  classType: z.string()
    .min(1, "Please select your class type preference"),
});

export type Step1Data = z.infer<typeof step1Schema>;
export type Step2Data = z.infer<typeof step2Schema>;
export type Step3Data = z.infer<typeof step3Schema>;
export type Step4Data = z.infer<typeof step4Schema>;

// Validation functions
export const validateStep1 = (data: any) => step1Schema.safeParse(data);
export const validateStep2 = (data: any) => step2Schema.safeParse(data);
export const validateStep3 = (data: any) => step3Schema.safeParse(data);
export const validateStep4 = (data: any) => step4Schema.safeParse(data);