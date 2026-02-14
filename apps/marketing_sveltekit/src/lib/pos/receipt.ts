import { Receipt } from '@/lib/types/pos';
import { formatCurrency, formatDate } from '@/lib/utils/formatting';

export const receiptService = {
    generateHTML(receipt: Receipt): string {
        const { sale, items, tenant_name, branch_name, cashier_name } = receipt;

        const itemsHtml = items.map(item => `
      <tr>
        <td style="padding: 5px 0;">
            <div>${item.product_name}</div>
            <div style="font-size: 0.8em; color: #666;">${item.quantity} x ${formatCurrency(item.unit_price)}</div>
        </td>
        <td style="text-align: right; vertical-align: top; padding: 5px 0;">
            ${formatCurrency(item.subtotal)}
        </td>
      </tr>
    `).join('');

        return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Courier New', monospace; font-size: 14px; max-width: 300px; margin: 0 auto; color: #000; }
          .header { text-align: center; margin-bottom: 20px; }
          .meta { margin-bottom: 15px; font-size: 12px; }
          .totals { margin-top: 15px; border-top: 1px dashed #000; padding-top: 10px; }
          .row { display: flex; justify-content: space-between; margin-bottom: 5px; }
          .bold { font-weight: bold; }
          table { width: 100%; border-collapse: collapse; }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="bold" style="font-size: 18px;">${tenant_name}</div>
          <div>${branch_name}</div>
          <br/>
          <div>RECEIPT</div>
        </div>
        
        <div class="meta">
          <div class="row"><span>Date:</span> <span>${formatDate(sale.created_at)}</span></div>
          <div class="row"><span>Sale #:</span> <span>${sale.sale_number}</span></div>
          <div class="row"><span>Cashier:</span> <span>${cashier_name}</span></div>
        </div>

        <table>
          ${itemsHtml}
        </table>

        <div class="totals">
          <div class="row"><span>Subtotal:</span> <span>${formatCurrency(sale.subtotal)}</span></div>
          ${sale.discount_amount > 0 ? `<div class="row"><span>Discount:</span> <span>-${formatCurrency(sale.discount_amount)}</span></div>` : ''}
          ${sale.tax_amount > 0 ? `<div class="row"><span>Tax:</span> <span>${formatCurrency(sale.tax_amount)}</span></div>` : ''}
          <div class="row bold" style="font-size: 16px; margin-top: 10px;">
            <span>TOTAL:</span> <span>${formatCurrency(sale.total_amount)}</span>
          </div>
        </div>
        
        <div style="text-align: center; margin-top: 30px; font-size: 12px;">
          Thank you for your patronage!
        </div>
      </body>
      </html>
    `;
    }
};
