import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Typeboard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Waiting for hotkey…")
                .foregroundStyle(.secondary)
        }
        .frame(width: 420, height: 220)
    }
}

#Preview {
    ContentView()
}
