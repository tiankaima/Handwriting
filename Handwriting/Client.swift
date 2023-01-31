//
//  Client.swift
//  Handwriting
//
//  Created by Tiankai Ma on 2023/1/31.
//

// used on macOS to train models and other stuff.
import PencilKit
import SwiftUI

#if os(macOS)
struct ContentView: View {
    @State var fileURL: URL?
    @State var strokeStroage: [String: [PKStroke]] = [:]
    @State var currentLetter: String = ""
    @Environment(\.displayScale) var scale
    @State var pkdrawing = PKDrawing(strokes: [])

    var body: some View {
        // Button to open json file:
        // 1. read json file
        // 2. decode json file to [String: PKDrawing], save to memory
        NavigationSplitView {
            List(strokeStroage.keys.map { $0 }, id: \.self, selection: $currentLetter) { key in
                Text(key)
            }
        } detail: {
            Image(nsImage: pkdrawing.image(from: pkdrawing.bounds, scale: scale))
                .onChange(of: currentLetter) { newValue in
                    pkdrawing.strokes = strokeStroage.first(where: { $0.key == newValue })?.value ?? []
                }
        }
        .toolbar {
            Button {
                // open a seprate window asking for file
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    self.fileURL = panel.url
                }

                // read json file
                let data = try! Data(contentsOf: fileURL!)
                let decoder = JSONDecoder()
                let drawingStorage = try! decoder.decode([String: PKDrawing].self, from: data)
                strokeStroage = drawingStorage.mapValues { $0.strokes }
            } label: {
                Label("Select file", systemImage: "square.and.arrow.down")
            }
        }
    }
}

struct ContentView_PreviewProvider: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 400, height: 400)
    }
}
#endif
