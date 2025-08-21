import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { PricingService, PricingCalculation, UserSubscription } from '@/lib/pricing-service';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Check, Crown, Star, Users, Zap } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

const PricingPage: React.FC = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  
  const [user, setUser] = useState<any>(null);
  const [pricingCalculations, setPricingCalculations] = useState<PricingCalculation[]>([]);
  const [userSubscription, setUserSubscription] = useState<UserSubscription | null>(null);
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [loading, setLoading] = useState(true);
  const [selectedTier, setSelectedTier] = useState<string | null>(null);

  useEffect(() => {
    // Get current user
    const getCurrentUser = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        setUser(user);
      } catch (error) {
        console.error('Error getting user:', error);
      }
    };

    getCurrentUser();
    loadPricingData();
    
    // Subscribe to real-time updates
    const subscription = PricingService.subscribeToPricingUpdates(() => {
      loadPricingData();
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadPricingData = async () => {
    try {
      setLoading(true);
      const [calculations, subscription] = await Promise.all([
        PricingService.getAllPricingCalculations(),
        user ? PricingService.getUserSubscription(user.id) : Promise.resolve(null)
      ]);
      
      setPricingCalculations(calculations);
      setUserSubscription(subscription);
    } catch (error) {
      console.error('Error loading pricing data:', error);
      toast({
        title: "Error",
        description: "Failed to load pricing information",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  // Reload pricing data when user changes
  useEffect(() => {
    if (user) {
      loadPricingData();
    }
  }, [user]);

  const handleSubscribe = async (tierId: string) => {
    if (!user) {
      navigate('/login');
      return;
    }

    try {
      setSelectedTier(tierId);
      const subscription = await PricingService.createOrUpdateSubscription(
        user.id,
        tierId,
        billingCycle
      );
      
      setUserSubscription(subscription);
      
      toast({
        title: "Success!",
        description: "Your subscription has been updated",
      });
      
      // Navigate to payment or dashboard
      navigate('/dashboard');
    } catch (error) {
      console.error('Error updating subscription:', error);
      toast({
        title: "Error",
        description: "Failed to update subscription",
        variant: "destructive"
      });
    } finally {
      setSelectedTier(null);
    }
  };

  const handleCancelSubscription = async () => {
    if (!user || !userSubscription) return;

    try {
      await PricingService.cancelSubscription(user.id);
      setUserSubscription(null);
      
      toast({
        title: "Subscription Cancelled",
        description: "Your subscription has been cancelled",
      });
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      toast({
        title: "Error",
        description: "Failed to cancel subscription",
        variant: "destructive"
      });
    }
  };

  const getCurrentTier = () => {
    if (!userSubscription) return null;
    return pricingCalculations.find(calc => calc.tier.id === userSubscription.tier_id);
  };

  const getTierIcon = (tierName: string) => {
    switch (tierName) {
      case 'Basic':
        return <Users className="h-6 w-6" />;
      case 'Standard':
        return <Star className="h-6 w-6" />;
      case 'Professional':
        return <Zap className="h-6 w-6" />;
      case 'Enterprise':
        return <Crown className="h-6 w-6" />;
      case 'Unlimited':
        return <Crown className="h-6 w-6 text-yellow-500" />;
      default:
        return <Users className="h-6 w-6" />;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-lg text-gray-600">Loading pricing information...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              Choose Your Plan
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              Access students based on your practice size. Scale up as you grow.
            </p>
            
            {/* Billing Cycle Toggle */}
            <div className="flex items-center justify-center space-x-4 mb-8">
              <span className={`text-sm ${billingCycle === 'monthly' ? 'text-gray-900' : 'text-gray-500'}`}>
                Monthly
              </span>
              <Tabs value={billingCycle} onValueChange={(value) => setBillingCycle(value as 'monthly' | 'yearly')}>
                <TabsList className="grid w-20 grid-cols-2">
                  <TabsTrigger value="monthly">M</TabsTrigger>
                  <TabsTrigger value="yearly">Y</TabsTrigger>
                </TabsList>
              </Tabs>
              <span className={`text-sm ${billingCycle === 'yearly' ? 'text-gray-900' : 'text-gray-500'}`}>
                Yearly
                <Badge variant="secondary" className="ml-2">Save 20%</Badge>
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Current Subscription Status */}
      {userSubscription && (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <Card className="bg-gradient-to-r from-green-50 to-emerald-50 border-green-200">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-green-800">
                    Current Subscription: {getCurrentTier()?.tier.tier_name}
                  </h3>
                  <p className="text-green-600">
                    {userSubscription.current_student_count} / {userSubscription.max_students_allowed} students accessed
                  </p>
                  <p className="text-sm text-green-500">
                    Renews on {new Date(userSubscription.current_period_end).toLocaleDateString()}
                  </p>
                </div>
                <Button
                  variant="outline"
                  onClick={handleCancelSubscription}
                  className="border-green-300 text-green-700 hover:bg-green-100"
                >
                  Cancel Subscription
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Pricing Tiers */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6">
          {pricingCalculations.map((calculation) => {
            const isCurrentTier = userSubscription?.tier_id === calculation.tier.id;
            const isRecommended = calculation.isRecommended;
            
            return (
              <Card 
                key={calculation.tier.id} 
                className={`relative transition-all duration-200 hover:scale-105 ${
                  isCurrentTier 
                    ? 'ring-2 ring-green-500 bg-green-50' 
                    : isRecommended 
                    ? 'ring-2 ring-blue-500 bg-blue-50' 
                    : 'hover:shadow-lg'
                }`}
              >
                {isRecommended && (
                  <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                    <Badge className="bg-blue-600 text-white px-3 py-1">
                      <Star className="h-3 w-3 mr-1" />
                      Recommended
                    </Badge>
                  </div>
                )}
                
                {isCurrentTier && (
                  <div className="absolute -top-3 right-3">
                    <Badge className="bg-green-600 text-white">
                      Current Plan
                    </Badge>
                  </div>
                )}

                <CardHeader className="text-center pb-4">
                  <div className="flex justify-center mb-3">
                    {getTierIcon(calculation.tier.tier_name)}
                  </div>
                  <CardTitle className="text-xl font-bold text-gray-900">
                    {calculation.tier.tier_name}
                  </CardTitle>
                  <CardDescription className="text-gray-600">
                    {calculation.tier.description}
                  </CardDescription>
                </CardHeader>

                <CardContent className="pb-4">
                  {/* Price */}
                  <div className="text-center mb-6">
                    <div className="text-3xl font-bold text-gray-900">
                      ₹{billingCycle === 'monthly' ? calculation.monthlyPrice : calculation.yearlyPrice}
                    </div>
                    <div className="text-gray-500">
                      per {billingCycle === 'monthly' ? 'month' : 'year'}
                    </div>
                    {billingCycle === 'yearly' && (
                      <div className="text-sm text-green-600 mt-1">
                        Save ₹{calculation.savings} annually
                      </div>
                    )}
                  </div>

                  {/* Student Limits */}
                  <div className="text-center mb-6">
                    <div className="text-2xl font-bold text-indigo-600">
                      {calculation.tier.max_students}
                    </div>
                    <div className="text-gray-600">Students</div>
                    <div className="text-xs text-gray-500">
                      {calculation.tier.min_students === calculation.tier.max_students 
                        ? `Up to ${calculation.tier.max_students} students`
                        : `${calculation.tier.min_students}-${calculation.tier.max_students} students`
                      }
                    </div>
                  </div>

                  {/* Features */}
                  <div className="space-y-2">
                    <div className="flex items-center text-sm">
                      <Check className="h-4 w-4 text-green-500 mr-2" />
                      View student profiles
                    </div>
                    <div className="flex items-center text-sm">
                      <Check className="h-4 w-4 text-green-500 mr-2" />
                      Contact students
                    </div>
                    <div className="flex items-center text-sm">
                      <Check className="h-4 w-4 text-green-500 mr-2" />
                      Book sessions
                    </div>
                    {calculation.tier.tier_name !== 'Basic' && (
                      <>
                        <div className="flex items-center text-sm">
                          <Check className="h-4 w-4 text-green-500 mr-2" />
                          Priority support
                        </div>
                        <div className="flex items-center text-sm">
                          <Check className="h-4 w-4 text-green-500 mr-2" />
                          Advanced analytics
                        </div>
                      </>
                    )}
                  </div>
                </CardContent>

                <CardFooter>
                  <Button
                    className={`w-full ${
                      isCurrentTier
                        ? 'bg-green-600 hover:bg-green-700'
                        : isRecommended
                        ? 'bg-blue-600 hover:bg-blue-700'
                        : 'bg-gray-900 hover:bg-gray-800'
                    }`}
                    onClick={() => handleSubscribe(calculation.tier.id)}
                    disabled={isCurrentTier || selectedTier === calculation.tier.id}
                  >
                    {isCurrentTier 
                      ? 'Current Plan' 
                      : selectedTier === calculation.tier.id 
                      ? 'Updating...' 
                      : isCurrentTier 
                      ? 'Current Plan' 
                      : 'Subscribe'
                    }
                  </Button>
                </CardFooter>
              </Card>
            );
          })}
        </div>
      </div>

      {/* FAQ Section */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h2 className="text-3xl font-bold text-center text-gray-900 mb-8">
          Frequently Asked Questions
        </h2>
        <div className="space-y-6">
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              How does the student counting work?
            </h3>
            <p className="text-gray-600">
              We count unique students that you view, contact, or book sessions with. The count resets each billing cycle.
            </p>
          </div>
          
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Can I upgrade or downgrade my plan?
            </h3>
            <p className="text-gray-600">
              Yes! You can change your plan at any time. Upgrades take effect immediately, downgrades take effect at the next billing cycle.
            </p>
          </div>
          
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              What happens if I exceed my student limit?
            </h3>
            <p className="text-gray-600">
              You'll be prompted to upgrade your plan to continue accessing more students. Your existing student connections remain active.
            </p>
          </div>
          
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Is there a free trial?
            </h3>
            <p className="text-gray-600">
              Yes! The Basic tier allows you to access up to 5 students for free. Upgrade when you're ready to grow your practice.
            </p>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-indigo-600 py-16">
        <div className="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold text-white mb-4">
            Ready to Grow Your Practice?
          </h2>
          <p className="text-xl text-indigo-100 mb-8">
            Join thousands of tutors and institutions who are already connecting with students.
          </p>
          <Button 
            size="lg" 
            className="bg-white text-indigo-600 hover:bg-gray-100"
            onClick={() => navigate('/signup')}
          >
            Get Started Today
          </Button>
        </div>
      </div>
    </div>
  );
};

export default PricingPage;
