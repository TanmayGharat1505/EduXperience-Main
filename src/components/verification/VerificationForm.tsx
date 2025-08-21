import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { VerificationService } from '@/lib/verification-service';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Upload, FileText, Users, BookOpen, CheckCircle, Plus, X } from 'lucide-react';

interface VerificationFormProps {
  userType: 'tutor' | 'institute';
  onComplete?: () => void;
}

export default function VerificationForm({ userType, onComplete }: VerificationFormProps) {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [currentStep, setCurrentStep] = useState(1);
  const [verificationRequestId, setVerificationRequestId] = useState<string | null>(null);
  const [documents, setDocuments] = useState<Record<string, File>>({});
  const [references, setReferences] = useState<Array<{
    name: string;
    title: string;
    organization: string;
    email: string;
    phone: string;
    relationship: string;
    isContactable: boolean;
  }>>([]);
  const [subjects, setSubjects] = useState<string[]>([]);

  const totalSteps = 4;
  const progress = (currentStep / totalSteps) * 100;

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        navigate('/login');
        return;
      }
      setCurrentUser(user);
    } catch (error) {
      console.error('Auth check error:', error);
      navigate('/login');
    }
  };

  const createVerificationRequest = async () => {
    if (!currentUser) return;

    try {
      setIsLoading(true);
      const result = await VerificationService.createVerificationRequest(
        currentUser.id,
        userType
      );

      if (result.success && result.requestId) {
        setVerificationRequestId(result.requestId);
        toast({
          title: "Verification Request Created",
          description: "Your verification request has been created successfully.",
        });
        setCurrentStep(2);
      } else {
        throw new Error(result.error || 'Failed to create verification request');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to create verification request",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleFileUpload = async (file: File, documentType: string) => {
    if (!verificationRequestId) return;

    try {
      setIsLoading(true);
      const result = await VerificationService.uploadDocument(
        verificationRequestId,
        documentType,
        file
      );

      if (result.success) {
        setDocuments(prev => ({ ...prev, [documentType]: file }));
        toast({
          title: "Document Uploaded",
          description: `${file.name} has been uploaded successfully.`,
        });
      } else {
        throw new Error(result.error || 'Upload failed');
      }
    } catch (error) {
      toast({
        title: "Upload Failed",
        description: error instanceof Error ? error.message : "Failed to upload document",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const addReference = () => {
    setReferences(prev => [...prev, {
      name: '',
      title: '',
      organization: '',
      email: '',
      phone: '',
      relationship: '',
      isContactable: true
    }]);
  };

  const updateReference = (index: number, field: string, value: any) => {
    setReferences(prev => prev.map((ref, i) => 
      i === index ? { ...ref, [field]: value } : ref
    ));
  };

  const removeReference = (index: number) => {
    setReferences(prev => prev.filter((_, i) => i !== index));
  };

  const addSubject = () => {
    const subject = prompt('Enter subject name:');
    if (subject && !subjects.includes(subject)) {
      setSubjects(prev => [...prev, subject]);
    }
  };

  const removeSubject = (subject: string) => {
    setSubjects(prev => prev.filter(s => s !== subject));
  };

  const submitVerification = async () => {
    if (!verificationRequestId) return;

    try {
      setIsLoading(true);
      
      // Save references
      for (const reference of references) {
        if (reference.name.trim()) {
          await VerificationService.addReference(verificationRequestId, {
            reference_name: reference.name,
            reference_title: reference.title || null,
            reference_organization: reference.organization || null,
            reference_email: reference.email || null,
            reference_phone: reference.phone || null,
            reference_relationship: reference.relationship || null,
            is_contactable: reference.isContactable,
            verification_status: 'pending'
          });
        }
      }

      toast({
        title: "Verification Submitted",
        description: "Your verification request has been submitted successfully. Our team will review it within 2-3 business days.",
      });

      onComplete?.();
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to submit verification. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const renderDocumentUpload = (documentType: string, label: string, required: boolean = true) => {
    const file = documents[documentType];
    const isUploaded = !!file;

    return (
      <div className="space-y-2">
        <Label className="flex items-center gap-2">
          {label}
          {required && <span className="text-red-500">*</span>}
        </Label>
        
        {!isUploaded ? (
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-gray-400 transition-colors">
            <Upload className="h-8 w-8 text-gray-400 mx-auto mb-2" />
            <p className="text-sm text-gray-600 mb-2">Click to upload or drag and drop</p>
            <Input
              type="file"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) {
                  handleFileUpload(file, documentType);
                }
              }}
              accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
              className="hidden"
              id={`upload-${documentType}`}
            />
            <Button
              variant="outline"
              onClick={() => document.getElementById(`upload-${documentType}`)?.click()}
              disabled={isLoading}
            >
              Choose File
            </Button>
          </div>
        ) : (
          <div className="border border-green-200 bg-green-50 rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle className="h-5 w-5 text-green-600" />
                <span className="text-sm font-medium text-green-800">{file.name}</span>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setDocuments(prev => {
                    const newDocs = { ...prev };
                    delete newDocs[documentType];
                    return newDocs;
                  });
                }}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>
        )}
      </div>
    );
  };

  if (!currentUser) {
    return <div>Loading...</div>;
  }

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold">Verification Application</h1>
        <p className="text-gray-600">
          Complete your verification to unlock all platform features
        </p>
      </div>

      <div className="space-y-2">
        <div className="flex justify-between text-sm text-gray-600">
          <span>Step {currentStep} of {totalSteps}</span>
          <span>{Math.round(progress)}% Complete</span>
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      {currentStep === 1 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="h-5 w-5" />
              Start Verification Process
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-gray-600">
              Click the button below to create your verification request.
            </p>
            <Button 
              onClick={createVerificationRequest}
              disabled={isLoading}
              className="w-full"
            >
              {isLoading ? 'Creating...' : 'Create Verification Request'}
            </Button>
          </CardContent>
        </Card>
      )}

      {currentStep === 2 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Upload Required Documents
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {renderDocumentUpload('governmentId', 'Government ID (Aadhar, PAN, Passport)', true)}
            {renderDocumentUpload('academicCertificates', 'Academic Certificates (Degrees, Transcripts)', true)}
            {userType === 'tutor' && renderDocumentUpload('teachingCertificates', 'Teaching Certificates', true)}
            {userType === 'institute' && (
              <>
                {renderDocumentUpload('registrationCertificate', 'Registration Certificate', true)}
                {renderDocumentUpload('taxId', 'Tax ID / GST Number', true)}
                {renderDocumentUpload('locationProof', 'Location Proof', true)}
                {renderDocumentUpload('accreditationProof', 'Accreditation Proof', true)}
              </>
            )}

            <div className="flex justify-between pt-4">
              <Button variant="outline" onClick={() => setCurrentStep(1)}>
                Previous
              </Button>
              <Button onClick={() => setCurrentStep(3)}>
                Next: References
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {currentStep === 3 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Professional References
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {references.map((reference, index) => (
              <div key={index} className="border rounded-lg p-4 space-y-3">
                <div className="flex justify-between items-center">
                  <h4 className="font-medium">Reference {index + 1}</h4>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => removeReference(index)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <Input
                    placeholder="Full Name *"
                    value={reference.name}
                    onChange={(e) => updateReference(index, 'name', e.target.value)}
                  />
                  <Input
                    placeholder="Title"
                    value={reference.title}
                    onChange={(e) => updateReference(index, 'title', e.target.value)}
                  />
                  <Input
                    placeholder="Organization"
                    value={reference.organization}
                    onChange={(e) => updateReference(index, 'organization', e.target.value)}
                  />
                  <Input
                    placeholder="Email"
                    value={reference.email}
                    onChange={(e) => updateReference(index, 'email', e.target.value)}
                  />
                </div>
              </div>
            ))}

            <Button variant="outline" onClick={addReference} className="w-full">
              <Plus className="h-4 w-4 mr-2" />
              Add Reference
            </Button>

            <div className="flex justify-between pt-4">
              <Button variant="outline" onClick={() => setCurrentStep(2)}>
                Previous
              </Button>
              <Button onClick={() => setCurrentStep(4)}>
                Next: Subjects & Submit
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {currentStep === 4 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="h-5 w-5" />
              Subjects & Final Submission
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Subjects You Can Teach</Label>
              <div className="flex flex-wrap gap-2 mb-3">
                {subjects.map((subject, index) => (
                  <Badge key={index} variant="secondary" className="flex items-center gap-1">
                    {subject}
                    <button onClick={() => removeSubject(subject)}>
                      <X className="h-3 w-3" />
                    </button>
                  </Badge>
                ))}
              </div>
              <Button variant="outline" onClick={addSubject} size="sm">
                <Plus className="h-4 w-4 mr-2" />
                Add Subject
              </Button>
            </div>

            <div className="flex justify-between pt-4">
              <Button variant="outline" onClick={() => setCurrentStep(3)}>
                Previous
              </Button>
              <Button onClick={submitVerification} disabled={isLoading} className="bg-green-600 hover:bg-green-700">
                {isLoading ? 'Submitting...' : 'Submit Verification'}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
