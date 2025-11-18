
import SwiftUI

struct FavoritesScreen: View {
    @EnvironmentObject private var store: DataStore
    
    @State private var selectedSphereID: UUID? = nil
    @State private var showAddSphere = false
    
    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 18),
        count: 4
    )
    
    private let circleSize: CGFloat = 72
    
    var body: some View {
        ZStack {
            HomeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                CustomNavBar(
                    title: "Favorites",
                    left: { EmptyView() },
                    right: { EmptyView() }
                )
                .disableDynamicTypeScaling()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        LazyVGrid(columns: columns, alignment: .center, spacing: 22) {
                            // показываем все сферы, которые есть в store
                            ForEach(store.spheres) { sphere in
                                FavoritesCircleItem(
                                    title: sphere.name,
                                    color: sphere.color.color,
                                    isSelected: selectedSphereID == sphere.id,
                                    circleSize: circleSize
                                ) {
                                    selectedSphereID = sphere.id
                                }
                            }
                            
                            // круг "Add" с плюсом
                            FavoritesAddCircleItem(circleSize: circleSize) {
                                showAddSphere = true
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .onAppear {
            store.ensurePresetSpheresIfNeeded()
            if selectedSphereID == nil {
                selectedSphereID = store.spheres.first?.id
            }
        }
        .navigationDestination(isPresented: $showAddSphere) {
            AddSphereView()
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
    }
}


private struct FavoritesCircleItem: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let circleSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                    
                    if isSelected {
                        Image("choose")
                            .resizable()
                            .scaledToFit()
                            .frame(width: circleSize - 24, height: circleSize - 24)
                            .allowsHitTesting(false)
                    }
                }
                
                Text(title)
                    .font(.osRegular(16))
                    .foregroundStyle(HomeTheme.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: circleSize + 4)
                    .disableDynamicTypeScaling()
            }
        }
        .buttonStyle(.plain)
    }
}


private struct FavoritesAddCircleItem: View {
    let circleSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
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
                
                Text("Add")
                    .font(.osRegular(16))
                    .foregroundStyle(HomeTheme.white)
                    .frame(maxWidth: circleSize + 4)
                    .disableDynamicTypeScaling()
            }
        }
        .buttonStyle(.plain)
    }
}
