// Loyalty Points Service (Disabled)
// This service has been disabled because the loyalty_points column was removed from the database.

export class LoyaltyService {
  constructor(private supabase: any) {}
  calculatePointsEarned() { return { points_earned: 0, order_amount: 0, multiplier: 0 }; }
  calculatePointsValue() { return 0; }
  async awardPoints() { return { success: true, new_balance: 0 }; }
  async redeemPoints() { return { success: true, new_balance: 0, naira_value: 0 }; }
  async getPointsBalance() { return { balance: { customer_id: '', points_balance: 0, points_value_naira: 0, lifetime_points: 0 } }; }
  async getTransactionHistory() { return { transactions: [] }; }
  async validateRedemption() { return { valid: false, error: 'Loyalty points system is currently disabled.' }; }
  getEarningRate() { return { points_per_naira: 0, naira_per_point: 0, description: 'Loyalty points system is currently disabled.' }; }
}
