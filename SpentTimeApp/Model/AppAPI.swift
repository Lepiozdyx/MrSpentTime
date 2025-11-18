import Foundation
import SwiftUI
import Combine


enum JSONCoding {
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
}


enum DateStripper {
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    static func startOfWeek(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? startOfDay(date)
    }
    static func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? startOfDay(date)
    }
    static func days(from start: Date, to end: Date) -> [Date] {
        let cal = Calendar.current
        var days: [Date] = []
        var d = startOfDay(start)
        let e = startOfDay(end)
        while d <= e {
            days.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return days
    }
}


extension Color {
    init(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

struct HexColor: Codable, Hashable, Equatable {
    let hex: String
    var color: Color { Color(hexString: hex) }

    static let palette: [HexColor] = [
        HexColor(hex: "#FFD60A"), HexColor(hex: "#FF8C00"), HexColor(hex: "#0EA5E9"),
        HexColor(hex: "#22C55E"), HexColor(hex: "#A78BFA"), HexColor(hex: "#F43F5E"),
        HexColor(hex: "#F59E0B"), HexColor(hex: "#14B8A6"), HexColor(hex: "#94A3B8")
    ]

    static let gridPalette: [HexColor] = [
        HexColor(hex: "#E74C3C"), HexColor(hex: "#EB5A5A"), HexColor(hex: "#F06A3C"), HexColor(hex: "#F2994A"), HexColor(hex: "#F2C94C"),
        HexColor(hex: "#FFF59E"), HexColor(hex: "#B9F36C"), HexColor(hex: "#D9F67A"), HexColor(hex: "#7CF24B"), HexColor(hex: "#B8F5D2"),
        HexColor(hex: "#9AF6FF"), HexColor(hex: "#C8FBFF"), HexColor(hex: "#2155FF"), HexColor(hex: "#98A9FF"), HexColor(hex: "#7D3CFF"),
        HexColor(hex: "#A690FF"), HexColor(hex: "#9A00FF"), HexColor(hex: "#D9A7FF"), HexColor(hex: "#FF5EA8"), HexColor(hex: "#F6A0C1")
    ]
}

enum HomeTheme {
    static let background = Color(hexString: "#0C0C0C")
    static let navy       = Color(hexString: "#0E2656")
    static let yellow     = Color(hexString: "#FEBA07")
    static let white      = Color.white
    static let greyRing   = Color.white.opacity(0.35)
    static let cardStroke = Color(hexString: "#FFD60A")
    static let cardText   = Color.white
    static let secondary  = Color.white.opacity(0.75)
}

enum TimeOfDay: String, Codable, CaseIterable, Equatable, Hashable {
    case any = "Any", morning = "Morning", day = "Day", evening = "Evening", night = "Night"
    var symbol: String {
        switch self {
        case .any: return "🕒"
        case .morning: return "☀️"
        case .day: return "☀️"
        case .evening: return "🌆"
        case .night: return "🌙"
        }
    }
}

enum PresetSpheres {
    
    static let all: [LifeSphere] = [
        LifeSphere(name: "Social",    color: HexColor(hex: "#FF83A7")),
        LifeSphere(name: "Family",    color: HexColor(hex: "#FF8182")),
        LifeSphere(name: "Rest",      color: HexColor(hex: "#FE9B71")),
        LifeSphere(name: "Work",      color: HexColor(hex: "#9DAEFE")),
        LifeSphere(name: "Health",    color: HexColor(hex: "#82FFBB")),
        LifeSphere(name: "Commute",   color: HexColor(hex: "#35AD32")),
        LifeSphere(name: "Sleep",     color: HexColor(hex: "#3BE98A")),
        LifeSphere(name: "Self-Care", color: HexColor(hex: "#157DEC")),
        LifeSphere(name: "Learning",  color: HexColor(hex: "#0091BE"))
    ]
}

struct LifeSphere: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var color: HexColor
    var isFavorite: Bool
    init(id: UUID = UUID(), name: String, color: HexColor, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.isFavorite = isFavorite
    }
}

struct TimeEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var minutes: Int
    var sphereID: UUID
    var timeOfDay: TimeOfDay
    init(id: UUID = UUID(), date: Date, minutes: Int, sphereID: UUID, timeOfDay: TimeOfDay) {
        self.id = id
        self.date = DateStripper.startOfDay(date)
        self.minutes = max(1, minutes)
        self.sphereID = sphereID
        self.timeOfDay = timeOfDay
    }
}

enum AggregationRange: String, Codable, CaseIterable, Hashable {
    case day = "Day", week = "Week", month = "Month"
}

struct PieSlice: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let sphereID: UUID
    let totalMinutes: Int
    init(id: UUID = UUID(), sphereID: UUID, totalMinutes: Int) {
        self.id = id
        self.sphereID = sphereID
        self.totalMinutes = totalMinutes
    }
}


struct Tip: Identifiable, Codable, Equatable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case productivity = "Productivity"
        case healthyHabits = "Healthy Habits"
        case unhealthy = "Unhealthy Habits (and how to avoid)"
    }
    let id: UUID
    let kind: Kind
    let text: String
    init(id: UUID = UUID(), kind: Kind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}

enum TipsCatalog {
    static let productivity: [Tip] = [
        Tip(kind: .productivity, text: "Start your day with your most important task—before distractions kick in."),
        Tip(kind: .productivity, text: "Use the “2-minute rule”: if it takes ≤2 minutes, do it immediately."),
        Tip(kind: .productivity, text: "Take a break every 50–60 minutes (try the Pomodoro Technique)."),
        Tip(kind: .productivity, text: "Plan your day the night before—fewer decisions in the morning."),
        Tip(kind: .productivity, text: "Batch similar tasks (e.g., calls, emails) into dedicated blocks."),
        Tip(kind: .productivity, text: "Eliminate or defer tasks that don’t move you toward your goals."),
        Tip(kind: .productivity, text: "Keep your workspace tidy—it reduces mental clutter."),
        Tip(kind: .productivity, text: "Turn off notifications during deep work sessions."),
        Tip(kind: .productivity, text: "Use a timer to start—even 5 minutes of work builds momentum."),
        Tip(kind: .productivity, text: "Keep a “done list” instead of just a to-do list—it boosts motivation.")
    ]
    static let healthyHabits: [Tip] = [
        Tip(kind: .healthyHabits, text: "Drink a glass of water right after waking up."),
        Tip(kind: .healthyHabits, text: "Walk for at least 20 minutes daily—for body and mind."),
        Tip(kind: .healthyHabits, text: "Read 10 pages a day—knowledge compounds quietly."),
        Tip(kind: .healthyHabits, text: "Do 5 minutes of stretching or breathing exercises in the morning."),
        Tip(kind: .healthyHabits, text: "Write down 3 things you’re grateful for—it lifts your mood."),
        Tip(kind: .healthyHabits, text: "Eat slowly and away from screens—better digestion and portion control."),
        Tip(kind: .healthyHabits, text: "Go to bed and wake up at the same time daily—stabilizes your rhythm."),
        Tip(kind: .healthyHabits, text: "Say “no” politely but firmly—protect your time and energy."),
        Tip(kind: .healthyHabits, text: "Schedule a weekly digital detox (1–2 hours without screens)."),
        Tip(kind: .healthyHabits, text: "Hug someone you care about every day—it lowers stress.")
    ]
    static let unhealthy: [Tip] = [
        Tip(kind: .unhealthy, text: "Don’t check email or social media first thing in the morning—start with yourself."),
        Tip(kind: .unhealthy, text: "Avoid working in bed—it blurs the line between rest and activity."),
        Tip(kind: .unhealthy, text: "Don’t multitask—it reduces both quality and speed."),
        Tip(kind: .unhealthy, text: "Don’t sacrifice sleep for “just one more episode”—chronic sleep loss kills productivity."),
        Tip(kind: .unhealthy, text: "Avoid eating on the go or while staring at a screen—it leads to overeating."),
        Tip(kind: .unhealthy, text: "Stop comparing your day to curated Instagram lives—it’s an illusion."),
        Tip(kind: .unhealthy, text: "Don’t reply to work messages at night—boundaries matter."),
        Tip(kind: .unhealthy, text: "Keep your phone away during conversations—it shows respect and focus."),
        Tip(kind: .unhealthy, text: "Don’t use “I’m busy” as an excuse for procrastination."),
        Tip(kind: .unhealthy, text: "Don’t wait for the perfect moment—start small, start now.")
    ]
    static let all: [Tip] = productivity + healthyHabits + unhealthy
}


enum UDKeys {
    static let storeVersion = "mst.store.version"
    static let bundle       = "mst.appState.bundle"
}

struct AppState: Codable, Equatable {
    var spheres: [LifeSphere]
    var timeEntries: [TimeEntry]
    var version: Int
    init(spheres: [LifeSphere] = [], timeEntries: [TimeEntry] = [], version: Int = 1) {
        self.spheres = spheres
        self.timeEntries = timeEntries
        self.version = version
    }
}

final class DataStore: ObservableObject {
    @Published private(set) var state: AppState
    private var cancellables: Set<AnyCancellable> = []
    private let currentVersion: Int = 1

    init() {
        if let loaded = Self.loadFromUD() {
            self.state = Self.migrateIfNeeded(loaded, to: currentVersion)
        } else {
            self.state = AppState(version: currentVersion)
            Self.saveToUD(self.state)
        }
        $state
            .dropFirst()
            .sink { Self.saveToUD($0) }
            .store(in: &cancellables)
    }

    var spheres: [LifeSphere]    { state.spheres }
    var timeEntries: [TimeEntry] { state.timeEntries }
    var tips: [Tip]              { TipsCatalog.all }

    // CRUD — Spheres
    @discardableResult
    func addSphere(name: String, color: HexColor, isFavorite: Bool = false) -> LifeSphere {
        let s = LifeSphere(name: name, color: color, isFavorite: isFavorite)
        state.spheres.append(s)
        return s
    }
    func updateSphere(_ sphere: LifeSphere) {
        if let idx = state.spheres.firstIndex(where: { $0.id == sphere.id }) {
            state.spheres[idx] = sphere
        }
    }
    func deleteSphere(id: UUID) {
        state.spheres.removeAll { $0.id == id }
        state.timeEntries.removeAll { $0.sphereID == id } // каскад
    }

    @discardableResult
    func addTimeEntry(date: Date, minutes: Int, sphereID: UUID, timeOfDay: TimeOfDay) -> TimeEntry {
        let entry = TimeEntry(date: date, minutes: minutes, sphereID: sphereID, timeOfDay: timeOfDay)
        state.timeEntries.append(entry)
        return entry
    }
    func updateTimeEntry(_ entry: TimeEntry) {
        if let idx = state.timeEntries.firstIndex(where: { $0.id == entry.id }) {
            state.timeEntries[idx] = entry
        }
    }
    func deleteTimeEntry(id: UUID) {
        state.timeEntries.removeAll { $0.id == id }
    }

    func entries(on day: Date) -> [TimeEntry] {
        let d = DateStripper.startOfDay(day)
        return state.timeEntries.filter { $0.date == d }
    }
    func entries(from start: Date, to end: Date) -> [TimeEntry] {
        let a = DateStripper.startOfDay(start)
        let b = DateStripper.startOfDay(end)
        return state.timeEntries.filter { $0.date >= a && $0.date <= b }
    }
    func dominantSphere(on day: Date) -> LifeSphere? {
        let per = aggregateBySphere(on: day)
        guard let (sid, _) = per.max(by: { $0.value < $1.value }) else { return nil }
        return state.spheres.first(where: { $0.id == sid })
    }
    func aggregateBySphere(on day: Date) -> [UUID: Int] {
        var dict: [UUID: Int] = [:]
        for e in entries(on: day) { dict[e.sphereID, default: 0] += e.minutes }
        return dict
    }

    func pieData(for range: AggregationRange, refDate: Date = Date()) -> [PieSlice] {
        let list: [TimeEntry]
        switch range {
        case .day:
            list = entries(on: refDate)
        case .week:
            let s = DateStripper.startOfWeek(for: refDate)
            let e = Calendar.current.date(byAdding: .day, value: 6, to: s) ?? refDate
            list = entries(from: s, to: e)
        case .month:
            let s = DateStripper.startOfMonth(for: refDate)
            let e = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: s) ?? refDate
            list = entries(from: s, to: e)
        }
        return Dictionary(grouping: list, by: { $0.sphereID })
            .map { (id, arr) in PieSlice(sphereID: id, totalMinutes: arr.reduce(0) { $0 + $1.minutes }) }
            .filter { $0.totalMinutes > 0 }
    }

    func weekdayHistogram(for refDate: Date = Date()) -> [Int: Int] {
        let start = DateStripper.startOfWeek(for: refDate)
        let days = DateStripper.days(from: start, to: Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start)
        var hist: [Int: Int] = [:]
        for d in days {
            let w = Calendar.current.component(.weekday, from: d) // 1..7
            hist[w] = entries(on: d).reduce(0) { $0 + $1.minutes }
        }
        return hist
    }

    func isColorUsed(_ c: HexColor) -> Bool {
        state.spheres.contains { $0.color == c }
    }
    func availablePaletteColors(excludeUsed: Bool = true) -> [HexColor] {
        let all = HexColor.gridPalette
        guard excludeUsed else { return all }
        return all.filter { !isColorUsed($0) }
    }
    func nextPaletteColor() -> HexColor {
        availablePaletteColors().first ?? HexColor.gridPalette.first!
    }

    private static func saveToUD(_ state: AppState) {
        do {
            let data = try JSONCoding.encoder.encode(state)
            let ud = UserDefaults.standard
            ud.set(data, forKey: UDKeys.bundle)
            ud.set(state.version, forKey: UDKeys.storeVersion)
        } catch {
            assertionFailure("UserDefaults save error: \(error)")
        }
    }
    private static func loadFromUD() -> AppState? {
        guard let data = UserDefaults.standard.data(forKey: UDKeys.bundle) else { return nil }
        return try? JSONCoding.decoder.decode(AppState.self, from: data)
    }
    private static func migrateIfNeeded(_ state: AppState, to target: Int) -> AppState {
        var s = state
        if s.version < target {
            s.version = target
        }
        return s
    }
}


enum SphereFactory {
    static func createUniqueSphere(named name: String, color: HexColor, favorite: Bool, in store: DataStore) -> LifeSphere {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return store.addSphere(name: "Other", color: color, isFavorite: favorite)
        }
        if store.spheres.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            var i = 2
            var candidate = "\(trimmed) \(i)"
            while store.spheres.contains(where: { $0.name.caseInsensitiveCompare(candidate) == .orderedSame }) {
                i += 1
                candidate = "\(trimmed) \(i)"
            }
            return store.addSphere(name: candidate, color: color, isFavorite: favorite)
        } else {
            return store.addSphere(name: trimmed, color: color, isFavorite: favorite)
        }
    }
}


enum StatsEngine {
    static func totalMinutes(on day: Date, using store: DataStore) -> Int {
        store.entries(on: day).reduce(0) { $0 + $1.minutes }
    }
    static func totalMinutes(from start: Date, to end: Date, using store: DataStore) -> Int {
        store.entries(from: start, to: end).reduce(0) { $0 + $1.minutes }
    }
    static func totalMinutes(for sphereID: UUID, from start: Date, to end: Date, using store: DataStore) -> Int {
        store.entries(from: start, to: end)
            .filter { $0.sphereID == sphereID }
            .reduce(0) { $0 + $1.minutes }
    }
    static func percentage(for slice: PieSlice, in slices: [PieSlice]) -> Double {
        let total = slices.reduce(0) { $0 + $1.totalMinutes }
        guard total > 0 else { return 0 }
        return (Double(slice.totalMinutes) / Double(total)) * 100.0
    }
}

extension DataStore {
    func ensurePresetSpheresIfNeeded() {
        guard state.spheres.isEmpty else { return }
        state.spheres.append(contentsOf: PresetSpheres.all)
    }
}
