import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { Star } from "lucide-react";

export default function LeaveReview() {
  const { tutorId } = useParams();
  const [formData, setFormData] = useState({
    rating: 5,
    reviewText: '',
    subjectTaught: '',
    classType: 'online',
    classDate: '',
    anonymous: false
  });
  const [tutor, setTutor] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isLoadingTutor, setIsLoadingTutor] = useState(true);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    loadTutor();
  }, [tutorId]);

  const loadTutor = async () => {
    if (!tutorId) return;
    
    try {
      const { data, error } = await supabase
        .from('tutor_profiles')
        .select(`
          *,
          public_users!tutor_profiles_user_id_fkey(email)
        `)
        .eq('id', tutorId)
        .single();

      if (error) throw error;
      setTutor(data);
    } catch (error) {
      console.error('Error loading tutor:', error);
      toast({
        title: "Error",
        description: "Failed to load tutor information",
        variant: "destructive",
      });
    } finally {
      setIsLoadingTutor(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('You must be logged in to leave a review');
      }

      // Submit review
      const { error } = await supabase
        .from('reviews')
        .insert({
          student_id: user.id,
          tutor_id: tutorId,
          rating: formData.rating,
          review_text: formData.reviewText,
          subject_taught: formData.subjectTaught,
          class_type: formData.classType,
          class_date: formData.classDate,
          anonymous: formData.anonymous,
          verified_student: true,
          status: 'pending',
          created_at: new Date().toISOString()
        });

      if (error) throw error;

      toast({
        title: "Review Submitted!",
        description: "Your review has been submitted and is pending admin approval.",
      });

      // Redirect based on user role - for now redirect to home
      // TODO: Implement proper role-based redirect
      navigate('/');
    } catch (error) {
      console.error('Review submission error:', error);
      toast({
        title: "Submission Failed",
        description: error instanceof Error ? error.message : "Something went wrong",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string, value: string | number | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  if (isLoadingTutor) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading tutor information...</p>
        </div>
      </div>
    );
  }

  if (!tutor) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Card className="w-full max-w-md">
          <CardContent className="pt-6">
            <p className="text-center text-gray-600">Tutor not found</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <Card className="w-full max-w-2xl">
        <CardHeader>
          <CardTitle className="text-2xl text-center">Leave a Review</CardTitle>
          <div className="text-center text-gray-600">
            Review for <span className="font-semibold">{tutor.full_name}</span>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label>Rating</Label>
              <div className="flex space-x-1 mt-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => handleInputChange('rating', star)}
                    className="focus:outline-none"
                  >
                    <Star
                      className={`h-8 w-8 ${
                        star <= formData.rating
                          ? 'text-yellow-400 fill-current'
                          : 'text-gray-300'
                      }`}
                    />
                  </button>
                ))}
              </div>
              <p className="text-sm text-gray-500 mt-1">
                {formData.rating} out of 5 stars
              </p>
            </div>

            <div>
              <Label htmlFor="reviewText">Review</Label>
              <Textarea
                id="reviewText"
                value={formData.reviewText}
                onChange={(e) => handleInputChange('reviewText', e.target.value)}
                required
                placeholder="Share your experience with this tutor..."
                rows={4}
              />
            </div>

            <div>
              <Label htmlFor="subjectTaught">Subject Taught</Label>
              <Input
                id="subjectTaught"
                value={formData.subjectTaught}
                onChange={(e) => handleInputChange('subjectTaught', e.target.value)}
                placeholder="e.g., Mathematics, Physics"
              />
            </div>

            <div>
              <Label htmlFor="classType">Class Type</Label>
              <Select value={formData.classType} onValueChange={(value) => handleInputChange('classType', value)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="online">Online</SelectItem>
                  <SelectItem value="offline">Offline</SelectItem>
                  <SelectItem value="hybrid">Hybrid</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="classDate">Class Date</Label>
              <Input
                id="classDate"
                type="date"
                value={formData.classDate}
                onChange={(e) => handleInputChange('classDate', e.target.value)}
              />
            </div>

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="anonymous"
                checked={formData.anonymous}
                onChange={(e) => handleInputChange('anonymous', e.target.checked)}
                className="rounded"
              />
              <Label htmlFor="anonymous">Submit anonymously</Label>
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? "Submitting Review..." : "Submit Review"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
