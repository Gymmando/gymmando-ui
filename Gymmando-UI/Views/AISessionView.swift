import SwiftUI
import AVFoundation
import LiveKit

struct AISessionView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var audioMonitor = AudioMonitor()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isConnecting = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main visualization area
                ZStack {
                    // Waveform behind mic
                    WaveformView(
                        audioLevel: max(audioMonitor.level, CGFloat(viewModel.liveKit.remoteAudioLevel)),
                        isActive: viewModel.liveKit.connected
                    )
                    .frame(height: 140)
                    .padding(.horizontal, 30)
                    
                    // Pulsing rings when active
                    if viewModel.liveKit.connected {
                        Circle()
                            .stroke(Color.green.opacity(0.4), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseScale)
                            .opacity(2 - pulseScale)
                            .animation(
                                .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: pulseScale
                            )
                        
                        Circle()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            .frame(width: 220, height: 220)
                            .scaleEffect(pulseScale * 0.9)
                            .opacity(2 - pulseScale)
                            .animation(
                                .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                                value: pulseScale
                            )
                    }
                    
                    // Mic icon
                    ZStack {
                        // Glow circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        viewModel.liveKit.connected ? Color.orange.opacity(0.5) : Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        
                        // Mic icon
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.5)
                        } else {
                            Image(systemName: viewModel.liveKit.connected ? "mic.fill" : "mic")
                                .font(.system(size: 100, weight: .medium))
                                .foregroundStyle(
                                    viewModel.liveKit.connected
                                        ? LinearGradient(colors: [.white, .orange], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: viewModel.liveKit.connected ? .orange.opacity(0.8) : .white.opacity(0.3), radius: 30)
                        }
                    }
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Status text
                Group {
                    if !viewModel.liveKit.connected {
                        Text("Connecting...")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                            .tracking(2)
                    } else if viewModel.liveKit.remoteAudioLevel > 0.1 {
                        Text("GYMMANDO SPEAKING")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .tracking(2)
                    } else if audioMonitor.level > 0.1 {
                        Text("YOU")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                            .tracking(2)
                    } else {
                        Text("LISTENING...")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)
                    }
                }
                .padding(.bottom, 20)
                
                // Bottom control bar
                HStack {
                    Spacer()
                    
                    // End Session button
                    Button(action: {
                        Task {
                            await endSession()
                        }
                    }) {
                        Text("End Session")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(Color.red)
                            .cornerRadius(25)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            pulseScale = 1.8
            Task {
                await startSession()
            }
        }
        .onDisappear {
            Task {
                await endSession()
            }
        }
    }
    
    private func startSession() async {
        isConnecting = true
        await viewModel.connect()
        if viewModel.liveKit.connected {
            audioMonitor.start()
        }
        isConnecting = false
    }
    
    private func endSession() async {
        audioMonitor.stop()
        await viewModel.liveKit.disconnect()
        dismiss()
    }
    
}

// MARK: - Waveform View (Histogram Style - Mirrored with Trail)
struct WaveformView: View {
    let audioLevel: CGFloat
    let isActive: Bool
    
    private let barCount = 12
    private let barSpacing: CGFloat = 8
    private let barCornerRadius: CGFloat = 4
    
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
                        barWidth: barWidth,
                        barCornerRadius: barCornerRadius
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
    let barCornerRadius: CGFloat
    
    @State private var trailLevel: CGFloat = 0
    @State private var currentHeight: CGFloat = 0
    
    var body: some View {
        let position = CGFloat(index) / CGFloat(barCount - 1)
        let envelope = sin(.pi * position) // 0 at edges, 1 at middle
        
        let baseHeight: CGFloat = 3
        let dynamicHeight = isActive ? audioLevel * halfHeight * 0.9 * envelope : 0
        let randomFactor = CGFloat(((index * 7 + 3) % 10)) / 10.0
        let targetSingleSideHeight = max(baseHeight, baseHeight + dynamicHeight + (isActive ? dynamicHeight * randomFactor * 0.3 : 0))
        
        let singleSideHeight = currentHeight
        let trailSideHeight = max(baseHeight, baseHeight + trailLevel * halfHeight * 0.9 * envelope)
        
        let totalHeight = singleSideHeight * 2
        let trailTotalHeight = trailSideHeight * 2
        
        let baseOpacity: CGFloat = 0.2
        let audioOpacity = isActive ? audioLevel * 0.8 : 0
        let edgeFade = envelope
        let finalOpacity = min(1.0, baseOpacity + audioOpacity * edgeFade)
        let trailOpacity = min(0.4, 0.1 + trailLevel * 0.3 * edgeFade)
        
        ZStack {
            // Trail (behind)
            RoundedRectangle(cornerRadius: barCornerRadius)
                .fill(Color.green.opacity(0.6))
                .frame(width: barWidth, height: trailTotalHeight)
                .opacity(trailOpacity)
                .blur(radius: 3)
                .shadow(color: Color.green.opacity(0.5 * trailOpacity), radius: 5)
            
            // Main bar (front)
            RoundedRectangle(cornerRadius: barCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [.green, .cyan, .green],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: barWidth, height: totalHeight)
                .opacity(finalOpacity)
                .shadow(color: Color.cyan.opacity(0.8 * finalOpacity), radius: 6)
                .shadow(color: Color.green.opacity(0.8 * finalOpacity), radius: 6)
        }
        .animation(.easeInOut(duration: 0.12), value: currentHeight)
        .animation(.easeOut(duration: 0.25), value: trailLevel)
        .onChange(of: audioLevel) { newValue in
            currentHeight = targetSingleSideHeight
            
            if newValue > trailLevel {
                trailLevel = newValue
            } else {
                trailLevel = trailLevel * 0.9
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
                self?.level = CGFloat(min(avg * 10, 1.0))
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

