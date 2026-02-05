import SwiftUI
import SilenceKit
import AVFoundation

struct ContentView: View {
    @StateObject private var processor = AudioProcessor()
    @State private var selectedFile: URL?
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // File Selection
                fileSelectionSection
                
                if selectedFile != nil {
                    // Playback Controls
                    playbackSection
                    
                    // Effects Controls
                    effectsSection
                    
                    // Stats
                    statsSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Audio Demo")
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker(selectedURL: $selectedFile)
            }
            .onChange(of: selectedFile) { _, url in
                if let url = url {
                    loadFile(url)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Sections
    
    private var fileSelectionSection: some View {
        VStack(spacing: 12) {
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(selectedFile?.lastPathComponent ?? "Select Audio File")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            if selectedFile != nil {
                Text("Duration: \(formatTime(processor.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var playbackSection: some View {
        VStack(spacing: 16) {
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: processor.currentTime, total: max(processor.duration, 1))
                    .tint(.blue)
                
                HStack {
                    Text(formatTime(processor.currentTime))
                    Spacer()
                    Text(formatTime(processor.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            // Controls
            HStack(spacing: 32) {
                Button {
                    processor.seek(to: max(0, processor.currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                
                Button {
                    if processor.isPlaying {
                        processor.pause()
                    } else {
                        processor.play()
                    }
                } label: {
                    Image(systemName: processor.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                
                Button {
                    processor.seek(to: min(processor.duration, processor.currentTime + 30))
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Effects")
                .font(.headline)
            
            // Trim Silence
            VStack(alignment: .leading, spacing: 8) {
                Text("Trim Silence")
                    .font(.subheadline)
                
                Picker("Trim Silence", selection: $processor.trimSilenceLevel) {
                    ForEach(TrimSilenceLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Playback Speed
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1fx", processor.playbackSpeed))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $processor.playbackSpeed, in: 0.5...3.0, step: 0.1)
            }
            
            // Volume Boost
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume Boost")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1fx", processor.volumeBoost))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $processor.volumeBoost, in: 0.5...2.0, step: 0.1)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.headline)
            
            HStack {
                Label("Time saved by trimming:", systemImage: "clock.badge.checkmark")
                Spacer()
                Text(formatTime(processor.timeSavedByTrimming))
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    
    private func loadFile(_ url: URL) {
        do {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Copy to temp directory for processing
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            try processor.loadFile(url: tempURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .mp3, .wav, .mpeg4Audio])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURL = urls.first
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
