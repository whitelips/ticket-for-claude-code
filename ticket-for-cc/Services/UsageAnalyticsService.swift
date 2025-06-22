import Foundation

class UsageAnalyticsService: ObservableObject {
    @Published var dailyUsages: [DailyUsage] = []
    @Published var monthlyUsages: [MonthlyUsage] = []
    @Published var sessionBlocks: [SessionBlock] = []
    @Published var modelBreakdown: [String: ModelUsage] = [:]
    
    // Current period analytics
    @Published var todayUsage: DailyUsage?
    @Published var currentMonthUsage: MonthlyUsage?
    
    func analyzeUsageData(_ entries: [UsageEntry]) {
        guard !entries.isEmpty else { return }
        
        // Group by day
        groupByDay(entries)
        
        // Group by month
        groupByMonth()
        
        // Group by session
        groupBySessions(entries)
        
        // Calculate model breakdown
        calculateModelBreakdown(entries)
        
        // Set current period data
        setCurrentPeriods()
    }
    
    private func groupByDay(_ entries: [UsageEntry]) {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        dailyUsages = grouped.map { date, entries in
            var dailyUsage = DailyUsage(date: date)
            dailyUsage.entries = entries.sorted { $0.timestamp < $1.timestamp }
            return dailyUsage
        }.sorted { $0.date < $1.date }
    }
    
    private func groupByMonth() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dailyUsages) { dailyUsage in
            calendar.dateInterval(of: .month, for: dailyUsage.date)?.start ?? dailyUsage.date
        }
        
        monthlyUsages = grouped.map { month, dailyUsages in
            var monthlyUsage = MonthlyUsage(month: month)
            monthlyUsage.dailyUsages = dailyUsages.sorted { $0.date < $1.date }
            return monthlyUsage
        }.sorted { $0.month < $1.month }
    }
    
    private func groupBySessions(_ entries: [UsageEntry]) {
        let grouped = Dictionary(grouping: entries) { $0.sessionId }
        
        sessionBlocks = grouped.compactMap { sessionId, entries in
            guard !entries.isEmpty else { return nil }
            let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
            
            var sessionBlock = SessionBlock(
                sessionId: sessionId,
                startTime: sortedEntries.first!.timestamp
            )
            sessionBlock.entries = sortedEntries
            return sessionBlock
        }.sorted { $0.startTime < $1.startTime }
    }
    
    private func calculateModelBreakdown(_ entries: [UsageEntry]) {
        modelBreakdown.removeAll()
        
        for entry in entries {
            if modelBreakdown[entry.model] == nil {
                modelBreakdown[entry.model] = ModelUsage(model: entry.model)
            }
            modelBreakdown[entry.model]?.addEntry(entry)
        }
    }
    
    private func setCurrentPeriods() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? today
        
        todayUsage = dailyUsages.first { calendar.isDate($0.date, inSameDayAs: today) }
        currentMonthUsage = monthlyUsages.first { calendar.isDate($0.month, inSameDayAs: currentMonth) }
    }
    
    // ccusage-style calculations
    func getTotalCostForPeriod(_ startDate: Date, _ endDate: Date) -> Double {
        dailyUsages
            .filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0.0) { $0 + $1.totalCost }
    }
    
    func getTokensPerHour(for session: SessionBlock) -> Double {
        guard session.duration > 0 else { return 0 }
        return Double(session.totalTokens) / (session.duration / 3600.0)
    }
    
    func getAverageCostPerRequest(for model: String) -> Double {
        guard let modelUsage = modelBreakdown[model], modelUsage.requestCount > 0 else { return 0 }
        return modelUsage.cost / Double(modelUsage.requestCount)
    }
    
    func getBillingBlocks() -> [Date: [SessionBlock]] {
        return Dictionary(grouping: sessionBlocks) { $0.billingBlockStart }
    }
    
    func getUsageTrend(days: Int = 7) -> [DailyUsage] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return dailyUsages.filter { $0.date >= startDate }
    }
    
    func getMostExpensiveSession() -> SessionBlock? {
        return sessionBlocks.max { $0.totalCost < $1.totalCost }
    }
    
    func getMostActiveModel() -> String? {
        return modelBreakdown.max { $0.value.requestCount < $1.value.requestCount }?.key
    }
}