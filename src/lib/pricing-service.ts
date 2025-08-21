import { supabase } from '@/integrations/supabase/client';

export interface PricingTier {
  id: string;
  tier_name: string;
  min_students: number;
  max_students: number;
  price_multiplier: number;
  description: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PricingConfig {
  id: string;
  base_price: number;
  currency: string;
  billing_cycle: 'monthly' | 'yearly';
  annual_discount_percent: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserSubscription {
  id: string;
  user_id: string;
  tier_id: string;
  current_student_count: number;
  max_students_allowed: number;
  subscription_status: 'active' | 'expired' | 'cancelled' | 'suspended';
  current_period_start: string;
  current_period_end: string;
  auto_renew: boolean;
  created_at: string;
  updated_at: string;
  tier?: PricingTier;
}

export interface SubscriptionPayment {
  id: string;
  subscription_id: string;
  amount: number;
  currency: string;
  payment_method?: string;
  payment_status: 'pending' | 'completed' | 'failed' | 'refunded';
  transaction_id?: string;
  payment_date: string;
  created_at: string;
}

export interface StudentAccessLog {
  id: string;
  tutor_id: string;
  student_id: string;
  access_type: 'view' | 'contact' | 'book';
  access_timestamp: string;
  subscription_tier_at_time?: string;
  created_at: string;
}

export interface PricingCalculation {
  tier: PricingTier;
  monthlyPrice: number;
  yearlyPrice: number;
  savings: number;
  isRecommended: boolean;
}

export class PricingService {
  // Get all pricing tiers
  static async getPricingTiers(): Promise<PricingTier[]> {
    const { data, error } = await supabase
      .from('pricing_tiers')
      .select('*')
      .eq('is_active', true)
      .order('min_students', { ascending: true });

    if (error) {
      console.error('Error fetching pricing tiers:', error);
      throw error;
    }

    return data || [];
  }

  // Get pricing configuration
  static async getPricingConfig(): Promise<PricingConfig | null> {
    const { data, error } = await supabase
      .from('pricing_config')
      .select('*')
      .eq('is_active', true)
      .single();

    if (error) {
      console.error('Error fetching pricing config:', error);
      return null;
    }

    return data;
  }

  // Get user's current subscription
  static async getUserSubscription(userId: string): Promise<UserSubscription | null> {
    const { data, error } = await supabase
      .from('user_subscriptions')
      .select(`
        *,
        tier:pricing_tiers(*)
      `)
      .eq('user_id', userId)
      .eq('subscription_status', 'active')
      .order('created_at', { ascending: false })
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        // No subscription found
        return null;
      }
      console.error('Error fetching user subscription:', error);
      throw error;
    }

    return data;
  }

  // Get user's subscription history
  static async getUserSubscriptionHistory(userId: string): Promise<UserSubscription[]> {
    const { data, error } = await supabase
      .from('user_subscriptions')
      .select(`
        *,
        tier:pricing_tiers(*)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching subscription history:', error);
      throw error;
    }

    return data || [];
  }

  // Get user's payment history
  static async getUserPaymentHistory(userId: string): Promise<SubscriptionPayment[]> {
    const { data, error } = await supabase
      .from('subscription_payments')
      .select('*')
      .eq('subscription_id', 
        supabase
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', userId)
      )
      .order('payment_date', { ascending: false });

    if (error) {
      console.error('Error fetching payment history:', error);
      throw error;
    }

    return data || [];
  }

  // Calculate pricing for a specific tier
  static async calculatePricing(tierId: string, billingCycle: 'monthly' | 'yearly' = 'monthly'): Promise<number> {
    const { data, error } = await supabase
      .rpc('calculate_subscription_price', {
        p_tier_id: tierId,
        p_billing_cycle: billingCycle
      });

    if (error) {
      console.error('Error calculating pricing:', error);
      throw error;
    }

    return data || 0;
  }

  // Get all pricing calculations for comparison
  static async getAllPricingCalculations(): Promise<PricingCalculation[]> {
    const [tiers, config] = await Promise.all([
      this.getPricingTiers(),
      this.getPricingConfig()
    ]);

    if (!config) {
      throw new Error('Pricing configuration not found');
    }

    const calculations: PricingCalculation[] = [];

    for (const tier of tiers) {
      const monthlyPrice = config.base_price * tier.price_multiplier;
      const yearlyPrice = monthlyPrice * 12 * (1 - config.annual_discount_percent / 100);
      const savings = (monthlyPrice * 12) - yearlyPrice;

      calculations.push({
        tier,
        monthlyPrice: Math.round(monthlyPrice * 100) / 100,
        yearlyPrice: Math.round(yearlyPrice * 100) / 100,
        savings: Math.round(savings * 100) / 100,
        isRecommended: tier.tier_name === 'Standard' // Recommend Standard tier
      });
    }

    return calculations;
  }

  // Check if user can access more students
  static async canAccessMoreStudents(userId: string, requiredStudents: number = 1): Promise<boolean> {
    const { data, error } = await supabase
      .rpc('can_access_more_students', {
        p_user_id: userId,
        p_required_students: requiredStudents
      });

    if (error) {
      console.error('Error checking student access:', error);
      return false;
    }

    return data || false;
  }

  // Log student access
  static async logStudentAccess(tutorId: string, studentId: string, accessType: 'view' | 'contact' | 'book' = 'view'): Promise<boolean> {
    const { data, error } = await supabase
      .rpc('log_student_access', {
        p_tutor_id: tutorId,
        p_student_id: studentId,
        p_access_type: accessType
      });

    if (error) {
      console.error('Error logging student access:', error);
      return false;
    }

    return data || false;
  }

  // Create or update user subscription
  static async createOrUpdateSubscription(
    userId: string,
    tierId: string,
    billingCycle: 'monthly' | 'yearly' = 'monthly'
  ): Promise<UserSubscription> {
    // Check if user already has an active subscription
    const existingSubscription = await this.getUserSubscription(userId);

    if (existingSubscription) {
      // Update existing subscription
      const { data, error } = await supabase
        .from('user_subscriptions')
        .update({
          tier_id: tierId,
          max_students_allowed: (await this.getPricingTiers()).find(t => t.id === tierId)?.max_students || 5,
          updated_at: new Date().toISOString()
        })
        .eq('id', existingSubscription.id)
        .select('*')
        .single();

      if (error) {
        console.error('Error updating subscription:', error);
        throw error;
      }

      return data;
    } else {
      // Create new subscription
      const tier = (await this.getPricingTiers()).find(t => t.id === tierId);
      if (!tier) {
        throw new Error('Invalid tier ID');
      }

      const { data, error } = await supabase
        .from('user_subscriptions')
        .insert({
          user_id: userId,
          tier_id: tierId,
          current_student_count: 0,
          max_students_allowed: tier.max_students,
          subscription_status: 'active',
          current_period_start: new Date().toISOString(),
          current_period_end: new Date(Date.now() + (billingCycle === 'monthly' ? 30 : 365) * 24 * 60 * 60 * 1000).toISOString(),
          auto_renew: true
        })
        .select('*')
        .single();

      if (error) {
        console.error('Error creating subscription:', error);
        throw error;
      }

      return data;
    }
  }

  // Cancel user subscription
  static async cancelSubscription(userId: string): Promise<void> {
    const { error } = await supabase
      .from('user_subscriptions')
      .update({
        subscription_status: 'cancelled',
        auto_renew: false,
        updated_at: new Date().toISOString()
      })
      .eq('user_id', userId)
      .eq('subscription_status', 'active');

    if (error) {
      console.error('Error cancelling subscription:', error);
      throw error;
    }
  }

  // Record payment
  static async recordPayment(
    subscriptionId: string,
    amount: number,
    paymentMethod: string,
    transactionId?: string
  ): Promise<SubscriptionPayment> {
    const { data, error } = await supabase
      .from('subscription_payments')
      .insert({
        subscription_id: subscriptionId,
        amount,
        currency: 'INR',
        payment_method: paymentMethod,
        payment_status: 'completed',
        transaction_id: transactionId,
        payment_date: new Date().toISOString()
      })
      .select('*')
      .single();

    if (error) {
      console.error('Error recording payment:', error);
      throw error;
    }

    return data;
  }

  // Get student access logs for a tutor
  static async getStudentAccessLogs(tutorId: string): Promise<StudentAccessLog[]> {
    const { data, error } = await supabase
      .from('student_access_logs')
      .select('*')
      .eq('tutor_id', tutorId)
      .order('access_timestamp', { ascending: false });

    if (error) {
      console.error('Error fetching access logs:', error);
      throw error;
    }

    return data || [];
  }

  // Get analytics for admin dashboard
  static async getPricingAnalytics(): Promise<{
    totalSubscriptions: number;
    activeSubscriptions: number;
    totalRevenue: number;
    tierDistribution: { tier: string; count: number }[];
    monthlyGrowth: number;
  }> {
    const [
      { count: totalSubscriptions },
      { count: activeSubscriptions },
      { data: tierDistribution },
      { data: paymentsData }
    ] = await Promise.all([
      supabase.from('user_subscriptions').select('*', { count: 'exact', head: true }),
      supabase.from('user_subscriptions').select('*', { count: 'exact', head: true }).eq('subscription_status', 'active'),
      supabase
        .from('user_subscriptions')
        .select('tier_id, pricing_tiers(tier_name)')
        .eq('subscription_status', 'active'),
      supabase
        .from('subscription_payments')
        .select('amount')
        .eq('payment_status', 'completed')
    ]);

    // Calculate tier distribution
    const tierCounts: { [key: string]: number } = {};
    tierDistribution?.forEach(item => {
      const tierName = (item.pricing_tiers as any)?.tier_name || 'Unknown';
      tierCounts[tierName] = (tierCounts[tierName] || 0) + 1;
    });

    const tierDistributionArray = Object.entries(tierCounts).map(([tier, count]) => ({
      tier,
      count
    }));

    // Calculate total revenue
    const totalRevenue = paymentsData?.reduce((sum, payment) => sum + payment.amount, 0) || 0;

    return {
      totalSubscriptions: totalSubscriptions || 0,
      activeSubscriptions: activeSubscriptions || 0,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      tierDistribution: tierDistributionArray,
      monthlyGrowth: 0 // TODO: Implement monthly growth calculation
    };
  }

  // Subscribe to real-time updates
  static subscribeToPricingUpdates(callback: (payload: any) => void) {
    const subscription = supabase
      .channel('pricing-updates')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'pricing_tiers'
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'pricing_config'
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'user_subscriptions'
        },
        callback
      )
      .subscribe();

    return subscription;
  }
}
