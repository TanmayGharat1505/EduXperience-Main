import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { supabase } from "@/integrations/supabase/client";
import { createTutorProfileAfterVerification } from "@/lib/profile-creation";
import { useToast } from "@/hooks/use-toast";

export default function TestProfileCreation() {
  const [isLoading, setIsLoading] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);
  const { toast } = useToast();

  const addLog = (message: string) => {
    setLogs(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  const testProfileCreation = async () => {
    setIsLoading(true);
    setLogs([]);
    
    try {
      addLog("Starting profile creation test...");
      
      // Get current user
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      
      if (userError || !user) {
        addLog(`Error getting user: ${userError?.message || 'No user found'}`);
        toast({
          title: "Error",
          description: "Please log in first",
          variant: "destructive",
        });
        return;
      }
      
      addLog(`User found: ${user.id}`);
      addLog(`User email: ${user.email}`);
      addLog(`Email confirmed: ${user.email_confirmed_at ? 'Yes' : 'No'}`);

      // Check if profile already exists
      const { data: existingProfile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (profileError && !profileError.message.includes('No rows found')) {
        addLog(`Error checking existing profile: ${profileError.message}`);
      } else if (existingProfile) {
        addLog(`Profile already exists: ${JSON.stringify(existingProfile)}`);
      } else {
        addLog("No existing profile found");
      }

      // Check if tutor profile already exists
      const { data: existingTutorProfile, error: tutorProfileError } = await supabase
        .from('tutor_profiles')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (tutorProfileError && !tutorProfileError.message.includes('No rows found')) {
        addLog(`Error checking existing tutor profile: ${tutorProfileError.message}`);
      } else if (existingTutorProfile) {
        addLog(`Tutor profile already exists: ${JSON.stringify(existingTutorProfile)}`);
      } else {
        addLog("No existing tutor profile found");
      }

      // Test profile creation
      const testFormData = {
        fullName: "Test Tutor",
        city: "Test City",
        area: "Test Area",
        teachingMethodology: "Test teaching methodology",
        teachingExperience: "3-5 years",
        individualFee: "500",
        groupFee: "800",
        classType: "online",
        highestQualification: "Graduate",
        universityName: "Test University",
        yearOfPassing: "2020",
        percentage: "85",
        subjects: ["Mathematics", "Physics"],
        studentLevels: ["Secondary", "Higher Secondary"],
        curriculum: ["CBSE", "ICSE"],
        availableDays: ["Monday", "Tuesday"],
        timeSlots: {},
        maxTravelDistance: 10,
      };

      addLog("Attempting to create tutor profile...");
      const result = await createTutorProfileAfterVerification(user.id, testFormData);
      
      if (result.success) {
        addLog("Profile creation successful!");
        toast({
          title: "Success",
          description: result.message,
        });
      } else {
        addLog(`Profile creation failed: ${result.error}`);
        toast({
          title: "Error",
          description: result.error,
          variant: "destructive",
        });
      }

    } catch (error) {
      addLog(`Unexpected error: ${error}`);
      toast({
        title: "Error",
        description: "An unexpected error occurred",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const checkCurrentUser = async () => {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) {
      addLog(`Error getting user: ${error.message}`);
    } else if (user) {
      addLog(`Current user: ${user.id} (${user.email})`);
      addLog(`Email confirmed: ${user.email_confirmed_at ? 'Yes' : 'No'}`);
    } else {
      addLog("No user found");
    }
  };

  const clearLogs = () => {
    setLogs([]);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <Card>
        <CardHeader>
          <CardTitle>Test Profile Creation</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Button onClick={checkCurrentUser} variant="outline">
              Check Current User
            </Button>
            <Button onClick={testProfileCreation} disabled={isLoading}>
              {isLoading ? "Testing..." : "Test Profile Creation"}
            </Button>
            <Button onClick={clearLogs} variant="outline">
              Clear Logs
            </Button>
          </div>
          
          <div className="bg-muted p-4 rounded-lg max-h-96 overflow-y-auto">
            <h3 className="font-semibold mb-2">Logs:</h3>
            {logs.length === 0 ? (
              <p className="text-muted-foreground">No logs yet. Click a button to start testing.</p>
            ) : (
              <div className="space-y-1">
                {logs.map((log, index) => (
                  <div key={index} className="text-sm font-mono">
                    {log}
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 