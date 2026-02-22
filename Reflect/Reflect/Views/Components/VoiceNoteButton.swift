import SwiftUI
import AVFoundation

/// A button that records and plays back voice notes using AVAudioRecorder/Player.
struct VoiceNoteButton: View {
    @Binding var voiceNotePath: String?
    @StateObject private var recorder = VoiceNoteRecorder()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.checkInVoiceNote)
                .font(AppFont.callout)
                .foregroundColor(AppColor.label)

            HStack(spacing: Spacing.md) {
                // Record button
                Button(action: toggleRecording) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                            .foregroundColor(recorder.isRecording ? AppColor.danger : AppColor.primary)
                        Text(recorder.isRecording ? "Stop" : "Record")
                            .font(AppFont.callout)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColor.secondaryBackground)
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)

                // Play button (if recording exists)
                if voiceNotePath != nil {
                    Button(action: togglePlayback) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: recorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppColor.primary)
                            Text(recorder.isPlaying ? "Pause" : "Play")
                                .font(AppFont.callout)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColor.secondaryBackground)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .buttonStyle(.plain)

                    // Delete recording
                    Button(action: deleteRecording) {
                        Image(systemName: "trash")
                            .foregroundColor(AppColor.danger)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Duration display
                if recorder.isRecording {
                    Text(recorder.formattedDuration)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.danger)
                        .monospacedDigit()
                }
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
            voiceNotePath = recorder.currentFilePath
        } else {
            recorder.startRecording()
        }
    }

    private func togglePlayback() {
        guard let path = voiceNotePath else { return }
        if recorder.isPlaying {
            recorder.stopPlayback()
        } else {
            recorder.startPlayback(path: path)
        }
    }

    private func deleteRecording() {
        if let path = voiceNotePath {
            recorder.deleteRecording(path: path)
        }
        voiceNotePath = nil
    }
}

// MARK: - Voice Note Recorder

@MainActor
final class VoiceNoteRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    @Published var currentFilePath: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let filename = "voice_\(UUID().uuidString).m4a"
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDir.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            currentFilePath = fileURL.path
            duration = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.duration += 1
                }
            }
        } catch {
            // Recording failed — degrade gracefully
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
    }

    func startPlayback(path: String) {
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            // Playback failed
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func deleteRecording(path: String) {
        stopPlayback()
        try? FileManager.default.removeItem(atPath: path)
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceNoteRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
