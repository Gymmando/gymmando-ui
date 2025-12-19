import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var audioMonitor = AudioMonitor()
    @State private var isConnecting = false
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            // Bokeh particles
            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { i in
                    Circle()
                        .fill(Color.cyan.opacity(0.08))
                        .frame(width: CGFloat(30 + (i * 7) % 50))
                        .position(
                            x: CGFloat(20 + (i * 47) % Int(geo.size.width)),
                            y: CGFloat(50 + (i * 83) % Int(geo.size.height))
                        )
                        .blur(radius: 15)
                }
            }
            
            VStack {
                Spacer()
                
                // Waveform behind mic
                ZStack {
                    // Standing wave - combines your voice and AI voice
                    WaveformView(
                        audioLevel: max(audioMonitor.level, CGFloat(viewModel.liveKit.remoteAudioLevel)),
                        isActive: viewModel.liveKit.connected
                    )
                    .frame(height: 120)
                    .padding(.horizontal, 40)
                    
                    // Mic button
                    Button(action: {
                        Task {
                            if viewModel.liveKit.connected {
                                isConnecting = true
                                audioMonitor.stop()
                                await viewModel.liveKit.disconnect()
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                isConnecting = false
                            } else {
                                isConnecting = true
                                await viewModel.connect()
                                if viewModel.liveKit.connected {
                                    audioMonitor.start()
                                }
                                isConnecting = false
                            }
                        }
                    }) {
                        ZStack {
                            // Glow circle
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            viewModel.liveKit.connected ? Color.cyan.opacity(0.4) : Color.gray.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 200, height: 200)
                            
                            // Mic icon
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                    .scaleEffect(2)
                            } else {
                                Image(systemName: viewModel.liveKit.connected ? "mic.fill" : "mic")
                                    .font(.system(size: 100, weight: .medium))
                                    .foregroundStyle(
                                        viewModel.liveKit.connected
                                            ? LinearGradient(colors: [.cyan, .white], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [.gray, .white.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .shadow(color: viewModel.liveKit.connected ? .cyan.opacity(0.6) : .clear, radius: 20)
                            }
                        }
                    }
                    .disabled(isConnecting)
                }
                
                Spacer()
                
                // Status text
                VStack(spacing: 4) {
                    if !viewModel.liveKit.connected {
                        Text("Tap to start")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    } else if viewModel.liveKit.remoteAudioLevel > 0.1 {
                        Text("Gymmando")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.purple)
                    } else if audioMonitor.level > 0.1 {
                        Text("You")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                    } else {
                        Text("Listening...")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.6))
                    }
                }
                .padding(.bottom, 60)
                .animation(.easeInOut(duration: 0.2), value: audioMonitor.level > 0.1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.liveKit.remoteAudioLevel > 0.1)
            }
        }
        .onDisappear {
            audioMonitor.stop()
            Task {
                await viewModel.liveKit.disconnect()
            }
        }
    }
}

// MARK: - Waveform View (Histogram Style - Mirrored with Trail)
struct WaveformView: View {
    let audioLevel: CGFloat
    let isActive: Bool
    
    private let barCount = 20
    private let barSpacing: CGFloat = 4
    
    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(barCount - 1) * barSpacing) / CGFloat(barCount)
            let halfHeight = geo.size.height / 2
            
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    BarWithTrailView(
                        index: index,
                        barCount: barCount,
                        audioLevel: audioLevel,
                        isActive: isActive,
                        halfHeight: halfHeight,
                        barWidth: barWidth
                    )
                }
            }
            .frame(height: geo.size.height)
        }
    }
}

struct BarWithTrailView: View {
    let index: Int
    let barCount: Int
    let audioLevel: CGFloat
    let isActive: Bool
    let halfHeight: CGFloat
    let barWidth: CGFloat
    
    @State private var trailLevel: CGFloat = 0
    
    var body: some View {
        // Envelope: edges are short, middle is tall
        let position = CGFloat(index) / CGFloat(barCount - 1)
        let envelope = sin(.pi * position)
        
        // Base height + audio-reactive height (for one side)
        let baseHeight: CGFloat = 2
        let dynamicHeight = isActive ? audioLevel * halfHeight * 0.85 * envelope : 0
        
        // Add slight randomness per bar for organic feel
        let randomFactor = CGFloat(((index * 7 + 3) % 10)) / 12.0
        let singleSideHeight = max(baseHeight, baseHeight + dynamicHeight + (isActive ? dynamicHeight * randomFactor : 0))
        
        // Trail height (slower decay)
        let trailSideHeight = max(baseHeight, baseHeight + trailLevel * halfHeight * 0.85 * envelope)
        
        // Total height is double (mirrored up and down)
        let totalHeight = singleSideHeight * 2
        let trailTotalHeight = trailSideHeight * 2
        
        // Opacity: edges fade more, center stays brighter
        let baseOpacity: CGFloat = 0.3
        let audioOpacity = isActive ? audioLevel * 0.7 : 0
        let edgeFade = envelope
        let finalOpacity = min(1.0, baseOpacity + audioOpacity * edgeFade)
        
        let trailOpacity = min(0.5, 0.1 + trailLevel * 0.4 * edgeFade)
        
        ZStack {
            // Trail (behind)
            Rectangle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: barWidth, height: trailTotalHeight)
                .opacity(trailOpacity)
                .blur(radius: 2)
            
            // Main bar (front)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .cyan, .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: barWidth, height: totalHeight)
                .opacity(finalOpacity)
                .shadow(color: .cyan.opacity(0.5 * finalOpacity), radius: 3)
        }
        .animation(.easeInOut(duration: 0.12), value: audioLevel)
        .animation(.easeOut(duration: 0.25), value: trailLevel)
        .onChange(of: audioLevel) { newValue in
            // Update trail - it follows but decays slower
            if newValue > trailLevel {
                trailLevel = newValue
            } else {
                trailLevel = trailLevel * 0.92 // Smooth decay
            }
        }
    }
}

// MARK: - Audio Monitor
class AudioMonitor: ObservableObject {
    @Published var level: CGFloat = 0
    
    private var audioEngine: AVAudioEngine?
    
    func start() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = buffer.frameLength
            
            var sum: Float = 0
            for i in 0..<Int(frames) {
                sum += abs(channelData[i])
            }
            let avg = sum / Float(frames)
            
            DispatchQueue.main.async {
                self?.level = CGFloat(min(avg * 8, 1.0))
            }
        }
        
        do {
            try engine.start()
            self.audioEngine = engine
        } catch {
            print("Audio engine error: \(error)")
        }
    }
    
    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        level = 0
    }
}
