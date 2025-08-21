import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { supabase } from "@/integrations/supabase/client";

export default function DatabaseTest() {
  const [results, setResults] = useState<any>({});
  const [loading, setLoading] = useState(false);

  const testDatabase = async () => {
    setLoading(true);
    const testResults: any = {};

    try {
      // Test 1: Check if we can connect to the database
      console.log("Testing database connection...");
      const { data: connectionTest, error: connectionError } = await supabase
        .from("tutor_profiles")
        .select("count")
        .limit(1);
      
      testResults.connection = {
        success: !connectionError,
        data: connectionTest,
        error: connectionError
      };

      // Test 2: Check tutor_profiles table
      console.log("Testing tutor_profiles table...");
      const { data: tutorProfiles, error: tutorProfilesError } = await supabase
        .from("tutor_profiles")
        .select("*")
        .limit(5);
      
      testResults.tutorProfiles = {
        success: !tutorProfilesError,
        count: tutorProfiles?.length || 0,
        data: tutorProfiles,
        error: tutorProfilesError
      };

      // Test 3: Check profiles table
      console.log("Testing profiles table...");
      const { data: profiles, error: profilesError } = await supabase
        .from("profiles")
        .select("*")
        .limit(5);
      
      testResults.profiles = {
        success: !profilesError,
        count: profiles?.length || 0,
        data: profiles,
        error: profilesError
      };

      // Test 4: Check if there are any tutor profiles with role='tutor'
      console.log("Testing profiles with tutor role...");
      const { data: tutorProfilesWithRole, error: tutorRoleError } = await supabase
        .from("profiles")
        .select("*")
        .eq("role", "tutor")
        .limit(5);
      
      testResults.tutorProfilesWithRole = {
        success: !tutorRoleError,
        count: tutorProfilesWithRole?.length || 0,
        data: tutorProfilesWithRole,
        error: tutorRoleError
      };

      // Test 5: Try to join tutor_profiles with profiles
      console.log("Testing join between tutor_profiles and profiles...");
      try {
        const { data: joinedData, error: joinError } = await supabase
          .from("tutor_profiles")
          .select(`
            *,
            profiles!inner(*)
          `)
          .limit(5);
        
        testResults.joinTest = {
          success: !joinError,
          count: joinedData?.length || 0,
          data: joinedData,
          error: joinError
        };
      } catch (joinError) {
        console.log("Join test failed, trying alternative approach:", joinError);
        
        // Alternative approach: Load data separately and combine
        const { data: tutorData, error: tutorError } = await supabase
          .from("tutor_profiles")
          .select("*")
          .limit(5);
        
        const { data: profileData, error: profileError } = await supabase
          .from("profiles")
          .select("*")
          .eq("role", "tutor")
          .limit(5);
        
        if (!tutorError && !profileError) {
          // Create a map of user_id to profile data
          const profilesMap = new Map(profileData?.map(profile => [profile.user_id, profile]) || []);
          
          // Combine the data
          const combinedData = tutorData?.map(tutor => ({
            ...tutor,
            profile: profilesMap.get(tutor.user_id) || null
          })) || [];
          
          testResults.joinTest = {
            success: true,
            count: combinedData.length,
            data: combinedData,
            error: null
          };
        } else {
          testResults.joinTest = {
            success: false,
            count: 0,
            data: null,
            error: { message: "Could not load data separately", tutorError, profileError }
          };
        }
      }

    } catch (error) {
      console.error("Database test error:", error);
      testResults.generalError = error;
    }

    setResults(testResults);
    setLoading(false);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <Card>
        <CardHeader>
          <CardTitle>Database Test</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button onClick={testDatabase} disabled={loading}>
            {loading ? "Testing..." : "Run Database Tests"}
          </Button>
          
          {Object.keys(results).length > 0 && (
            <div className="space-y-4">
              <h3 className="font-semibold">Test Results:</h3>
              
              {Object.entries(results).map(([testName, result]: [string, any]) => (
                <Card key={testName} className="bg-muted">
                  <CardContent className="p-4">
                    <h4 className="font-semibold mb-2">{testName}</h4>
                    <div className="space-y-2 text-sm">
                      <p><strong>Success:</strong> {result.success ? "✅ Yes" : "❌ No"}</p>
                      {result.count !== undefined && (
                        <p><strong>Count:</strong> {result.count}</p>
                      )}
                      {result.error && (
                        <div>
                          <p><strong>Error:</strong></p>
                          <pre className="bg-red-100 p-2 rounded text-xs overflow-auto">
                            {JSON.stringify(result.error, null, 2)}
                          </pre>
                        </div>
                      )}
                      {result.data && result.data.length > 0 && (
                        <div>
                          <p><strong>Sample Data:</strong></p>
                          <pre className="bg-green-100 p-2 rounded text-xs overflow-auto">
                            {JSON.stringify(result.data[0], null, 2)}
                          </pre>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
} 