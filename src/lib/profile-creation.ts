import { supabase } from "@/integrations/supabase/client";

export async function createTutorProfileAfterVerification(userId: string, formData: any) {
  try {
    console.log('Creating tutor profile after email verification...');
    console.log('User ID:', userId);
    console.log('Form data keys:', Object.keys(formData));

    // First, try to create the basic profile
    console.log('Attempting to create basic profile...');
    const { error: profileError } = await supabase
      .from('profiles')
      .insert({
        user_id: userId,
        full_name: formData.fullName || 'Tutor',
        city: formData.city || 'Unknown',
        area: formData.area || 'Unknown',
        role: 'tutor',
      });

    if (profileError) {
      console.error('Profile creation error:', profileError);
    } else {
      console.log('Basic profile created successfully');
    }

    // Then, try to create the tutor profile
    console.log('Attempting to create tutor profile...');
    const { error: tutorProfileError } = await supabase
      .from('tutor_profiles')
      .insert({
        user_id: userId,
        bio: formData.teachingMethodology || formData.profileHeadline || 'Experienced tutor',
        experience_years: parseInt(formData.teachingExperience?.split('-')[0]) || 0,
        hourly_rate_min: parseInt(formData.individualFee) || 0,
        hourly_rate_max: parseInt(formData.groupFee) || 0,
        teaching_mode: formData.classType || 'online',
        qualifications: {
          highest_qualification: formData.highestQualification,
          university: formData.universityName,
          year_of_passing: formData.yearOfPassing,
          percentage: formData.percentage,
          subjects: formData.subjects || [],
          student_levels: formData.studentLevels || [],
          curriculum: formData.curriculum || [],
        },
        availability: {
          available_days: formData.availableDays || [],
          time_slots: formData.timeSlots || {},
          max_travel_distance: formData.maxTravelDistance || 10,
        },
        verified: false,
      });

    if (tutorProfileError) {
      console.error('Tutor profile creation error:', tutorProfileError);
      return { 
        success: false, 
        error: `Tutor profile creation failed: ${tutorProfileError.message}` 
      };
    } else {
      console.log('Tutor profile created successfully');
    }

    // Upload profile photo if provided
    if (formData.profilePhoto) {
      try {
        const fileExt = formData.profilePhoto.name.split('.').pop();
        const fileName = `${userId}-profile.${fileExt}`;
        
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
            .eq('user_id', userId);
        }
      } catch (uploadError) {
        console.warn('Profile photo upload failed after verification:', uploadError);
      }
    }

    return { 
      success: true, 
      message: 'Tutor profile created successfully' 
    };
  } catch (error) {
    console.error('Profile creation after verification failed:', error);
    return { success: false, error };
  }
}

export function getPendingTutorProfile() {
  const pending = localStorage.getItem('pendingTutorProfile');
  if (pending) {
    try {
      const data = JSON.parse(pending);
      // Check if data is not too old (24 hours)
      if (Date.now() - data.timestamp < 24 * 60 * 60 * 1000) {
        return data;
      } else {
        localStorage.removeItem('pendingTutorProfile');
      }
    } catch (error) {
      console.error('Error parsing pending tutor profile:', error);
      localStorage.removeItem('pendingTutorProfile');
    }
  }
  return null;
}

export function clearPendingTutorProfile() {
  localStorage.removeItem('pendingTutorProfile');
}

export async function createStudentProfileAfterVerification(userId: string, formData: any) {
  try {
    console.log('Creating student profile after email verification...');
    console.log('User ID:', userId);
    console.log('Form data keys:', Object.keys(formData));

    // First, try to create the basic profile
    console.log('Attempting to create basic profile...');
    const { error: profileError } = await supabase
      .from('profiles')
      .insert({
        user_id: userId,
        full_name: formData.fullName || 'Student',
        city: formData.city || 'Unknown',
        area: formData.area || 'Unknown',
        role: 'student',
        primary_language: formData.primaryLanguage || 'English',
      });

    if (profileError) {
      console.error('Profile creation error:', profileError);
    } else {
      console.log('Basic profile created successfully');
    }

    // Then, try to create the student profile
    console.log('Attempting to create student profile...');
    const { error: studentProfileError } = await supabase
      .from('student_profiles')
      .insert({
        user_id: userId,
        date_of_birth: formData.dateOfBirth,
        education_level: formData.educationLevel || 'High School',
        instruction_language: formData.primaryLanguage || 'English',
        onboarding_completed: false,
        profile_completion_percentage: 0,
      });

    if (studentProfileError) {
      console.error('Student profile creation error:', studentProfileError);
      return { 
        success: false, 
        error: `Student profile creation failed: ${studentProfileError.message}` 
      };
    } else {
      console.log('Student profile created successfully');
    }

    // Upload profile photo if provided
    if (formData.profilePhoto) {
      try {
        const fileExt = formData.profilePhoto.name.split('.').pop();
        const fileName = `${userId}-profile.${fileExt}`;
        
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
            .eq('user_id', userId);
        }
      } catch (uploadError) {
        console.warn('Profile photo upload failed after verification:', uploadError);
      }
    }

    return { 
      success: true, 
      message: 'Student profile created successfully' 
    };
  } catch (error) {
    console.error('Profile creation after verification failed:', error);
    return { success: false, error };
  }
}

export function getPendingStudentProfile() {
  const pending = localStorage.getItem('pendingStudentProfile');
  if (pending) {
    try {
      const data = JSON.parse(pending);
      // Check if data is not too old (24 hours)
      if (Date.now() - data.timestamp < 24 * 60 * 60 * 1000) {
        return data;
      } else {
        localStorage.removeItem('pendingStudentProfile');
      }
    } catch (error) {
      console.error('Error parsing pending student profile:', error);
      localStorage.removeItem('pendingStudentProfile');
    }
  }
  return null;
}

export function clearPendingStudentProfile() {
  localStorage.removeItem('pendingStudentProfile');
} 