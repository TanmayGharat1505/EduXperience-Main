export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instanciate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  public: {
    Tables: {
      institution_profiles: {
        Row: {
          address: string | null
          contact_phone: string | null
          created_at: string
          description: string | null
          established_year: number | null
          id: string
          institution_name: string
          institution_type: string | null
          rating: number | null
          total_reviews: number | null
          updated_at: string
          user_id: string
          verified: boolean | null
          website_url: string | null
        }
        Insert: {
          address?: string | null
          contact_phone?: string | null
          created_at?: string
          description?: string | null
          established_year?: number | null
          id?: string
          institution_name: string
          institution_type?: string | null
          rating?: number | null
          total_reviews?: number | null
          updated_at?: string
          user_id: string
          verified?: boolean | null
          website_url?: string | null
        }
        Update: {
          address?: string | null
          contact_phone?: string | null
          created_at?: string
          description?: string | null
          established_year?: number | null
          id?: string
          institution_name?: string
          institution_type?: string | null
          rating?: number | null
          total_reviews?: number | null
          updated_at?: string
          user_id?: string
          verified?: boolean | null
          website_url?: string | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          area: string | null
          city: string | null
          created_at: string
          full_name: string
          id: string
          primary_language: string | null
          profile_photo_url: string | null
          role: Database["public"]["Enums"]["app_role"]
          updated_at: string
          user_id: string
        }
        Insert: {
          area?: string | null
          city?: string | null
          created_at?: string
          full_name: string
          id?: string
          primary_language?: string | null
          profile_photo_url?: string | null
          role?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
          user_id: string
        }
        Update: {
          area?: string | null
          city?: string | null
          created_at?: string
          full_name?: string
          id?: string
          primary_language?: string | null
          profile_photo_url?: string | null
          role?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      student_learning_goals: {
        Row: {
          created_at: string
          id: string
          learning_objective: string | null
          proficiency_level: string | null
          student_id: string
          subject_id: string
          timeline: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          learning_objective?: string | null
          proficiency_level?: string | null
          student_id: string
          subject_id: string
          timeline?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          learning_objective?: string | null
          proficiency_level?: string | null
          student_id?: string
          subject_id?: string
          timeline?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "student_learning_goals_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "student_profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "student_learning_goals_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      student_profiles: {
        Row: {
          age: number | null
          budget_max: number | null
          budget_min: number | null
          class_duration: number | null
          class_type_preference: string | null
          created_at: string
          date_of_birth: string | null
          education_level: string | null
          frequency: string | null
          id: string
          instruction_language: string | null
          learning_mode: string | null
          offline_radius: number | null
          onboarding_completed: boolean | null
          profile_completion_percentage: number | null
          schedule_preferences: Json | null
          special_requirements: string | null
          teaching_methodology: string | null
          tutor_gender_preference: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          age?: number | null
          budget_max?: number | null
          budget_min?: number | null
          class_duration?: number | null
          class_type_preference?: string | null
          created_at?: string
          date_of_birth?: string | null
          education_level?: string | null
          frequency?: string | null
          id?: string
          instruction_language?: string | null
          learning_mode?: string | null
          offline_radius?: number | null
          onboarding_completed?: boolean | null
          profile_completion_percentage?: number | null
          schedule_preferences?: Json | null
          special_requirements?: string | null
          teaching_methodology?: string | null
          tutor_gender_preference?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          age?: number | null
          budget_max?: number | null
          budget_min?: number | null
          class_duration?: number | null
          class_type_preference?: string | null
          created_at?: string
          date_of_birth?: string | null
          education_level?: string | null
          frequency?: string | null
          id?: string
          instruction_language?: string | null
          learning_mode?: string | null
          offline_radius?: number | null
          onboarding_completed?: boolean | null
          profile_completion_percentage?: number | null
          schedule_preferences?: Json | null
          special_requirements?: string | null
          teaching_methodology?: string | null
          tutor_gender_preference?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          }
        ]
      }
      subject_categories: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      subjects: {
        Row: {
          category_id: string
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          category_id: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          category_id?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "subjects_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "subject_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          id: string
          user_id: string
          title: string
          message: string
          type: string
          read: boolean
          data: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          message: string
          type?: string
          read?: boolean
          data?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          message?: string
          type?: string
          read?: boolean
          data?: Json | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "auth.users"
            referencedColumns: ["id"]
          }
        ]
      }
      reviews: {
        Row: {
          id: string
          tutor_id: string
          student_id: string
          rating: number
          review_text: string | null
          subject_taught: string | null
          class_type: string | null
          class_date: string | null
          anonymous: boolean
          verified_student: boolean
          helpful_votes: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tutor_id: string
          student_id: string
          rating: number
          review_text?: string | null
          subject_taught?: string | null
          class_type?: string | null
          class_date?: string | null
          anonymous?: boolean
          verified_student?: boolean
          helpful_votes?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tutor_id?: string
          student_id?: string
          rating?: number
          review_text?: string | null
          subject_taught?: string | null
          class_type?: string | null
          class_date?: string | null
          anonymous?: boolean
          verified_student?: boolean
          helpful_votes?: number
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reviews_tutor_id_fkey"
            columns: ["tutor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tutor_content: {
        Row: {
          id: string
          tutor_id: string
          content_type: string
          title: string
          description: string | null
          file_url: string | null
          thumbnail_url: string | null
          duration: string | null
          file_size: string | null
          views: number
          downloads: number
          is_public: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tutor_id: string
          content_type: string
          title: string
          description?: string | null
          file_url?: string | null
          thumbnail_url?: string | null
          duration?: string | null
          file_size?: string | null
          views?: number
          downloads?: number
          is_public?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tutor_id?: string
          content_type?: string
          title?: string
          description?: string | null
          file_url?: string | null
          thumbnail_url?: string | null
          duration?: string | null
          file_size?: string | null
          views?: number
          downloads?: number
          is_public?: boolean
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutor_content_tutor_id_fkey"
            columns: ["tutor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tutor_certificates: {
        Row: {
          id: string
          tutor_id: string
          title: string
          description: string | null
          certificate_type: string
          issuing_organization: string | null
          issue_date: string | null
          expiry_date: string | null
          certificate_url: string | null
          verification_status: string
          verified_by: string | null
          verified_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tutor_id: string
          title: string
          description?: string | null
          certificate_type: string
          issuing_organization?: string | null
          issue_date?: string | null
          expiry_date?: string | null
          certificate_url?: string | null
          verification_status?: string
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tutor_id?: string
          title?: string
          description?: string | null
          certificate_type?: string
          issuing_organization?: string | null
          issue_date?: string | null
          expiry_date?: string | null
          certificate_url?: string | null
          verification_status?: string
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutor_certificates_tutor_id_fkey"
            columns: ["tutor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutor_certificates_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tutor_verifications: {
        Row: {
          id: string
          tutor_id: string
          verification_type: string
          status: string
          verified_by: string | null
          verified_at: string | null
          verification_notes: string | null
          document_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tutor_id: string
          verification_type: string
          status?: string
          verified_by?: string | null
          verified_at?: string | null
          verification_notes?: string | null
          document_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tutor_id?: string
          verification_type?: string
          status?: string
          verified_by?: string | null
          verified_at?: string | null
          verification_notes?: string | null
          document_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutor_verifications_tutor_id_fkey"
            columns: ["tutor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutor_verifications_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tutor_achievements: {
        Row: {
          id: string
          tutor_id: string
          title: string
          description: string | null
          achievement_type: string
          year: number | null
          organization: string | null
          achievement_url: string | null
          is_verified: boolean
          verified_by: string | null
          verified_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tutor_id: string
          title: string
          description?: string | null
          achievement_type: string
          year?: number | null
          organization?: string | null
          achievement_url?: string | null
          is_verified?: boolean
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tutor_id?: string
          title?: string
          description?: string | null
          achievement_type?: string
          year?: number | null
          organization?: string | null
          achievement_url?: string | null
          is_verified?: boolean
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutor_achievements_tutor_id_fkey"
            columns: ["tutor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutor_achievements_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      tutor_profiles: {
        Row: {
          availability: Json | null
          bio: string | null
          created_at: string
          experience_years: number | null
          hourly_rate_max: number | null
          hourly_rate_min: number | null
          id: string
          profile_completion_percentage: number | null
          qualifications: Json | null
          rating: number | null
          response_time_hours: number | null
          teaching_mode: string | null
          total_reviews: number | null
          updated_at: string
          user_id: string
          verified: boolean | null
        }
        Insert: {
          availability?: Json | null
          bio?: string | null
          created_at?: string
          experience_years?: number | null
          hourly_rate_max?: number | null
          hourly_rate_min?: number | null
          id?: string
          profile_completion_percentage?: number | null
          qualifications?: Json | null
          rating?: number | null
          response_time_hours?: number | null
          teaching_mode?: string | null
          total_reviews?: number | null
          updated_at?: string
          user_id: string
          verified?: boolean | null
        }
        Update: {
          availability?: Json | null
          bio?: string | null
          created_at?: string
          experience_years?: number | null
          hourly_rate_max?: number | null
          hourly_rate_min?: number | null
          id?: string
          profile_completion_percentage?: number | null
          qualifications?: Json | null
          rating?: number | null
          response_time_hours?: number | null
          teaching_mode?: string | null
          total_reviews?: number | null
          updated_at?: string
          user_id?: string
          verified?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "tutor_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          }
        ]
      }
      verification_requests: {
        Row: {
          id: string
          user_id: string
          user_type: string
          status: string
          rejection_reason: string | null
          verified_by: string | null
          verified_at: string | null
          created_at: string
          updated_at: string
          re_verification_due_date: string | null
          last_verification_date: string | null
        }
        Insert: {
          id?: string
          user_id: string
          user_type: string
          status?: string
          rejection_reason?: string | null
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
          re_verification_due_date?: string | null
          last_verification_date?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          user_type?: string
          status?: string
          rejection_reason?: string | null
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
          re_verification_due_date?: string | null
          last_verification_date?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verification_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      verification_documents: {
        Row: {
          id: string
          verification_request_id: string
          document_type: string
          document_name: string
          file_url: string
          file_size: number | null
          mime_type: string | null
          is_required: boolean
          is_verified: boolean
          verification_notes: string | null
          uploaded_at: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          id?: string
          verification_request_id: string
          document_type: string
          document_name: string
          file_url: string
          file_size?: number | null
          mime_type?: string | null
          is_required?: boolean
          is_verified?: boolean
          verification_notes?: string | null
          uploaded_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          id?: string
          verification_request_id?: string
          document_type?: string
          document_name?: string
          file_url?: string
          file_size?: number | null
          mime_type?: string | null
          is_required?: boolean
          is_verified?: boolean
          verification_notes?: string | null
          uploaded_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verification_documents_verification_request_id_fkey"
            columns: ["verification_request_id"]
            isOneToOne: false
            referencedRelation: "verification_requests"
            referencedColumns: ["id"]
          }
        ]
      }
      verification_references: {
        Row: {
          id: string
          verification_request_id: string
          reference_name: string
          reference_title: string | null
          reference_organization: string | null
          reference_email: string | null
          reference_phone: string | null
          reference_relationship: string | null
          is_contactable: boolean
          verification_status: string
          verification_notes: string | null
          created_at: string
        }
        Insert: {
          id?: string
          verification_request_id: string
          reference_name: string
          reference_title?: string | null
          reference_organization?: string | null
          reference_email?: string | null
          reference_phone?: string | null
          reference_relationship?: string | null
          is_contactable?: boolean
          verification_status?: string
          verification_notes?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          verification_request_id?: string
          reference_name?: string
          reference_title?: string | null
          reference_organization?: string | null
          reference_email?: string | null
          reference_phone?: string | null
          reference_relationship?: string | null
          is_contactable?: boolean
          verification_status?: string
          verification_notes?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "verification_references_verification_request_id_fkey"
            columns: ["verification_request_id"]
            isOneToOne: false
            referencedRelation: "verification_requests"
            referencedColumns: ["id"]
          }
        ]
      }
      subject_proficiency_tests: {
        Row: {
          id: string
          subject: string
          test_name: string
          description: string | null
          total_questions: number
          passing_score: number
          time_limit_minutes: number | null
          is_active: boolean
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          subject: string
          test_name: string
          description?: string | null
          total_questions: number
          passing_score: number
          time_limit_minutes?: number | null
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          subject?: string
          test_name?: string
          description?: string | null
          total_questions?: number
          passing_score?: number
          time_limit_minutes?: number | null
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      test_questions: {
        Row: {
          id: string
          test_id: string
          question_text: string
          question_type: string
          options: Json | null
          correct_answer: string
          points: number
          order_index: number
          created_at: string
        }
        Insert: {
          id?: string
          test_id: string
          question_text: string
          question_type: string
          options?: Json | null
          correct_answer: string
          points?: number
          order_index?: number
          created_at?: string
        }
        Update: {
          id?: string
          test_id?: string
          question_text?: string
          question_type?: string
          options?: Json | null
          correct_answer?: string
          points?: number
          order_index?: number
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "test_questions_test_id_fkey"
            columns: ["test_id"]
            isOneToOne: false
            referencedRelation: "subject_proficiency_tests"
            referencedColumns: ["id"]
          }
        ]
      }
      test_attempts: {
        Row: {
          id: string
          verification_request_id: string
          test_id: string
          user_id: string
          score: number
          total_questions: number
          passing_score: number
          passed: boolean
          time_taken_minutes: number | null
          started_at: string
          completed_at: string | null
          answers: Json | null
          admin_review_notes: string | null
          admin_reviewed_by: string | null
          admin_reviewed_at: string | null
        }
        Insert: {
          id?: string
          verification_request_id: string
          test_id: string
          user_id: string
          score: number
          total_questions: number
          passing_score: number
          passed: boolean
          time_taken_minutes?: number | null
          started_at?: string
          completed_at?: string | null
          answers?: Json | null
          admin_review_notes?: string | null
          admin_reviewed_by?: string | null
          admin_reviewed_at?: string | null
        }
        Update: {
          id?: string
          verification_request_id?: string
          test_id?: string
          user_id?: string
          score?: number
          total_questions?: number
          passing_score?: number
          passed?: boolean
          time_taken_minutes?: number | null
          started_at?: string
          completed_at?: string | null
          answers?: Json | null
          admin_review_notes?: string | null
          admin_reviewed_by?: string | null
          admin_reviewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "test_attempts_verification_request_id_fkey"
            columns: ["verification_request_id"]
            isOneToOne: false
            referencedRelation: "verification_requests"
            referencedColumns: ["id"]
          }
        ]
      }
      verification_workflow_logs: {
        Row: {
          id: string
          verification_request_id: string
          action: string
          previous_status: string | null
          new_status: string | null
          action_by: string | null
          action_notes: string | null
          created_at: string
        }
        Insert: {
          id?: string
          verification_request_id: string
          action: string
          previous_status?: string | null
          new_status?: string | null
          action_by?: string | null
          action_notes?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          verification_request_id?: string
          action?: string
          previous_status?: string | null
          new_status?: string | null
          action_by?: string | null
          action_notes?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "verification_workflow_logs_verification_request_id_fkey"
            columns: ["verification_request_id"]
            isOneToOne: false
            referencedRelation: "verification_requests"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      app_role: "student" | "tutor" | "institution" | "admin"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["student", "tutor", "institution", "admin"],
    },
  },
} as const
