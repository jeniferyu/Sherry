import SwiftUI

struct RoadMapView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Image("map")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .navigationTitle("Prayer Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    RoadMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
