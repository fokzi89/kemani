export const taxCalculator = {
    calculateTax(subtotal: number, taxRatePercent: number): number {
        if (taxRatePercent < 0) return 0;
        return Number((subtotal * (taxRatePercent / 100)).toFixed(2));
    },

    calculateTotals(items: { unit_price: number; quantity: number; discount_amount?: number }[], taxRatePercent: number) {
        const subtotal = items.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
        const totalDiscount = items.reduce((sum, item) => sum + (item.discount_amount || 0), 0);

        // Check if discount applies before tax (usually yes)
        const taxableAmount = subtotal - totalDiscount;
        const taxAmount = this.calculateTax(taxableAmount, taxRatePercent);
        const total = taxableAmount + taxAmount;

        return {
            subtotal,
            discount: totalDiscount,
            tax: taxAmount,
            total
        };
    }
};
