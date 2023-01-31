//
//  ContentView.swift
//  Handwriting
//
//  Created by Tiankai Ma on 2023/1/31.
//

import PencilKit
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
struct PencilCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context _: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = PKInkingTool(.pen, color: .blue, width: 15)
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_: PKCanvasView, context _: Context) {}
}

struct ContentView: View {
    @State var canvasView: PKCanvasView = .init()
    // a-z, A-Z, 0-9, and usefull math symbols(inside unicode)
    var allLetters: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "√", "∫", "∑", "∞", "∝", "∠", "∧", "∨", "∩", "∪", "∫", "∴", "∵", "∼", "≈", "≠", "≡", "≤", "≥", "⊂", "⊃", "⊆", "⊇", "⊕", "⊗", "⊥", "⋅"]
    @State var strokeStorage: [String: [PKStroke]] = [:]
    @State var currentLetter: String = "a" {
        willSet {
            if !canvasView.drawing.strokes.isEmpty {
                strokeStorage[currentLetter] = canvasView.drawing.strokes
            }
            canvasView.drawing.strokes = strokeStorage.first(where: { $0.key == newValue })?.value ?? []
        }
    }

    // Apparently I haven't find a way to listen to variable change inside a Struct
    @State var isErasor: Bool = false
    @State var isPen: Bool = true

    // export strokeStorage to json, save to tmp file, return file URL
    // strokeStorage: [String: [PKStroke]], is stored to [String: PKDrawing]
    func export() -> URL {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("tmpStrokeStorage.json")
        let encoder = JSONEncoder()
        let drawingStorage = strokeStorage.mapValues { PKDrawing(strokes: $0) }
        let data = try! encoder.encode(drawingStorage)
        try! data.write(to: tmpFile)
        return tmpFile
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(allLetters, id: \.self) { letter in
                        Button {
                            currentLetter = letter
                        } label: {
                            ZStack {
                                if strokeStorage.keys.contains(letter) && !(strokeStorage.first(where: { $0.key == letter })?.value ?? []).isEmpty {
                                    Color.green
                                        .opacity(0.3)
                                } else {
                                    Color.gray
                                }
                                Text(letter)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 50)
                            .border(currentLetter == letter ? .blue : .clear)
                        }
                    }
                }
            }
            HStack {
                List {
                    Section {
                        Button {
                            canvasView.tool = PKEraserTool(.vector)
                            isErasor = true
                            isPen = false
                        } label: {
                            Label("Erasor(Vector)", systemImage: "eraser")
                                .foregroundColor(isErasor ? .green : .accentColor)
                        }

                        Button {
                            canvasView.tool = PKInkingTool(.pen, color: .blue, width: 15)
                            isErasor = false
                            isPen = true
                        } label: {
                            Label("Pencil", systemImage: "pencil")
                                .foregroundColor(isPen ? .green : .accentColor)
                        }
                    } header: {
                        Text("Tools")
                    }

                    Section {
                        ShareLink(item: export())

                        Button {
                            let picker = DocumentPickerViewController(
                                supportedTypes: [.json],
                                onPick: { url in
                                    if url.startAccessingSecurityScopedResource() {
                                        let data = try! Data(contentsOf: url)
                                        let decoder = JSONDecoder()
                                        let drawingStorage = try! decoder.decode([String: PKDrawing].self, from: data)
                                        self.strokeStorage = drawingStorage.mapValues { $0.strokes }
                                        url.stopAccessingSecurityScopedResource()
                                    }
                                },
                                onDismiss: {
                                    print("dismiss")
                                }
                            )
                            UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    } header: {
                        Text("Export")
                    }

                    Section {
                        Button {
                            canvasView.drawing.strokes = []
                        } label: {
                            Label("Remove all strokes", systemImage: "exclamationmark.square.fill")
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("Dangerous")
                    }
                }
                .listStyle(.plain)
                .foregroundColor(.blue)
                .frame(width: 250)

                PencilCanvas(canvasView: $canvasView)
                    .border(.blue)
                    .background {
                        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                            ForEach(0 ..< 5) { _ in
                                GridRow {
                                    ForEach(0 ..< 5) { _ in
                                        Color.clear
                                            .opacity(0.2)
                                            .border(.blue.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class DocumentPickerViewController: UIDocumentPickerViewController {
    private let onDismiss: () -> Void
    private let onPick: (URL) -> Void

    init(supportedTypes: [UTType], onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onPick = onPick

        super.init(forOpeningContentTypes: supportedTypes, asCopy: false)
        allowsMultipleSelection = false
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first!)
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        onDismiss()
    }
}
#endif
