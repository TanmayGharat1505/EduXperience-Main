import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { VerificationService } from '@/lib/verification-service';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { 
  Shield, 
  CheckCircle, 
  XCircle, 
  Clock, 
  AlertTriangle,
  FileText,
  Users,
  BookOpen,
  ArrowRight
} from 'lucide-react';

interface VerificationStatusProps {
  userType: 'tutor' | 'institute';
  onStartVerification?: () => void;
}

export default function VerificationStatus({ userType, onStartVerification }: VerificationStatusProps) {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [verificationRequest, setVerificationRequest] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkVerificationStatus();
  }, []);

  const checkVerificationStatus = async () => {
    try {
      setIsLoading(true);
      const { data: { user } } = await import('@/integrations/supabase/client').then(m => m.supabase.auth.getUser());
      
      if (!user) {
        navigate('/login');
        return;
      }

      const result = await VerificationService.getUserVerificationRequest(user.id);
      
      if (result.success) {
        setVerificationRequest(result.request);
      }
    } catch (error) {
      console.error('Error checking verification status:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary" className="flex items-center gap-1"><Clock className="h-3 w-3" /> Pending Review</Badge>;
      case 'verified':
        return <Badge variant="default" className="flex items-center gap-1"><CheckCircle className="h-3 w-3" /> Verified</Badge>;
      case 'rejected':
        return <Badge variant="destructive" className="flex items-center gap-1"><XCircle className="h-3 w-3" /> Rejected</Badge>;
      default:
        return <Badge variant="outline">Not Started</Badge>;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'text-yellow-600';
      case 'verified': return 'text-green-600';
      case 'rejected': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return <Clock className="h-8 w-8 text-yellow-600" />;
      case 'verified': return <CheckCircle className="h-8 w-8 text-green-600" />;
      case 'rejected': return <XCircle className="h-8 w-8 text-red-600" />;
      default: return <Shield className="h-8 w-8 text-gray-600" />;
    }
  };

  const getStatusMessage = (status: string) => {
    switch (status) {
      case 'pending':
        return "Your verification request is currently under review. Our team will examine your documents and references within 2-3 business days.";
      case 'verified':
        return "Congratulations! Your account has been verified. You now have access to all platform features and can start accepting students.";
      case 'rejected':
        return "Your verification request was not approved. Please review the feedback and submit a new application with updated documents.";
      default:
        return `Complete your ${userType} verification to unlock all platform features and start accepting students.`;
    }
  };

  const getNextSteps = (status: string) => {
    switch (status) {
      case 'pending':
        return [
          "Wait for admin review (2-3 business days)",
          "Check your email for updates",
          "Ensure all documents are properly uploaded"
        ];
      case 'verified':
        return [
          "Start creating your profile",
          "Set your availability and rates",
          "Begin accepting student requests"
        ];
      case 'rejected':
        return [
          "Review rejection feedback",
          "Update required documents",
          "Submit new verification request"
        ];
      default:
        return [
          "Upload government ID and academic certificates",
          "Add professional references",
          "Complete subject proficiency tests (optional)"
        ];
    }
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="animate-pulse space-y-4">
            <div className="h-4 bg-gray-200 rounded w-1/4"></div>
            <div className="h-4 bg-gray-200 rounded w-3/4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="shadow-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Shield className="h-5 w-5" />
          Verification Status
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Status Overview */}
        <div className="text-center space-y-4">
          {getStatusIcon(verificationRequest?.status)}
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              {verificationRequest?.status ? 
                `${userType.charAt(0).toUpperCase() + userType.slice(1)} Verification` : 
                'Verification Required'
              }
            </h3>
            <div className="mt-2">
              {getStatusBadge(verificationRequest?.status)}
            </div>
          </div>
          <p className="text-gray-600 max-w-md mx-auto">
            {getStatusMessage(verificationRequest?.status)}
          </p>
        </div>

        {/* Progress Bar for Pending */}
        {verificationRequest?.status === 'pending' && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm text-gray-600">
              <span>Verification Progress</span>
              <span>Under Review</span>
            </div>
            <Progress value={75} className="h-2" />
            <p className="text-xs text-gray-500 text-center">
              Estimated completion: 2-3 business days
            </p>
          </div>
        )}

        {/* Next Steps */}
        <div className="space-y-3">
          <h4 className="font-medium text-gray-900">Next Steps</h4>
          <div className="space-y-2">
            {getNextSteps(verificationRequest?.status).map((step, index) => (
              <div key={index} className="flex items-center gap-2 text-sm text-gray-600">
                <ArrowRight className="h-4 w-4 text-blue-500" />
                <span>{step}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-center gap-3 pt-4">
          {!verificationRequest && (
            <Button 
              onClick={onStartVerification}
              className="bg-blue-600 hover:bg-blue-700"
            >
              <FileText className="h-4 w-4 mr-2" />
              Start Verification
            </Button>
          )}

          {verificationRequest?.status === 'rejected' && (
            <Button 
              onClick={onStartVerification}
              variant="outline"
            >
              <BookOpen className="h-4 w-4 mr-2" />
              Submit New Application
            </Button>
          )}

          {verificationRequest?.status === 'verified' && (
            <Button 
              onClick={() => navigate('/dashboard')}
              className="bg-green-600 hover:bg-green-700"
            >
              <Users className="h-4 w-4 mr-2" />
              Start Teaching
            </Button>
          )}
        </div>

        {/* Additional Info */}
        {verificationRequest?.status === 'pending' && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-blue-600 mt-0.5" />
              <div>
                <h4 className="font-medium text-blue-900">Verification in Progress</h4>
                <p className="text-sm text-blue-700 mt-1">
                  While your verification is pending, you can still complete your profile and prepare your teaching materials. 
                  Once verified, you'll be able to accept students immediately.
                </p>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
