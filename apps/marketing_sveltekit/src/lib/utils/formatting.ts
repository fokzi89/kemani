export const formatCurrency = (amount: number, currency: string = 'NGN') => {
  return new Intl.NumberFormat('en-NG', {
    style: 'currency',
    currency: currency,
  }).format(amount);
};

export const formatDate = (date: Date | string) => {
  return new Intl.DateTimeFormat('en-NG', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date(date));
};

export const formatTime = (date: Date | string) => {
  return new Intl.DateTimeFormat('en-NG', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
  }).format(new Date(date));
};

export const formatPhoneNumber = (phone: string) => {
  // Basic formatting for Nigerian numbers
  if (phone.startsWith('0') && phone.length === 11) {
    return `+234 ${phone.substring(1, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}`;
  }
  return phone;
};
