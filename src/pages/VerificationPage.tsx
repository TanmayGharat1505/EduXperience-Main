import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { ArrowLeft, Shield } from 'lucide-react';
import VerificationForm from '@/components/verification/VerificationForm';

interface VerificationPageProps {
  userType?: 'tutor' | 'institute';
}

export default function VerificationPage({ userType = 'tutor' }: VerificationPageProps) {
  const navigate = useNavigate();

  const handleComplete = () => {
    // Show success message and redirect to dashboard
    navigate('/tutor-dashboard');
  };

  return (
    <div className="min-h-screen bg-gradient-subtle">
      {/* Header */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => navigate('/tutor-dashboard')}
                className="flex items-center gap-2"
              >
                <ArrowLeft className="h-4 w-4" />
                Back to Dashboard
              </Button>
            </div>
            
            <div className="flex items-center gap-2">
              <Shield className="h-6 w-6 text-blue-600" />
              <h1 className="text-xl font-semibold text-gray-900">
                {userType === 'tutor' ? 'Tutor' : 'Institute'} Verification
              </h1>
            </div>
            
            <div className="w-24"></div> {/* Spacer for centering */}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <VerificationForm 
          userType={userType} 
          onComplete={handleComplete} 
        />
      </div>
    </div>
  );
}
