import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Shivaji Arc Vertical Slice") {
                    NavigationLink("Scene 1, Shivneri") {
                        Text("Scene 1 placeholder")
                    }
                    NavigationLink("Scene 2, Torna and Rajgad") {
                        Text("Scene 2 placeholder")
                    }
                    NavigationLink("Fort Map Learning") {
                        Text("Map learning placeholder")
                    }
                    NavigationLink("Royal Chronicle") {
                        Text("Royal Chronicle placeholder")
                    }
                }
            }
            .navigationTitle("Greats of Bharatha")
        }
    }
}
