import SwiftUI
import PhotosUI
import Vision

struct ImageScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onExtracted: ([String]) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isProcessing: Bool = false
    @State private var scannedLines: [String] = []
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Escanear Lista por Foto")
                            .font(.headline)
                            .bold()
                        Text("Converta notas de papel ou prints em itens de checklist")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                        Text("Selecionar Foto da Galeria")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .onChange(of: selectedItem) { newItem in
                    guard let item = newItem else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            recognizeText(from: image)
                        }
                    }
                }
                
                if isProcessing {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Lendo texto da foto...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                if !scannedLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linhas Reconhecidas (\(scannedLines.count)):")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        List {
                            ForEach(scannedLines.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(scannedLines[index])
                                        .font(.subheadline)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                
                Spacer()
                
                if !scannedLines.isEmpty {
                    Button(action: {
                        onExtracted(scannedLines)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Adicionar \(scannedLines.count) Itens ao Checklist")
                                .font(.headline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Escanear Foto")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() }
            )
        }
    }
    
    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        isProcessing = true
        scannedLines.removeAll()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { req, err in
            DispatchQueue.main.async {
                self.isProcessing = false
                guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
                
                var lines: [String] = []
                for obs in observations {
                    if let topCandidate = obs.topCandidates(1).first {
                        let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            lines.append(text)
                        }
                    }
                }
                self.scannedLines = lines
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["pt-BR", "en-US"]
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
