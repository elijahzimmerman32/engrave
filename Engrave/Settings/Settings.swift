import AVFoundation

enum PracticeStyle: String, CaseIterable, Identifiable {
    /// Learn each piece on its own, then say the whole verse.
    case pieces
    /// Repeat after me, adding a piece each round: "For the wages of sin." then
    /// "For the wages of sin is death." and so on until it's the whole verse.
    case buildUp

    var id: Self { self }
    var label: String { self == .pieces ? "Pieces" : "Build Up" }
    var detail: String {
        switch self {
        case .pieces: "Learn each piece on its own, then say the whole verse."
        case .buildUp: "Repeat after me, adding a few words each round until you're saying the whole verse."
        }
    }
}

/// Choices saved on the phone and changed on the Settings tab.
enum AppSettings {
    static let voiceKey = "voiceIdentifier"
    static let repeatsKey = "repeatsPerRound"
    static let styleKey = "practiceStyle"

    /// How many correct answers in a row each practice round needs: 1 or 2 (the default).
    static var repeats: Int {
        UserDefaults.standard.integer(forKey: repeatsKey) == 1 ? 1 : 2
    }

    static var style: PracticeStyle {
        PracticeStyle(rawValue: UserDefaults.standard.string(forKey: styleKey) ?? "") ?? .pieces
    }
}

enum Voices {
    /// Natural-sounding male voices, best first, used when nothing has been picked.
    private static let preferredMale = ["Evan", "Nathan", "Tom", "Aaron", "Arthur", "Daniel", "Gordon", "Rishi"]

    /// English voices on this phone, best quality first. Leaves out the novelty and robotic voices.
    static var english: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("en")
                    && !voice.voiceTraits.contains(.isNoveltyVoice)
                    && !voice.voiceTraits.contains(.isPersonalVoice)
                    && !voice.identifier.contains("eloquence")
                    && !voice.identifier.contains("speech.synthesis.voice")
            }
            .sorted {
                if $0.quality != $1.quality { return $0.quality.rawValue > $1.quality.rawValue }
                return $0.name < $1.name
            }
    }

    static var defaultMale: AVSpeechSynthesisVoice? {
        let males = english.filter { $0.gender == .male }
        func rank(_ voice: AVSpeechSynthesisVoice) -> Int {
            preferredMale.firstIndex(of: voice.name) ?? preferredMale.count
        }
        return males.min {
            if $0.quality != $1.quality { return $0.quality.rawValue > $1.quality.rawValue }
            if ($0.language == "en-US") != ($1.language == "en-US") { return $0.language == "en-US" }
            return rank($0) < rank($1)
        }
    }

    /// The voice picked in Settings, or a male voice if none has been picked.
    static var current: AVSpeechSynthesisVoice? {
        if let id = UserDefaults.standard.string(forKey: AppSettings.voiceKey),
           let voice = AVSpeechSynthesisVoice(identifier: id) {
            return voice
        }
        return defaultMale ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    /// "Evan, Enhanced, US"
    static func label(for voice: AVSpeechSynthesisVoice) -> String {
        var parts = [voice.name]
        switch voice.quality {
        case .premium: parts.append("Premium")
        case .enhanced: parts.append("Enhanced")
        default: break
        }
        let region = voice.language.split(separator: "-").last.map(String.init) ?? ""
        let regions = ["US": "US", "GB": "UK", "AU": "Australia", "IE": "Ireland", "IN": "India", "ZA": "South Africa", "CA": "Canada", "NZ": "New Zealand"]
        if let name = regions[region] { parts.append(name) }
        return parts.joined(separator: ", ")
    }
}
