import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var userName: String = ""
    @State private var showAISession = false
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with title and greeting
                VStack(spacing: 8) {
                    Text("Gymmando")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !userName.isEmpty {
                        Text("Ready, \(userName)?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    } else {
                        Text("Ready?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Main content cards
                VStack(spacing: 20) {
                    // Start AI Session Card (Large)
                    Button(action: {
                        showAISession = true
                    }) {
                        VStack(spacing: 20) {
                            // Mic icon and waveform
                            ZStack {
                                // Simple waveform bars (animated)
                                WaveformBarsView()
                                
                                // Mic icon
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                            }
                            .frame(height: 60)
                            
                            // Button text
                            Text("Start AI Session")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(white: 0.15))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadUserName()
        }
        .fullScreenCover(isPresented: $showAISession) {
            AISessionView()
        }
    }
    
    private func loadUserName() {
        if let user = Auth.auth().currentUser {
            userName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? ""
        }
    }
}

// Simple animated waveform bars
struct WaveformBarsView: View {
    @State private var heights: [CGFloat] = [20, 30, 25, 35, 28, 32, 24, 30]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4, height: heights[index])
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: heights[index]
                    )
            }
        }
        .onAppear {
            // Animate heights
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                withAnimation {
                    for i in 0..<heights.count {
                        heights[i] = CGFloat.random(in: 20...40)
                    }
                }
            }
        }
    }
}
