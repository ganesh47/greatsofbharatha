import AVFoundation
import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Shared read-aloud controller. Visible lesson text is always the fallback for unavailable audio.
@MainActor
final class GBNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = GBNarrator()
    private static weak var speakingNarrator: GBNarrator?
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var activeCardID: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var isPaused = false
    private var lastRequest: (id: String, text: String)?
    private var activeUtteranceID: ObjectIdentifier?
    private var notificationSubscriptions: Set<AnyCancellable> = []

    override init() {
        super.init()
        synthesizer.delegate = self
#if os(iOS) || os(tvOS)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.stop() } }
            .store(in: &notificationSubscriptions)
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    if UIAccessibility.isVoiceOverRunning { self?.stop() }
                }
            }.store(in: &notificationSubscriptions)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                let interruption = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                guard interruption == AVAudioSession.InterruptionType.began.rawValue else { return }
                Task { @MainActor in
                    self?.stop()
                    self?.statusMessage = "Reading paused. Select Read aloud to hear it again."
                }
            }.store(in: &notificationSubscriptions)
#endif
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish(utteranceID: ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish(utteranceID: ObjectIdentifier(utterance))
    }

    private nonisolated func finish(utteranceID: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, activeUtteranceID == utteranceID else { return }
            activeUtteranceID = nil
            activeCardID = nil
            isPaused = false
        }
    }

    /// Existing iOS read-aloud buttons keep their start/stop behavior.
    func toggle(cardID: String, text: String) {
        if activeCardID == cardID { stop() } else { speak(id: cardID, text: text) }
    }

    /// Register the visible text for remote playback without starting speech.
    func setCurrent(id: String, text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            clearCurrent()
            return
        }
        guard lastRequest?.id != id || lastRequest?.text != trimmedText else { return }
        stop()
        lastRequest = (id: id, text: trimmedText)
        statusMessage = nil
    }

    /// Navigation clears the replay request; an explicit Stop button keeps it available.
    func clearCurrent() {
        stop()
        lastRequest = nil
        statusMessage = nil
    }

    /// The Siri Remote Play/Pause button pauses the active utterance, or replays the last request.
    func togglePlayback() {
        if isPaused {
            if synthesizer.continueSpeaking() { isPaused = false }
        } else if synthesizer.isSpeaking {
            if synthesizer.pauseSpeaking(at: .word) { isPaused = true }
        } else {
            repeatLast()
        }
    }

    func speak(id: String, text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            statusMessage = "Nothing to read aloud yet."
            stop()
            return
        }
        lastRequest = (id: id, text: trimmedText)
        Self.speakingNarrator?.stop()
        stop()
#if os(iOS) || os(tvOS)
        guard !UIAccessibility.isVoiceOverRunning else {
            statusMessage = "VoiceOver reads the lesson text."
            return
        }
#endif
        do {
            try prepareAudioSessionForSpeech()
            statusMessage = nil
        } catch {
            statusMessage = "Narration is unavailable. Check volume and try again."
            return
        }

        let utterance = AVSpeechUtterance(string: trimmedText)
        utterance.rate = AVSpeechUtteranceMinimumSpeechRate
            + (AVSpeechUtteranceDefaultSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * 0.70
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        activeUtteranceID = ObjectIdentifier(utterance)
        activeCardID = id
        Self.speakingNarrator = self
        synthesizer.speak(utterance)
    }

    func repeatLast() {
        guard let lastRequest else { return }
        speak(id: lastRequest.id, text: lastRequest.text)
    }

    func stop() {
        activeUtteranceID = nil
        synthesizer.stopSpeaking(at: .immediate)
        activeCardID = nil
        isPaused = false
        if Self.speakingNarrator === self { Self.speakingNarrator = nil }
    }

    private func prepareAudioSessionForSpeech() throws {
#if os(iOS) || os(tvOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
#endif
    }
}
