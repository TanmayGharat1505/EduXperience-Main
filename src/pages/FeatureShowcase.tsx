import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { 
  Users, 
  BookOpen, 
  Star, 
  CreditCard, 
  TrendingUp, 
  Shield,
  Upload,
  MessageSquare
} from "lucide-react";

export default function FeatureShowcase() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            EduXperience Admin Dashboard
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            A production-ready admin dashboard for managing tutors, students, content, and payments.
            Test all features with real-time data generation.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          {/* User Management */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <Users className="h-12 w-12 text-blue-600 mx-auto mb-2" />
              <CardTitle>User Management</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Register new users, verify accounts, and manage user roles
              </p>
              <Link to="/register">
                <Button className="w-full">Test User Registration</Button>
              </Link>
            </CardContent>
          </Card>

          {/* Content Management */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <BookOpen className="h-12 w-12 text-green-600 mx-auto mb-2" />
              <CardTitle>Content Management</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Upload educational content, moderate submissions, and track usage
              </p>
              <Link to="/upload-content">
                <Button className="w-full">Test Content Upload</Button>
              </Link>
            </CardContent>
          </Card>

          {/* Review System */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <Star className="h-12 w-12 text-yellow-600 mx-auto mb-2" />
              <CardTitle>Review System</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Submit and moderate student reviews for tutors
              </p>
              <Link to="/review/sample-tutor-id">
                <Button className="w-full">Test Review System</Button>
              </Link>
            </CardContent>
          </Card>

          {/* Payment Management */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <CreditCard className="h-12 w-12 text-purple-600 mx-auto mb-2" />
              <CardTitle>Payment Management</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Track transactions, manage payouts, and monitor revenue
              </p>
              <Button className="w-full" disabled>
                View in Admin Dashboard
              </Button>
            </CardContent>
          </Card>

          {/* Analytics */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <TrendingUp className="h-12 w-12 text-indigo-600 mx-auto mb-2" />
              <CardTitle>Analytics Dashboard</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Real-time insights into user growth, engagement, and revenue
              </p>
              <Link to="/admin/dashboard">
                <Button className="w-full">View Analytics</Button>
              </Link>
            </CardContent>
          </Card>

          {/* Admin Panel */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="text-center">
              <Shield className="h-12 w-12 text-red-600 mx-auto mb-2" />
              <CardTitle>Admin Panel</CardTitle>
            </CardHeader>
            <CardContent className="text-center">
              <p className="text-gray-600 mb-4">
                Full admin dashboard with real-time moderation tools
              </p>
              <Link to="/admin/dashboard">
                <Button className="w-full">Access Admin Panel</Button>
              </Link>
            </CardContent>
          </Card>
        </div>

        {/* Testing Instructions */}
        <Card className="max-w-4xl mx-auto">
          <CardHeader>
            <CardTitle className="text-2xl text-center">🚀 Testing Instructions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="bg-blue-50 p-4 rounded-lg">
              <h3 className="font-semibold text-blue-900 mb-2">Step 1: Create Test Users</h3>
              <p className="text-blue-800">
                Use the registration form to create multiple users with different roles. 
                Each user will appear in the admin dashboard in real-time.
              </p>
            </div>

            <div className="bg-green-50 p-4 rounded-lg">
              <h3 className="font-semibold text-green-900 mb-2">Step 2: Upload Content</h3>
              <p className="text-green-800">
                Login as tutors and upload various types of educational content. 
                All content will appear in the admin dashboard for moderation.
              </p>
            </div>

            <div className="bg-yellow-50 p-4 rounded-lg">
              <h3 className="font-semibold text-yellow-900 mb-2">Step 3: Submit Reviews</h3>
              <p className="text-yellow-800">
                Login as students and leave reviews for tutors. 
                Reviews will appear in the admin dashboard for approval.
              </p>
            </div>

            <div className="bg-purple-50 p-4 rounded-lg">
              <h3 className="font-semibold text-purple-900 mb-2">Step 4: Monitor Admin Dashboard</h3>
              <p className="text-purple-800">
                Open the admin dashboard in another tab and watch real-time updates 
                as users register, upload content, and submit reviews.
              </p>
            </div>

            <div className="text-center mt-6">
              <Link to="/admin/dashboard">
                <Button size="lg" className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700">
                  🎯 Start Testing Admin Dashboard
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
