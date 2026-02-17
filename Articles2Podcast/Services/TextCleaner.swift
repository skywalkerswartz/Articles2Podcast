import Foundation

enum TextCleaner {
    /// Clean extracted HTML content into plain text suitable for TTS
    static func clean(_ html: String) -> String {
        var text = html

        // Remove HTML tags
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&ndash;", "-"),
            ("&mdash;", "—"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}"),
            ("&hellip;", "..."),
            ("&trade;", "\u{2122}"),
            ("&copy;", "\u{00A9}"),
            ("&reg;", "\u{00AE}"),
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Decode numeric HTML entities (&#123; and &#x1F; forms)
        text = decodeNumericEntities(text)

        // Remove common web artifacts
        let artifacts = [
            "Advertisement",
            "[Read more]",
            "[Continue reading]",
            "Share this article",
            "Subscribe to our newsletter",
            "Click here to",
        ]
        for artifact in artifacts {
            text = text.replacingOccurrences(of: artifact, with: "")
        }

        // Normalize whitespace
        text = text.replacingOccurrences(
            of: "[ \\t]+",
            with: " ",
            options: .regularExpression
        )

        // Normalize line breaks (3+ newlines → 2)
        text = text.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Split cleaned text into paragraphs for paragraph-by-paragraph TTS
    static func splitIntoParagraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 1 }
    }

    private static func decodeNumericEntities(_ text: String) -> String {
        var result = text

        // Decimal: &#123;
        let decimalPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: decimalPattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result),
                      let numRange = Range(match.range(at: 1), in: result),
                      let codePoint = UInt32(result[numRange]),
                      let scalar = Unicode.Scalar(codePoint) else { continue }
                result.replaceSubrange(range, with: String(scalar))
            }
        }

        // Hex: &#x1F;
        let hexPattern = "&#x([0-9a-fA-F]+);"
        if let regex = try? NSRegularExpression(pattern: hexPattern) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result),
                      let numRange = Range(match.range(at: 1), in: result),
                      let codePoint = UInt32(result[numRange], radix: 16),
                      let scalar = Unicode.Scalar(codePoint) else { continue }
                result.replaceSubrange(range, with: String(scalar))
            }
        }

        return result
    }
}
