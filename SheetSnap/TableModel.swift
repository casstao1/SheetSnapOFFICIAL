import SwiftUI
import MLXVLM
import MLXLMCommon
import MLX

@MainActor
class TableModel: ObservableObject {
    @Published var state: AppState = .idle
    private var modelContainer: ModelContainer?

    func process(url: URL) {
        Task {
            do {
                if modelContainer == nil {
                    try await loadModel()
                }
                try await extractTable(from: url)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func loadModel() async throws {
        state = .downloading(0.0)

        let config = ModelConfiguration(
            id: "mlx-community/Qwen2-VL-2B-Instruct-4bit"
        )

        modelContainer = try await VLMModelFactory.shared.loadContainer(
            configuration: config
        ) { progress in
            Task { @MainActor in
                self.state = .downloading(progress.fractionCompleted)
            }
        }
    }

    private func extractTable(from url: URL) async throws {
        guard let container = modelContainer else {
            throw NSError(domain: "SheetSnap", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }

        let steps = [
            "Loading image",
            "Detecting table structure",
            "Extracting rows and columns",
            "Formatting output"
        ]

        // Advance steps visually while model runs
        Task {
            for step in steps.dropLast() {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if case .processing = self.state {
                    self.state = .processing(step)
                }
            }
        }

        state = .processing(steps[0])

        // Resize image
        guard let nsImage = NSImage(contentsOf: url),
              let resized = resizeImage(nsImage, maxDimension: 600),
              let imageData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]),
              let ciImage = CIImage(data: jpegData) else {
            throw NSError(domain: "SheetSnap", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not load image"])
        }

        let prompt = """
        Look at this image of a table.
        Step 1: Only if there is text clearly outside the table borders output it as: NOTE: <text>. If none, skip.
        Step 2: Output the table using pipe | to separate columns, one row per line.
        Start with the header row, then each data row.
        No dashes, no markdown, no explanation.

        Example:
        Month | Expenses | Budget | Total
        January | 35 | 100 | 65
        February | 23 | 120 | 97
        """

        let raw = try await container.perform { (context: MLXLMCommon.ModelContext) in
            let input = try await context.processor.prepare(
                input: UserInput(
                    prompt: prompt,
                    images: [.ciImage(ciImage)]
                )
            )
            let stream = try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(temperature: 0.0),
                context: context
            )
            var output = ""
            for await generation in stream {
                output += generation.chunk ?? ""
            }
            return output
        }
        let tsv = pipeToTSV(raw)

        if tsv.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            throw NSError(domain: "SheetSnap", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No table found in image"])
        }

        state = .result(tsv)
    }

    private func pipeToTSV(_ raw: String) -> String {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        var tsv: [String] = []

        for line in lines {
            var l = line.trimmingCharacters(in: .whitespaces)
            if l.isEmpty { continue }
            // Skip separator lines |---|
            if l.replacingOccurrences(of: "|", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "").isEmpty { continue }
            // Strip NOTE: prefix
            if l.uppercased().hasPrefix("NOTE:") {
                l = String(l.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
            if l.contains("|") {
                let cells = l.split(separator: "|", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                tsv.append(cells.joined(separator: "\t"))
            } else {
                tsv.append(l)
            }
        }
        return tsv.joined(separator: "\n")
    }

    private func resizeImage(_ image: NSImage, maxDimension: CGFloat) -> NSImage? {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        return newImage
    }
}
