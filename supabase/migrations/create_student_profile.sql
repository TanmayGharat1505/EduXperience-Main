-- Create a function to insert student profiles that bypasses RLS
CREATE OR REPLACE FUNCTION create_student_profile(
  p_user_id UUID,
  p_full_name TEXT,
  p_city TEXT,
  p_area TEXT,
  p_primary_language TEXT,
  p_date_of_birth DATE,
  p_education_level TEXT,
  p_instruction_language TEXT
) RETURNS VOID AS $$
BEGIN
  -- Insert into profiles table
  INSERT INTO profiles (user_id, full_name, city, area, role, primary_language)
  VALUES (p_user_id, p_full_name, p_city, p_area, 'student', p_primary_language)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Insert into student_profiles table
  INSERT INTO student_profiles (
    user_id, 
    date_of_birth, 
    education_level, 
    instruction_language, 
    onboarding_completed, 
    profile_completion_percentage
  )
  VALUES (
    p_user_id, 
    p_date_of_birth, 
    p_education_level, 
    p_instruction_language, 
    false, 
    0
  )
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_student_profile TO authenticated; 