'use client';

import { useState, useEffect } from 'react';

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });

  const [dashboardData, setDashboardData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, [dateRange]);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `/api/analytics/dashboard?start_date=${dateRange.start}&end_date=${dateRange.end}`
      );
      const result = await response.json();
      if (result.success) {
        setDashboardData(result.data);
      }
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-NG').format(num);
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Sales Analytics Dashboard</h1>
        <p className="text-gray-600">Comprehensive insights into your business performance</p>
      </div>

      {/* Date Range Selector */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow">
        <div className="flex gap-4 items-end">
          <div>
            <label className="block text-sm font-medium mb-1">Start Date</label>
            <input
              type="date"
              value={dateRange.start}
              onChange={(e) => setDateRange({ ...dateRange, start: e.target.value })}
              className="border rounded px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">End Date</label>
            <input
              type="date"
              value={dateRange.end}
              onChange={(e) => setDateRange({ ...dateRange, end: e.target.value })}
              className="border rounded px-3 py-2"
            />
          </div>
          <button
            onClick={fetchDashboardData}
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
          >
            Apply
          </button>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading analytics...</p>
        </div>
      ) : dashboardData ? (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-600 mb-2">Total Revenue</h3>
              <p className="text-3xl font-bold text-blue-600">
                {formatCurrency(dashboardData.total_revenue)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Profit Margin: {dashboardData.average_profit_margin.toFixed(2)}%
              </p>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-600 mb-2">Total Transactions</h3>
              <p className="text-3xl font-bold text-green-600">
                {formatNumber(dashboardData.total_transactions)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Avg: {formatCurrency(dashboardData.average_transaction_value)}
              </p>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-600 mb-2">Total Profit</h3>
              <p className="text-3xl font-bold text-purple-600">
                {formatCurrency(dashboardData.total_profit)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Cost: {formatCurrency(dashboardData.total_cost)}
              </p>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-sm font-medium text-gray-600 mb-2">Items Sold</h3>
              <p className="text-3xl font-bold text-orange-600">
                {formatNumber(dashboardData.total_items_sold || 0)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Per Transaction: {((dashboardData.total_items_sold || 0) / dashboardData.total_transactions).toFixed(2)}
              </p>
            </div>
          </div>

          {/* Quick Links */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <a
              href="/analytics/products"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">📦 Product Analytics</h3>
              <p className="text-sm text-gray-600">
                View sales history, top products, and slow-moving inventory
              </p>
            </a>

            <a
              href="/analytics/brands"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">🏷️ Brand Comparison</h3>
              <p className="text-sm text-gray-600">
                Compare performance across different brands
              </p>
            </a>

            <a
              href="/analytics/staff"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">👥 Staff Performance</h3>
              <p className="text-sm text-gray-600">
                View staff leaderboards and commission tracking
              </p>
            </a>

            <a
              href="/analytics/categories"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">📊 Category Analysis</h3>
              <p className="text-sm text-gray-600">
                Analyze performance by product category
              </p>
            </a>

            <a
              href="/analytics/compare"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">📈 Period Comparison</h3>
              <p className="text-sm text-gray-600">
                Compare month, quarter, and year performance
              </p>
            </a>

            <a
              href="/analytics/patterns"
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow"
            >
              <h3 className="font-semibold text-lg mb-2">🕐 Time Patterns</h3>
              <p className="text-sm text-gray-600">
                View hourly sales patterns and peak hours
              </p>
            </a>
          </div>
        </>
      ) : (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <p className="text-gray-600">No data available for selected period</p>
        </div>
      )}
    </div>
  );
}
