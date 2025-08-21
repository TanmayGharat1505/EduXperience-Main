import React, { useState, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';
import { VerificationService } from '@/lib/verification-service';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Eye, CheckCircle, XCircle, Clock, FileText, Users, BookOpen, RefreshCw } from 'lucide-react';

export default function AdminVerificationReview() {
  const { toast } = useToast();
  const [verificationRequests, setVerificationRequests] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedRequest, setSelectedRequest] = useState<any>(null);
  const [showReviewModal, setShowReviewModal] = useState(false);

  useEffect(() => {
    loadVerificationRequests();
  }, []);

  const loadVerificationRequests = async () => {
    try {
      setIsLoading(true);
      const result = await VerificationService.getAllVerificationRequests();
      
      if (result.success && result.requests) {
        setVerificationRequests(result.requests);
      } else {
        throw new Error(result.error || 'Failed to load verification requests');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to load verification requests",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleViewRequest = async (request: any) => {
    try {
      const result = await VerificationService.getVerificationRequest(request.id);
      
      if (result.success && result.request) {
        setSelectedRequest(result.request);
        setShowReviewModal(true);
      } else {
        throw new Error(result.error || 'Failed to load request details');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to load request details",
        variant: "destructive",
      });
    }
  };

  const handleApprove = async () => {
    if (!selectedRequest) return;

    try {
      const result = await VerificationService.updateVerificationStatus(
        selectedRequest.id,
        'verified'
      );

      if (result.success) {
        toast({
          title: "Verification Approved",
          description: "The verification request has been approved successfully.",
        });
        
        setShowReviewModal(false);
        setSelectedRequest(null);
        loadVerificationRequests();
      } else {
        throw new Error(result.error || 'Failed to approve verification');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to approve verification",
        variant: "destructive",
      });
    }
  };

  const handleReject = async () => {
    if (!selectedRequest) return;

    const reason = prompt('Please provide a reason for rejection:');
    if (!reason) return;

    try {
      const result = await VerificationService.updateVerificationStatus(
        selectedRequest.id,
        'rejected',
        reason
      );

      if (result.success) {
        toast({
          title: "Verification Rejected",
          description: "The verification request has been rejected.",
        });
        
        setShowReviewModal(false);
        setSelectedRequest(null);
        loadVerificationRequests();
      } else {
        throw new Error(result.error || 'Failed to reject verification');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to reject verification",
        variant: "destructive",
      });
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary"><Clock className="h-3 w-3 mr-1" /> Pending</Badge>;
      case 'verified':
        return <Badge variant="default"><CheckCircle className="h-3 w-3 mr-1" /> Verified</Badge>;
      case 'rejected':
        return <Badge variant="destructive"><XCircle className="h-3 w-3 mr-1" /> Rejected</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin text-blue-600 mx-auto mb-2" />
          <p className="text-gray-600">Loading verification requests...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Verification Review</h2>
        <Button onClick={loadVerificationRequests} variant="outline" size="sm">
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      {verificationRequests.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <BookOpen className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Verification Requests</h3>
            <p className="text-gray-600">There are no pending verification requests to review.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {verificationRequests.map((request) => (
            <Card key={request.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="text-lg font-semibold">{request.user_name || 'Unknown User'}</h3>
                      {getStatusBadge(request.status)}
                    </div>
                    
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm text-gray-600">
                      <div>
                        <span className="font-medium">Type:</span>
                        <Badge variant="outline" className="ml-2 capitalize">
                          {request.user_type}
                        </Badge>
                      </div>
                      <div>
                        <span className="font-medium">Documents:</span>
                        <span className="ml-2">{request.documents_count}</span>
                      </div>
                      <div>
                        <span className="font-medium">References:</span>
                        <span className="ml-2">{request.references_count}</span>
                      </div>
                      <div>
                        <span className="font-medium">Submitted:</span>
                        <span className="ml-2">
                          {new Date(request.created_at).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-col gap-2 ml-4">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleViewRequest(request)}
                    >
                      <Eye className="h-4 w-4 mr-2" />
                      Review
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Review Modal */}
      <Dialog open={showReviewModal} onOpenChange={setShowReviewModal}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Verification Review</DialogTitle>
          </DialogHeader>
          
          {selectedRequest && (
            <div className="space-y-6">
              {/* Basic Information */}
              <Card>
                <CardHeader>
                  <CardTitle>Applicant Information</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <span className="text-sm font-medium text-gray-700">User Type:</span>
                      <p className="text-gray-900 capitalize">{selectedRequest.user_type}</p>
                    </div>
                    <div>
                      <span className="text-sm font-medium text-gray-700">Status:</span>
                      <div className="mt-1">{getStatusBadge(selectedRequest.status)}</div>
                    </div>
                    <div>
                      <span className="text-sm font-medium text-gray-700">Submitted:</span>
                      <p className="text-gray-900">
                        {new Date(selectedRequest.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Documents */}
              <Card>
                <CardHeader>
                  <CardTitle>Documents ({selectedRequest.documents?.length || 0})</CardTitle>
                </CardHeader>
                <CardContent>
                  {selectedRequest.documents && selectedRequest.documents.length > 0 ? (
                    <div className="grid gap-3">
                      {selectedRequest.documents.map((doc: any) => (
                        <div key={doc.id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <FileText className="h-5 w-5 text-gray-400" />
                            <div>
                              <p className="font-medium">{doc.document_name}</p>
                              <p className="text-sm text-gray-600 capitalize">
                                {doc.document_type.replace('_', ' ')}
                              </p>
                            </div>
                          </div>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => window.open(doc.file_url, '_blank')}
                          >
                            <Eye className="h-4 w-4 mr-2" />
                            View
                          </Button>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-center py-4">No documents uploaded</p>
                  )}
                </CardContent>
              </Card>

              {/* References */}
              <Card>
                <CardHeader>
                  <CardTitle>References ({selectedRequest.references?.length || 0})</CardTitle>
                </CardHeader>
                <CardContent>
                  {selectedRequest.references && selectedRequest.references.length > 0 ? (
                    <div className="grid gap-3">
                      {selectedRequest.references.map((ref: any) => (
                        <div key={ref.id} className="p-3 border rounded-lg">
                          <div className="flex items-center justify-between mb-2">
                            <h4 className="font-medium">{ref.reference_name}</h4>
                            <Badge variant={ref.verification_status === 'verified' ? 'default' : 'secondary'}>
                              {ref.verification_status}
                            </Badge>
                          </div>
                          <div className="grid grid-cols-2 gap-2 text-sm text-gray-600">
                            <div>
                              <span className="font-medium">Title:</span> {ref.reference_title || 'N/A'}
                            </div>
                            <div>
                              <span className="font-medium">Organization:</span> {ref.reference_organization || 'N/A'}
                            </div>
                            <div>
                              <span className="font-medium">Email:</span> {ref.reference_email || 'N/A'}
                            </div>
                            <div>
                              <span className="font-medium">Phone:</span> {ref.reference_phone || 'N/A'}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-center py-4">No references provided</p>
                  )}
                </CardContent>
              </Card>

              {/* Action Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t">
                <Button variant="outline" onClick={() => setShowReviewModal(false)}>
                  Close
                </Button>
                
                {selectedRequest.status === 'pending' && (
                  <>
                    <Button onClick={handleApprove} className="bg-green-600 hover:bg-green-700">
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Approve
                    </Button>
                    <Button variant="destructive" onClick={handleReject}>
                      <XCircle className="h-4 w-4 mr-2" />
                      Reject
                    </Button>
                  </>
                )}

                {selectedRequest.status === 'rejected' && (
                  <Button onClick={handleApprove} className="bg-green-600 hover:bg-green-700">
                    <CheckCircle className="h-4 w-4 mr-2" />
                    Approve
                  </Button>
                )}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
