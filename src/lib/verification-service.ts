import { supabase } from "@/integrations/supabase/client";
import type { Tables } from "@/integrations/supabase/types";

export type VerificationRequest = Tables<"verification_requests">;
export type VerificationDocument = Tables<"verification_documents">;
export type VerificationReference = Tables<"verification_references">;
export type SubjectProficiencyTest = Tables<"subject_proficiency_tests">;
export type TestQuestion = Tables<"test_questions">;
export type TestAttempt = Tables<"test_attempts">;

export interface VerificationFormData {
  userType: 'tutor' | 'institute';
  documents: {
    governmentId?: File;
    academicCertificates?: File[];
    teachingCertificates?: File[];
    registrationCertificate?: File;
    taxId?: File;
    locationProof?: File;
    accreditationProof?: File;
    demoVideo?: File;
  };
  references: {
    name: string;
    title?: string;
    organization?: string;
    email?: string;
    phone?: string;
    relationship?: string;
    isContactable: boolean;
  }[];
  subjects: string[];
}

export interface DocumentUploadResult {
  success: boolean;
  documentId?: string;
  error?: string;
  fileUrl?: string;
}

export class VerificationService {
  // Create a new verification request
  static async createVerificationRequest(
    userId: string,
    userType: 'tutor' | 'institute'
  ): Promise<{ success: boolean; requestId?: string; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('verification_requests')
        .insert({
          user_id: userId,
          user_type: userType,
          status: 'pending'
        })
        .select('id')
        .single();

      if (error) throw error;

      return { success: true, requestId: data.id };
    } catch (error) {
      console.error('Error creating verification request:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Upload verification documents
  static async uploadDocument(
    requestId: string,
    documentType: string,
    file: File,
    isRequired: boolean = true
  ): Promise<DocumentUploadResult> {
    try {
      // Generate unique filename
      const fileExt = file.name.split('.').pop();
      const fileName = `${requestId}_${documentType}_${Date.now()}.${fileExt}`;
      const filePath = `${requestId}/${fileName}`;

      console.log('Uploading document:', {
        requestId,
        documentType,
        fileName,
        filePath,
        fileSize: file.size,
        mimeType: file.type
      });

      // Upload to Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('verification-documents')
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        });

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('verification-documents')
        .getPublicUrl(filePath);

      // Save document metadata to database
      const { data: docData, error: docError } = await supabase
        .from('verification_documents')
        .insert({
          verification_request_id: requestId,
          document_type: documentType,
          document_name: file.name,
          file_url: urlData.publicUrl,
          file_size: file.size,
          mime_type: file.type,
          is_required: isRequired
        })
        .select('id')
        .single();

      if (docError) throw docError;

      return { 
        success: true, 
        documentId: docData.id, 
        fileUrl: urlData.publicUrl 
      };
    } catch (error) {
      console.error('Error uploading document:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Add verification references
  static async addReference(
    requestId: string,
    reference: VerificationReference['Insert']
  ): Promise<{ success: boolean; referenceId?: string; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('verification_references')
        .insert({
          verification_request_id: requestId,
          ...reference
        })
        .select('id')
        .single();

      if (error) throw error;

      return { success: true, referenceId: data.id };
    } catch (error) {
      console.error('Error adding reference:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Get verification request with all related data
  static async getVerificationRequest(
    requestId: string
  ): Promise<{
    success: boolean;
    request?: VerificationRequest & {
      documents: VerificationDocument[];
      references: VerificationReference[];
      test_attempts: TestAttempt[];
    };
    error?: string;
  }> {
    try {
      // Get main request
      const { data: request, error: requestError } = await supabase
        .from('verification_requests')
        .select('*')
        .eq('id', requestId)
        .single();

      if (requestError) throw requestError;

      // Get documents
      const { data: documents, error: docsError } = await supabase
        .from('verification_documents')
        .select('*')
        .eq('verification_request_id', requestId);

      if (docsError) throw docsError;

      // Get references
      const { data: references, error: refsError } = await supabase
        .from('verification_references')
        .select('*')
        .eq('verification_request_id', requestId);

      if (refsError) throw refsError;

      // Get test attempts
      const { data: testAttempts, error: testsError } = await supabase
        .from('test_attempts')
        .select('*')
        .eq('verification_request_id', requestId);

      if (testsError) throw testsError;

      return {
        success: true,
        request: {
          ...request,
          documents: documents || [],
          references: references || [],
          test_attempts: testAttempts || []
        }
      };
    } catch (error) {
      console.error('Error getting verification request:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Get user's verification request
  static async getUserVerificationRequest(
    userId: string
  ): Promise<{
    success: boolean;
    request?: VerificationRequest;
    error?: string;
  }> {
    try {
      const { data, error } = await supabase
        .from('verification_requests')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned

      return { success: true, request: data || undefined };
    } catch (error) {
      console.error('Error getting user verification request:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Admin: Update verification status
  static async updateVerificationStatus(
    requestId: string,
    status: 'verified' | 'rejected',
    rejectionReason?: string,
    adminUserId?: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const updateData: any = {
        status,
        updated_at: new Date().toISOString()
      };

      if (status === 'verified') {
        updateData.verified_by = adminUserId;
        updateData.verified_at = new Date().toISOString();
        updateData.last_verification_date = new Date().toISOString();
        updateData.re_verification_due_date = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(); // 1 year from now
      } else if (status === 'rejected') {
        updateData.rejection_reason = rejectionReason;
      }

      const { error } = await supabase
        .from('verification_requests')
        .update(updateData)
        .eq('id', requestId);

      if (error) throw error;

      // If verified, also update the user's profile verification status
      if (status === 'verified') {
        const { data: request } = await supabase
          .from('verification_requests')
          .select('user_id, user_type')
          .eq('id', requestId)
          .single();

        if (request) {
          if (request.user_type === 'tutor') {
            await supabase
              .from('tutor_profiles')
              .update({ verified: true })
              .eq('user_id', request.user_id);
          }
          // Add institute profile update when that table exists
        }
      }

      return { success: true };
    } catch (error) {
      console.error('Error updating verification status:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Get all verification requests for admin
  static async getAllVerificationRequests(): Promise<{
    success: boolean;
    requests?: (VerificationRequest & {
      user_email?: string;
      user_name?: string;
      documents_count: number;
      references_count: number;
    })[];
    error?: string;
  }> {
    try {
      const { data, error } = await supabase
        .from('verification_requests')
        .select(`
          *,
          profiles!verification_requests_user_id_fkey(full_name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Get additional counts for each request
      const requestsWithCounts = await Promise.all(
        data.map(async (request) => {
          const [documentsCount, referencesCount] = await Promise.all([
            this.getDocumentsCount(request.id),
            this.getReferencesCount(request.id)
          ]);

          return {
            ...request,
            user_email: request.user_id, // We'll get this from auth.users if needed
            user_name: request.profiles?.full_name || 'Unknown',
            documents_count: documentsCount,
            references_count: referencesCount
          };
        })
      );

      return { success: true, requests: requestsWithCounts };
    } catch (error) {
      console.error('Error getting all verification requests:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Helper methods
  private static async getDocumentsCount(requestId: string): Promise<number> {
    try {
      const { count, error } = await supabase
        .from('verification_documents')
        .select('*', { count: 'exact', head: true })
        .eq('verification_request_id', requestId);

      if (error) throw error;
      return count || 0;
    } catch (error) {
      return 0;
    }
  }

  private static async getReferencesCount(requestId: string): Promise<number> {
    try {
      const { count, error } = await supabase
        .from('verification_references')
        .select('*', { count: 'exact', head: true })
        .eq('verification_request_id', requestId);

      if (error) throw error;
      return count || 0;
    } catch (error) {
      return 0;
    }
  }

  // Get available proficiency tests
  static async getProficiencyTests(): Promise<{
    success: boolean;
    tests?: SubjectProficiencyTest[];
    error?: string;
  }> {
    try {
      const { data, error } = await supabase
        .from('subject_proficiency_tests')
        .select('*')
        .eq('is_active', true)
        .order('subject', { ascending: true });

      if (error) throw error;

      return { success: true, tests: data || [] };
    } catch (error) {
      console.error('Error getting proficiency tests:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Submit test attempt
  static async submitTestAttempt(
    requestId: string,
    testId: string,
    userId: string,
    answers: Record<string, any>,
    timeTaken: number
  ): Promise<{ success: boolean; attemptId?: string; error?: string }> {
    try {
      // Get test details to calculate score
      const { data: test, error: testError } = await supabase
        .from('subject_proficiency_tests')
        .select('*')
        .eq('id', testId)
        .single();

      if (testError) throw testError;

      // Calculate score (this is a simplified version - you'd want more sophisticated scoring)
      const score = this.calculateTestScore(answers, testId);
      const passed = score >= test.passing_score;

      const { data, error } = await supabase
        .from('test_attempts')
        .insert({
          verification_request_id: requestId,
          test_id: testId,
          user_id: userId,
          score,
          total_questions: test.total_questions,
          passing_score: test.passing_score,
          passed,
          time_taken_minutes: timeTaken,
          answers,
          completed_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (error) throw error;

      return { success: true, attemptId: data.id };
    } catch (error) {
      console.error('Error submitting test attempt:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Simplified test scoring (you'd want to implement proper scoring logic)
  private static calculateTestScore(answers: Record<string, any>, testId: string): number {
    // This is a placeholder - implement actual scoring logic based on your test structure
    return Math.floor(Math.random() * 20) + 10; // Random score between 10-30 for demo
  }

  // Admin: Review test attempt
  static async reviewTestAttempt(
    attemptId: string,
    adminNotes: string,
    adminUserId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('test_attempts')
        .update({
          admin_review_notes: adminNotes,
          admin_reviewed_by: adminUserId,
          admin_reviewed_at: new Date().toISOString()
        })
        .eq('id', attemptId);

      if (error) throw error;

      return { success: true };
    } catch (error) {
      console.error('Error reviewing test attempt:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Trigger re-verification
  static async triggerReVerification(
    requestId: string,
    adminUserId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('verification_requests')
        .update({
          status: 'pending',
          rejection_reason: null,
          verified_by: null,
          verified_at: null,
          updated_at: new Date().toISOString()
        })
        .eq('id', requestId);

      if (error) throw error;

      return { success: true };
    } catch (error) {
      console.error('Error triggering re-verification:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }
}
