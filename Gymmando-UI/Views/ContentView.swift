import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var errorMessage: String = ""
    @State private var isConnecting = false  // ADD THIS LINE
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .font(.system(size: 60))
            
            Text("Gymmando")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Gym Bro Assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if viewModel.liveKit.connected {
                Text("🟢 Connected")
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            } else {
                Text("⚪️ Disconnected")
                    .foregroundColor(.gray)
            }
            
            if !errorMessage.isEmpty {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                errorMessage = ""
                Task {
                    if viewModel.liveKit.connected {
                        isConnecting = true
                        await viewModel.liveKit.disconnect()
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        isConnecting = false
                    } else {
                        isConnecting = true
                        await viewModel.connect()
                        isConnecting = false
                    }
                }
            }) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isConnecting ? "Processing..." : (viewModel.liveKit.connected ? "Disconnect" : "Connect"))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.liveKit.connected ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .disabled(isConnecting)
            .padding(.horizontal)
        }
        .padding()
        .onDisappear {
            Task {
                await viewModel.liveKit.disconnect()
            }
        }
    }
}
