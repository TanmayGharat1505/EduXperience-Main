-- Create a function to insert tutor profiles that bypasses RLS
CREATE OR REPLACE FUNCTION create_tutor_profile(
  p_user_id UUID,
  p_full_name TEXT,
  p_city TEXT,
  p_area TEXT,
  p_bio TEXT,
  p_experience_years INTEGER,
  p_hourly_rate_min INTEGER,
  p_hourly_rate_max INTEGER,
  p_teaching_mode TEXT,
  p_qualifications JSONB,
  p_availability JSONB
) RETURNS VOID AS $$
BEGIN
  -- Insert into profiles table
  INSERT INTO profiles (user_id, full_name, city, area, role)
  VALUES (p_user_id, p_full_name, p_city, p_area, 'tutor')
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Insert into tutor_profiles table
  INSERT INTO tutor_profiles (
    user_id, 
    bio, 
    experience_years, 
    hourly_rate_min, 
    hourly_rate_max, 
    teaching_mode, 
    qualifications, 
    availability, 
    verified
  )
  VALUES (
    p_user_id, 
    p_bio, 
    p_experience_years, 
    p_hourly_rate_min, 
    p_hourly_rate_max, 
    p_teaching_mode, 
    p_qualifications, 
    p_availability, 
    false
  )
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_tutor_profile TO authenticated; 