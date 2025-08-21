import React, { useState, useEffect } from 'react';
import { PricingService, PricingTier, PricingConfig } from '@/lib/pricing-service';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Edit, Plus, Trash2, Save, X, DollarSign, Users, Settings, CheckCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

const PricingManagement: React.FC = () => {
  const { toast } = useToast();
  
  const [pricingTiers, setPricingTiers] = useState<PricingTier[]>([]);
  const [pricingConfig, setPricingConfig] = useState<PricingConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingTier, setEditingTier] = useState<PricingTier | null>(null);
  const [editingConfig, setEditingConfig] = useState<PricingConfig | null>(null);
  const [showTierDialog, setShowTierDialog] = useState(false);
  const [showConfigDialog, setShowConfigDialog] = useState(false);
  const [newTier, setNewTier] = useState<Partial<PricingTier>>({
    tier_name: '',
    min_students: 1,
    max_students: 5,
    price_multiplier: 1.00,
    description: '',
    is_active: true
  });

  useEffect(() => {
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
      const [tiers, config] = await Promise.all([
        PricingService.getPricingTiers(),
        PricingService.getPricingConfig()
      ]);
      
      setPricingTiers(tiers);
      setPricingConfig(config);
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

  const handleSaveTier = async () => {
    if (!editingTier) return;

    try {
      const { data, error } = await supabase
        .from('pricing_tiers')
        .update({
          tier_name: editingTier.tier_name,
          min_students: editingTier.min_students,
          max_students: editingTier.max_students,
          price_multiplier: editingTier.price_multiplier,
          description: editingTier.description,
          is_active: editingTier.is_active,
          updated_at: new Date().toISOString()
        })
        .eq('id', editingTier.id)
        .select()
        .single();

      if (error) throw error;

      setPricingTiers(prev => prev.map(tier => 
        tier.id === editingTier.id ? data : tier
      ));
      setEditingTier(null);
      
      toast({
        title: "Success",
        description: "Pricing tier updated successfully",
      });
    } catch (error) {
      console.error('Error updating tier:', error);
      toast({
        title: "Error",
        description: "Failed to update pricing tier",
        variant: "destructive"
      });
    }
  };

  const handleSaveConfig = async () => {
    if (!editingConfig) return;

    try {
      const { data, error } = await supabase
        .from('pricing_config')
        .update({
          base_price: editingConfig.base_price,
          currency: editingConfig.currency,
          billing_cycle: editingConfig.billing_cycle,
          annual_discount_percent: editingConfig.annual_discount_percent,
          is_active: editingConfig.is_active,
          updated_at: new Date().toISOString()
        })
        .eq('id', editingConfig.id)
        .select()
        .single();

      if (error) throw error;

      setPricingConfig(data);
      setEditingConfig(null);
      
      toast({
        title: "Success",
        description: "Pricing configuration updated successfully",
      });
    } catch (error) {
      console.error('Error updating config:', error);
      toast({
        title: "Error",
        description: "Failed to update pricing configuration",
        variant: "destructive"
      });
    }
  };

  const toggleTierStatus = async (tierId: string, currentStatus: boolean) => {
    try {
      const { data, error } = await supabase
        .from('pricing_tiers')
        .update({ 
          is_active: !currentStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', tierId)
        .select()
        .single();

      if (error) throw error;

      setPricingTiers(prev => prev.map(tier => 
        tier.id === tierId ? data : tier
      ));
      
      toast({
        title: "Success",
        description: `Tier ${!currentStatus ? 'activated' : 'deactivated'} successfully`,
      });
    } catch (error) {
      console.error('Error toggling tier status:', error);
      toast({
        title: "Error",
        description: "Failed to update tier status",
        variant: "destructive"
      });
    }
  };

  const handleDeleteTier = async (tierId: string) => {
    if (!confirm('Are you sure you want to delete this tier?')) return;

    try {
      const { error } = await supabase
        .from('pricing_tiers')
        .delete()
        .eq('id', tierId);

      if (error) throw error;

      setPricingTiers(prev => prev.filter(tier => tier.id !== tierId));
      
      toast({
        title: "Success",
        description: "Pricing tier deleted successfully",
      });
    } catch (error) {
      console.error('Error deleting tier:', error);
      toast({
        title: "Error",
        description: "Failed to delete pricing tier",
        variant: "destructive"
      });
    }
  };

  const calculatePricing = (tier: PricingTier) => {
    if (!pricingConfig) return { monthlyPrice: 0, yearlyPrice: 0, savings: 0 };
    
    const monthlyPrice = pricingConfig.base_price * tier.price_multiplier;
    const yearlyPrice = monthlyPrice * 12 * (1 - pricingConfig.annual_discount_percent / 100);
    const savings = (monthlyPrice * 12) - yearlyPrice;
    
    return {
      monthlyPrice: Math.round(monthlyPrice * 100) / 100,
      yearlyPrice: Math.round(yearlyPrice * 100) / 100,
      savings: Math.round(savings * 100) / 100
    };
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading pricing data...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Pricing Management</h2>
          <p className="text-gray-600">Manage pricing tiers and configuration for student access</p>
        </div>
        <Button onClick={() => setShowTierDialog(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Add Tier
        </Button>
      </div>

      {/* Success Message */}
      {pricingTiers.length > 0 && (
        <Card className="bg-green-50 border border-green-200">
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <span className="text-green-800 font-medium">
                ✅ Pricing system detected! {pricingTiers.length} tiers loaded successfully.
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      <Tabs defaultValue="tiers" className="space-y-6">
        <TabsList>
          <TabsTrigger value="tiers" className="flex items-center space-x-2">
            <Users className="h-4 w-4" />
            Pricing Tiers
          </TabsTrigger>
          <TabsTrigger value="config" className="flex items-center space-x-2">
            <Settings className="h-4 w-4" />
            Configuration
          </TabsTrigger>
        </TabsList>

        <TabsContent value="tiers" className="space-y-6">
          {/* Pricing Tiers */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {pricingTiers.map((tier) => {
              const pricing = calculatePricing(tier);
              return (
                <Card key={tier.id} className="relative">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-lg">{tier.tier_name}</CardTitle>
                      <Badge variant={tier.is_active ? "default" : "secondary"}>
                        {tier.is_active ? "Active" : "Inactive"}
                      </Badge>
                    </div>
                    <CardDescription>{tier.description}</CardDescription>
                  </CardHeader>
                  
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label className="text-sm font-medium">Min Students</Label>
                        <div className="text-lg font-semibold">{tier.min_students}</div>
                      </div>
                      <div>
                        <Label className="text-sm font-medium">Max Students</Label>
                        <div className="text-lg font-semibold">{tier.max_students}</div>
                      </div>
                    </div>
                    
                    <div>
                      <Label className="text-sm font-medium">Price Multiplier</Label>
                      <div className="text-2xl font-bold text-indigo-600">{tier.price_multiplier}x</div>
                    </div>

                    <div className="bg-gray-50 p-3 rounded-lg">
                      <div className="text-sm text-gray-600 mb-2">Pricing:</div>
                      <div className="space-y-1">
                        <div className="flex justify-between">
                          <span className="text-sm">Monthly:</span>
                          <span className="font-semibold">₹{pricing.monthlyPrice}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm">Yearly:</span>
                          <span className="font-semibold">₹{pricing.yearlyPrice}</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>

                  <div className="absolute top-4 right-4 flex space-x-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setEditingTier(tier)}
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => toggleTierStatus(tier.id, tier.is_active)}
                    >
                      {tier.is_active ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
                    </Button>
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => handleDeleteTier(tier.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </Card>
              );
            })}

            {/* Add New Tier Card */}
            <Card className="border-dashed border-2 border-gray-300 hover:border-gray-400 transition-colors">
              <CardContent className="flex items-center justify-center h-32">
                <Dialog open={showTierDialog} onOpenChange={setShowTierDialog}>
                  <DialogTrigger asChild>
                    <Button variant="ghost" className="h-full w-full">
                      <Plus className="h-8 w-8 text-gray-400" />
                      <span className="ml-2 text-gray-600">Add New Tier</span>
                    </Button>
                  </DialogTrigger>
                  
                  <DialogContent className="sm:max-w-[425px]">
                    <DialogHeader>
                      <DialogTitle>Create New Pricing Tier</DialogTitle>
                      <DialogDescription>
                        Add a new pricing tier for student access
                      </DialogDescription>
                    </DialogHeader>
                    
                    <div className="grid gap-4 py-4">
                      <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="tier_name" className="text-right">Name</Label>
                        <Input
                          id="tier_name"
                          value={newTier.tier_name}
                          onChange={(e) => setNewTier(prev => ({ ...prev, tier_name: e.target.value }))}
                          className="col-span-3"
                        />
                      </div>
                      
                      <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="min_students" className="text-right">Min Students</Label>
                        <Input
                          id="min_students"
                          type="number"
                          value={newTier.min_students}
                          onChange={(e) => setNewTier(prev => ({ ...prev, min_students: parseInt(e.target.value) }))}
                          className="col-span-3"
                        />
                      </div>
                      
                      <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="max_students" className="text-right">Max Students</Label>
                        <Input
                          id="max_students"
                          type="number"
                          value={newTier.max_students}
                          onChange={(e) => setNewTier(prev => ({ ...prev, max_students: parseInt(e.target.value) }))}
                          className="col-span-3"
                        />
                      </div>
                      
                      <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="price_multiplier" className="text-right">Multiplier</Label>
                        <Input
                          id="price_multiplier"
                          type="number"
                          step="0.01"
                          value={newTier.price_multiplier}
                          onChange={(e) => setNewTier(prev => ({ ...prev, price_multiplier: parseFloat(e.target.value) }))}
                          className="col-span-3"
                        />
                      </div>
                      
                      <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="description" className="text-right">Description</Label>
                        <Textarea
                          id="description"
                          value={newTier.description}
                          onChange={(e) => setNewTier(prev => ({ ...prev, description: e.target.value }))}
                          className="col-span-3"
                        />
                      </div>
                    </div>
                    
                    <DialogFooter>
                      <Button variant="outline" onClick={() => setShowTierDialog(false)}>
                        Cancel
                      </Button>
                      <Button onClick={() => {
                        // TODO: Implement create tier functionality
                        setShowTierDialog(false);
                      }}>
                        <Plus className="h-4 w-4 mr-2" />
                        Create Tier
                      </Button>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="config" className="space-y-6">
          {/* Pricing Configuration */}
          {pricingConfig && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Settings className="h-5 w-5" />
                  <span>Base Configuration</span>
                </CardTitle>
                <CardDescription>Manage base pricing and billing settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div>
                      <Label className="text-sm font-medium">Base Price</Label>
                      <div className="text-2xl font-bold text-green-600">
                        ₹{pricingConfig.base_price}
                      </div>
                      <p className="text-sm text-gray-500">per month</p>
                    </div>
                    
                    <div>
                      <Label className="text-sm font-medium">Currency</Label>
                      <div className="text-lg font-semibold">{pricingConfig.currency}</div>
                    </div>
                  </div>
                  
                  <div className="space-y-4">
                    <div>
                      <Label className="text-sm font-medium">Billing Cycle</Label>
                      <div className="text-lg font-semibold capitalize">{pricingConfig.billing_cycle}</div>
                    </div>
                    
                    <div>
                      <Label className="text-sm font-medium">Annual Discount</Label>
                      <div className="text-lg font-semibold text-blue-600">{pricingConfig.annual_discount_percent}%</div>
                    </div>
                  </div>
                </div>
                
                <Button onClick={() => setEditingConfig(pricingConfig)}>
                  <Edit className="h-4 w-4 mr-2" />
                  Edit Configuration
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Pricing Table */}
          <Card>
            <CardHeader>
              <CardTitle>Pricing Overview</CardTitle>
              <CardDescription>Complete pricing breakdown for all tiers</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2 font-medium">Tier</th>
                      <th className="text-center py-2 font-medium">Student Limit</th>
                      <th className="text-center py-2 font-medium">Monthly Price</th>
                      <th className="text-center py-2 font-medium">Yearly Price</th>
                      <th className="text-center py-2 font-medium">Annual Savings</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pricingTiers.map((tier) => {
                      const pricing = calculatePricing(tier);
                      return (
                        <tr key={tier.id} className="border-b">
                          <td className="py-2 font-medium">{tier.tier_name}</td>
                          <td className="py-2 text-center">{tier.max_students}</td>
                          <td className="py-2 text-center font-semibold">₹{pricing.monthlyPrice.toFixed(2)}</td>
                          <td className="py-2 text-center font-semibold">₹{pricing.yearlyPrice.toFixed(2)}</td>
                          <td className="py-2 text-center text-green-600">₹{pricing.savings.toFixed(2)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Edit Tier Dialog */}
      {editingTier && (
        <Dialog open={!!editingTier} onOpenChange={() => setEditingTier(null)}>
          <DialogContent className="sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle>Edit Pricing Tier</DialogTitle>
              <DialogDescription>
                Update the pricing tier configuration
              </DialogDescription>
            </DialogHeader>
            
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_tier_name" className="text-right">Name</Label>
                <Input
                  id="edit_tier_name"
                  value={editingTier.tier_name}
                  onChange={(e) => setEditingTier(prev => prev ? { ...prev, tier_name: e.target.value } : null)}
                  className="col-span-3"
                />
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_min_students" className="text-right">Min Students</Label>
                <Input
                  id="edit_min_students"
                  type="number"
                  value={editingTier.min_students}
                  onChange={(e) => setEditingTier(prev => prev ? { ...prev, min_students: parseInt(e.target.value) } : null)}
                  className="col-span-3"
                />
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_max_students" className="text-right">Max Students</Label>
                <Input
                  id="edit_max_students"
                  type="number"
                  value={editingTier.min_students}
                  onChange={(e) => setEditingTier(prev => prev ? { ...prev, max_students: parseInt(e.target.value) } : null)}
                  className="col-span-3"
                />
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_price_multiplier" className="text-right">Multiplier</Label>
                <Input
                  id="edit_price_multiplier"
                  type="number"
                  step="0.01"
                  value={editingTier.price_multiplier}
                  onChange={(e) => setEditingTier(prev => prev ? { ...prev, price_multiplier: parseFloat(e.target.value) } : null)}
                  className="col-span-3"
                />
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_description" className="text-right">Description</Label>
                <Textarea
                  id="edit_description"
                  value={editingTier.description}
                  onChange={(e) => setEditingTier(prev => prev ? { ...prev, description: e.target.value } : null)}
                  className="col-span-3"
                />
              </div>
            </div>
            
            <DialogFooter>
              <Button variant="outline" onClick={() => setEditingTier(null)}>
                Cancel
              </Button>
              <Button onClick={handleSaveTier}>
                <Save className="h-4 w-4 mr-2" />
                Save Changes
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Edit Config Dialog */}
      {editingConfig && (
        <Dialog open={!!editingConfig} onOpenChange={() => setEditingConfig(null)}>
          <DialogContent className="sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle>Edit Pricing Configuration</DialogTitle>
              <DialogDescription>
                Update the base pricing and billing configuration
              </DialogDescription>
            </DialogHeader>
            
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_base_price" className="text-right">Base Price</Label>
                <Input
                  id="edit_base_price"
                  type="number"
                  step="0.01"
                  value={editingConfig.base_price}
                  onChange={(e) => setEditingConfig(prev => prev ? { ...prev, base_price: parseFloat(e.target.value) } : null)}
                  className="col-span-3"
                />
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_currency" className="text-right">Currency</Label>
                <Select
                  value={editingConfig.currency}
                  onValueChange={(value) => setEditingConfig(prev => prev ? { ...prev, currency: value } : null)}
                >
                  <SelectTrigger className="col-span-3">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="INR">INR (₹)</SelectItem>
                    <SelectItem value="USD">USD ($)</SelectItem>
                    <SelectItem value="EUR">EUR (€)</SelectItem>
                    <SelectItem value="GBP">GBP (£)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_billing_cycle" className="text-right">Billing</Label>
                <Select
                  value={editingConfig.billing_cycle}
                  onValueChange={(value) => setEditingConfig(prev => prev ? { ...prev, billing_cycle: value as 'monthly' | 'yearly' } : null)}
                >
                  <SelectTrigger className="col-span-3">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="yearly">Yearly</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="edit_discount" className="text-right">Annual Discount</Label>
                <Input
                  id="edit_discount"
                  type="number"
                  step="0.01"
                  value={editingConfig.annual_discount_percent}
                  onChange={(e) => setEditingConfig(prev => prev ? { ...prev, annual_discount_percent: parseFloat(e.target.value) } : null)}
                  className="col-span-3"
                />
              </div>
            </div>
            
            <DialogFooter>
              <Button variant="outline" onClick={() => setEditingConfig(null)}>
                Cancel
              </Button>
              <Button onClick={handleSaveConfig}>
                <Save className="h-4 w-4 mr-2" />
                Save Changes
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
};

export default PricingManagement;
