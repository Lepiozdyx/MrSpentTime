import SwiftUI

struct AddActivityView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    
    @State private var selectedSphereID: UUID?
    @State private var durationMinutes: Int = 60
    @State private var timeOfDay: TimeOfDay = .any
    @State private var showAddSphere = false
    
    private let circleSize: CGFloat = 72
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomNavBar(
                    title: "Add Activity",
                    left: {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.white)
                        }
                    },
                    right: {
                        EmptyView()
                    }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        spheresGrid
                            .padding(.top, 20)
                        
                        separator
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.osBold(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(.white)
                            
                            Text(formattedTime(durationMinutes))
                                .font(.osRegular(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(.white)
                                .monospacedDigit()
                            
                            HStack(spacing: 14) {
                                durationButton("-15") {
                                    let newValue = max(1, durationMinutes - 15)
                                    durationMinutes = newValue
                                }
                                durationButton("+15") {
                                    let newValue = min(24 * 60, durationMinutes + 15)
                                    durationMinutes = newValue
                                }
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                        
                        separator
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Time of Day")
                                .font(.osBold(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 16) {
                                timeOfDayPill(.morning, label: "Morning")
                                timeOfDayPill(.day,      label: "Day")
                                timeOfDayPill(.evening,  label: "Evening")
                                timeOfDayPill(.night,    label: "Night")
                            }
                        }
                        
                        Spacer(minLength: 24)
                        
                        Button {
                            save()
                        } label: {
                            Text("Save")
                                .font(.osBold(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(HomeTheme.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                                        .fill(HomeTheme.yellow)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showAddSphere) {
            AddSphereView()
                .environmentObject(store)
        }
        .onAppear {
            store.ensurePresetSpheresIfNeeded()
            if selectedSphereID == nil {
                selectedSphereID = store.spheres.first?.id
            }
        }
    }
    
    func save() {
        guard let sphereID = selectedSphereID ?? store.spheres.first?.id else {
            return
        }
        
        let clampedMinutes = max(1, min(durationMinutes, 24 * 60))
        let period = timeOfDay
        
        store.addTimeEntry(
            date: date,
            minutes: clampedMinutes,
            sphereID: sphereID,
            timeOfDay: period
        )
        
        dismiss()
    }
}


extension AddActivityView {
    
    private var spheresGrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
            
            LazyVGrid(columns: columns, alignment: .center, spacing: 18) {
                ForEach(store.spheres) { sphere in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(sphere.color.color)
                                .frame(width: circleSize, height: circleSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                            
                            if selectedSphereID == sphere.id {
                                Image("choose")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: circleSize - 24, height: circleSize - 24)
                                    .allowsHitTesting(false)
                            }
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedSphereID = sphere.id
                        }
                        
                        Text(sphere.name)
                            .font(.osRegular(16))
                            .disableDynamicTypeScaling()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: circleSize + 6)
                    }
                }
                
                VStack(spacing: 6) {
                    Button {
                        showAddSphere = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(HomeTheme.yellow)
                                .frame(width: circleSize, height: circleSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .foregroundStyle(HomeTheme.navy)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Add")
                        .font(.osRegular(16))
                        .disableDynamicTypeScaling()
                        .foregroundStyle(.white)
                        .frame(maxWidth: circleSize + 6)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(HomeTheme.yellow.opacity(0.9))
            .frame(height: onePixel)
            .padding(.vertical, 6)
    }
    
    private func durationButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.osBold(18))
                .disableDynamicTypeScaling()
                .foregroundStyle(HomeTheme.yellow)
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(HomeTheme.yellow, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func timeOfDayPill(_ value: TimeOfDay, label: String) -> some View {
        let isSelected = (timeOfDay == value)
        return Button {
            timeOfDay = value
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .strokeBorder(HomeTheme.yellow, lineWidth: 2)
                    .background(
                        Circle().fill(isSelected ? HomeTheme.yellow : Color.clear)
                    )
                    .frame(width: 22, height: 22)
                Text(label)
                    .font(.osRegular(16))
                    .disableDynamicTypeScaling()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formattedTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
    
    private var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
}

struct AddSphereView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedColor: HexColor = HexColor.gridPalette.first!
    
    private let circleSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomNavBar(
                    title: "New Category",
                    left: {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.white)
                        }
                    },
                    right: { EmptyView() }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(HexColor.gridPalette, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: circleSize, height: circleSize)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                            .shadow(color: .black.opacity(0.35),
                                                    radius: 5, x: 0, y: 3)
                                        
                                        if selectedColor == color {
                                            Image("choose")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: circleSize - 18,
                                                       height: circleSize - 18)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 12)
                        
                        Rectangle()
                            .fill(HomeTheme.yellow)
                            .frame(height: onePixel)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.osBold(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(.white)
                            
                            TextField("Shopping", text: $name)
                                .font(.osRegular(24))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(.white)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.words)
                            
                            Rectangle()
                                .fill(HomeTheme.yellow)
                                .frame(height: onePixel)
                        }
                        
                        Spacer(minLength: 28)
                        
                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            
                            _ = SphereFactory.createUniqueSphere(
                                named: trimmed,
                                color: selectedColor,
                                favorite: false,
                                in: store
                            )
                            dismiss()
                        } label: {
                            Text("Save")
                                .font(.osBold(26))
                                .disableDynamicTypeScaling()
                                .foregroundStyle(HomeTheme.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(HomeTheme.yellow)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                }
            }
        }
    }
    
    private var onePixel: CGFloat {
        1.0 / (UIScreen.main.scale == 0 ? 2.0 : UIScreen.main.scale)
    }
}

#Preview {
    AddActivityView(date: Date())
        .environmentObject(DataStore())
}
