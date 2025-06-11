import SwiftUI
import Charts

// MARK: - Performance Dashboard View
struct PerformanceDashboardView: View {
    @StateObject private var dashboard = PerformanceDashboard.shared
    @StateObject private var moduleManager = ModuleManager.shared
    @State private var selectedTimeRange: TimeRange = .last30Minutes
    @State private var showingAlerts = false
    @State private var showingExportSheet = false
    
    enum TimeRange: String, CaseIterable {
        case last10Minutes = "10m"
        case last30Minutes = "30m"
        case lastHour = "1h"
        case last6Hours = "6h"
        case last24Hours = "24h"
        
        var duration: TimeInterval {
            switch self {
            case .last10Minutes: return 10 * 60
            case .last30Minutes: return 30 * 60
            case .lastHour: return 60 * 60
            case .last6Hours: return 6 * 60 * 60
            case .last24Hours: return 24 * 60 * 60
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Performance Score Card
                    performanceScoreCard
                    
                    // System Metrics Grid
                    systemMetricsGrid
                    
                    // Performance Charts
                    performanceChartsSection
                    
                    // Module Health Section
                    moduleHealthSection
                    
                    // Active Alerts Section
                    if !dashboard.alerts.isEmpty {
                        alertsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Performance Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        if dashboard.isMonitoring {
                            dashboard.stopMonitoring()
                        } else {
                            dashboard.startMonitoring()
                        }
                    }) {
                        Image(systemName: dashboard.isMonitoring ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(dashboard.isMonitoring ? .orange : .green)
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("System Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(dashboard.systemMetrics.lastUpdate.formatted(.dateTime.hour().minute().second()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Monitoring Status
                HStack {
                    Circle()
                        .fill(dashboard.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(dashboard.isMonitoring ? "Monitoring" : "Stopped")
                        .font(.caption)
                        .foregroundColor(dashboard.isMonitoring ? .green : .secondary)
                }
            }
            
            // Time Range Selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Performance Score Card
    private var performanceScoreCard: some View {
        Group {
            if let latestSnapshot = dashboard.performanceHistory.last {
                VStack(spacing: 16) {
                    // Overall Score
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Performance Score")
                                .font(.headline)
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text(latestSnapshot.score.grade.rawValue)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(latestSnapshot.score.grade.color)
                                
                                VStack(alignment: .leading) {
                                    Text("\(Int(latestSnapshot.score.overall))/100")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Text(getScoreDescription(latestSnapshot.score.grade))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Score Breakdown
                        VStack(alignment: .trailing, spacing: 4) {
                            scoreBreakdownRow("Memory", score: latestSnapshot.score.memory)
                            scoreBreakdownRow("Network", score: latestSnapshot.score.network)
                            scoreBreakdownRow("UI", score: latestSnapshot.score.ui)
                            scoreBreakdownRow("Stability", score: latestSnapshot.score.stability)
                        }
                    }
                    
                    // Progress Bars
                    VStack(spacing: 8) {
                        performanceProgressBar("Memory", score: latestSnapshot.score.memory)
                        performanceProgressBar("Network", score: latestSnapshot.score.network)
                        performanceProgressBar("UI", score: latestSnapshot.score.ui)
                        performanceProgressBar("Stability", score: latestSnapshot.score.stability)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            } else {
                Text("No performance data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // MARK: - System Metrics Grid
    private var systemMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            // Memory Usage
            metricCard(
                title: "Memory Usage",
                value: "\(dashboard.systemMetrics.memoryUsage.used / (1024 * 1024))MB",
                subtitle: "Peak: \(dashboard.systemMetrics.memoryUsage.peak / (1024 * 1024))MB",
                color: memoryPressureColor(dashboard.systemMetrics.memoryUsage.pressureLevel),
                icon: "memorychip"
            )
            
            // Network Requests
            metricCard(
                title: "Network Success",
                value: "\(String(format: "%.1f", dashboard.systemMetrics.networkMetrics.successRate))%",
                subtitle: "\(dashboard.systemMetrics.networkMetrics.requestCount) requests",
                color: dashboard.systemMetrics.networkMetrics.successRate > 95 ? .green : .orange,
                icon: "network"
            )
            
            // Frame Rate
            metricCard(
                title: "Frame Rate",
                value: "\(Int(dashboard.systemMetrics.uiMetrics.frameRate))fps",
                subtitle: "\(dashboard.systemMetrics.uiMetrics.frameDrops) drops",
                color: dashboard.systemMetrics.uiMetrics.frameRate >= 55 ? .green : .orange,
                icon: "speedometer"
            )
            
            // Response Time
            metricCard(
                title: "Response Time",
                value: "\(Int(dashboard.systemMetrics.networkMetrics.averageResponseTime * 1000))ms",
                subtitle: "Average",
                color: dashboard.systemMetrics.networkMetrics.averageResponseTime < 1.0 ? .green : .orange,
                icon: "timer"
            )
        }
    }
    
    // MARK: - Performance Charts
    private var performanceChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.headline)
                .padding(.horizontal)
            
            if #available(iOS 16.0, *) {
                performanceChart
                    .frame(height: 200)
                    .padding(.horizontal)
            } else {
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    @available(iOS 16.0, *)
    private var performanceChart: some View {
        Chart {
            ForEach(filteredPerformanceHistory, id: \.timestamp) { snapshot in
                LineMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Score", snapshot.score.overall)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Score", snapshot.score.overall)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    // MARK: - Module Health Section
    private var moduleHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Module Health")
                .font(.headline)
            
            if moduleManager.modules.isEmpty {
                Text("No modules loaded")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(moduleManager.moduleHealth.keys), id: \.self) { moduleId in
                    if let health = moduleManager.moduleHealth[moduleId],
                       let module = moduleManager.modules[moduleId] {
                        moduleHealthRow(module: module, health: health)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Alerts Section
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Alerts")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear All") {
                    dashboard.clearAlerts()
                }
                .foregroundColor(.blue)
            }
            
            ForEach(dashboard.alerts.prefix(5)) { alert in
                alertRow(alert)
            }
            
            if dashboard.alerts.count > 5 {
                Button("View All \(dashboard.alerts.count) Alerts") {
                    showingAlerts = true
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Export Sheet
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Performance Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(dashboard.getPerformanceReport())
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Share Report") {
                    // Implement sharing functionality
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getScoreDescription(_ grade: PerformanceDashboard.PerformanceScore.Grade) -> String {
        switch grade {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .critical: return "Critical"
        }
    }
    
    private func scoreBreakdownRow(_ title: String, score: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(score))")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func performanceProgressBar(_ title: String, score: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                
                Spacer()
                
                Text("\(Int(score))/100")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: score, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: progressBarColor(score)))
        }
    }
    
    private func progressBarColor(_ score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func memoryPressureColor(_ pressure: PerformanceDashboard.MemoryMetrics.MemoryPressure) -> Color {
        switch pressure {
        case .normal: return .green
        case .warning: return .yellow
        case .urgent: return .orange
        case .critical: return .red
        }
    }
    
    private func moduleHealthRow(module: any FeatureModule, health: ModuleHealth) -> some View {
        HStack {
            Circle()
                .fill(healthStatusColor(health.status))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(module.moduleId)
                    .font(.headline)
                
                Text("v\(module.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(healthStatusText(health.status))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(healthStatusColor(health.status))
                
                Text("\(health.metrics.memoryUsage / (1024 * 1024))MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func healthStatusColor(_ status: ModuleHealth.HealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
    
    private func healthStatusText(_ status: ModuleHealth.HealthStatus) -> String {
        switch status {
        case .healthy: return "Healthy"
        case .warning: return "Warning"
        case .critical: return "Critical"
        case .unknown: return "Unknown"
        }
    }
    
    private func alertRow(_ alert: PerformanceDashboard.PerformanceAlert) -> some View {
        HStack {
            Image(systemName: alertIcon(alert.severity))
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading) {
                Text(alert.title)
                    .font(.headline)
                
                Text(alert.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func alertIcon(_ severity: PerformanceDashboard.PerformanceAlert.Severity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    private var filteredPerformanceHistory: [PerformanceDashboard.PerformanceSnapshot] {
        let cutoffTime = Date().addingTimeInterval(-selectedTimeRange.duration)
        return dashboard.performanceHistory.filter { $0.timestamp >= cutoffTime }
    }
} 