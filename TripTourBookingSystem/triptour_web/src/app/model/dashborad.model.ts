export interface DashboardResponse {
  success: boolean;
  data: DashboardData;
}

export interface DashboardData {
  summary: Summary;
  chart: ChartItem[];
  revenueByCountry: CountryStat[];
  usersByCountry: CountryStat[];
}

export interface Summary {
  totalIncome: number;
  totalUsers: number;
  toldTravelers: number;
  confirmedUsers: number;
  finishedUsers: number;
  paidUsers: number;
  pendingConfirmation: number;
  pendingPayment: number;
}

export interface ChartItem {
  label: string;
  value: number;
}

export interface CountryStat {
  label: string;
  value: number;
}