//
//  DownloadSettings.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-24.
//

import SwiftUI
import SwiftData
import SwipeActions

struct LocalDownloadItem: Identifiable {
    let id: String
    let name: String
    let detail: String?
    let data: [Data]
    let model: any PersistentModel
    
    var byteCount: Int {
        data.reduce(0) { $0 + $1.count }
    }
}

class DownloadSettingsHelper {
    static func formattedByteCount(_ byteCount: Int) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(byteCount))
    }
    
    static func fetchAllLocalData(with dataController: DataController) throws -> [LocalDataKind: [LocalDownloadItem]] {
        var result: [LocalDataKind: [LocalDownloadItem]] = [:]
        
        for modelType in AppConstants.modelTypes {
            guard let providerType = modelType as? LocalDataProviding.Type else { continue }
            
            let models = try dataController.fetchSaved(modelType)
            
            let items = try models.compactMap { model -> LocalDownloadItem? in
                guard let provider = model as? LocalDataProviding else { return nil }
                
                let data = try provider.localFiles.compactMap { reference -> Data? in
                    guard
                        let url = reference.url,
                        FileManager.default.fileExists(atPath: url.path)
                    else {
                        return nil
                    }
                    
                    return try Data(contentsOf: url)
                }
                
                guard !data.isEmpty else { return nil }
                
                return LocalDownloadItem(
                    id: provider.localDataID,
                    name: provider.localDataName,
                    detail: provider.localDataDetail,
                    data: data,
                    model: model
                )
            }
            
            guard !items.isEmpty else { continue }
            result[providerType.modelKind, default: []].append(contentsOf: items)
        }
        
        return result
    }
}

struct DownloadSettings: View {
    
    var dataController: DataController
    
    @State private var dataByAssetKind: [LocalDataKind: [LocalDownloadItem]] = [:]
    
    @State private var categoriesToggled = Set<LocalDataKind>()
    
    var totalData: Int {
        dataByAssetKind
            .values
            .flatMap { $0 }
            .map(\.byteCount)
            .reduce(0, +)
    }
    
    var sortedDataByCategory: [(LocalDataKind, [LocalDownloadItem])] {
        dataByAssetKind
            .sorted {
                $0.value.map(\.byteCount).reduce(0, +) >
                $1.value.map(\.byteCount).reduce(0, +)
            }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16)  {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick summary")
                            .font(.title)
                            .bold()
                        
                        Text("Review everything you’ve downloaded. You can delete downloads individually or by category.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    
                    LabeledContent {
                        Text(DownloadSettingsHelper.formattedByteCount(totalData))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } label: {
                        Text("Total storage used")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if !sortedDataByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Downloads by category")
                            .font(.title)
                            .bold()
                        
                        VStack(spacing: .zero) {
                            SwipeViewGroup {
                                ForEach(Array(sortedDataByCategory.enumerated()), id: \.element.0) { index, element in
                                    let (assetKind, items) = element
                                    let totalByteCount = items.reduce(0) { $0 + $1.byteCount }
                                    
                                    SwipeView {
                                        LabeledContent {
                                            Text(DownloadSettingsHelper.formattedByteCount(totalByteCount))
                                        } label: {
                                            VStack(alignment: .leading) {
                                                Text(assetKind.menuPage)
                                                    .fontWeight(.medium)
                                                Text(assetKind.summary)
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                                    .frame(minWidth: 150, maxWidth: 250, alignment: .leading)
                                            }
                                        }
                                        .contentShape(.rect)
                                    } trailingActions: { _ in
                                        SwipeAction {
                                            do {
                                                for item in items {
                                                    try deleteItem(for: item)
                                                }
                                                
                                                dataByAssetKind.removeValue(forKey: assetKind)
                                            } catch {
                                                print(error)
                                            }
                                        } label: { _ in
                                            Label("Delete", systemImage: "trash")
                                                .font(.footnote)
                                                .foregroundStyle(.red)
                                        } background: { _ in
                                            Color(.secondarySystemBackground)
                                        }
                                    }
                                    .padding()
                                    
                                    if index < sortedDataByCategory.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                
                if !sortedDataByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Individual downloads")
                            .font(.title)
                            .bold()
                        
                        VStack(spacing: .zero) {
                            SwipeViewGroup {
                                ForEach(Array(sortedDataByCategory.enumerated()), id: \.element.0) { index, element in
                                    let (assetKind, items) = element
                                    let isExpanded = categoriesToggled.contains(assetKind)
                                    
                                    Button {
                                        withAnimation {
                                            updateCategoryToggleState(assetKind)
                                        }
                                    } label: {
                                        LabeledContent {
                                            Image(systemName: "chevron.right")
                                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                        } label: {
                                            Text(assetKind.menuPage)
                                                .fontWeight(.medium)
                                        }
                                        .padding()
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if isExpanded {
                                        VStack(spacing: 10) {
                                            ForEach(items) { item in
                                                SwipeView {
                                                    LabeledContent {
                                                        Text(DownloadSettingsHelper.formattedByteCount(item.byteCount))
                                                            .foregroundStyle(.secondary)
                                                            .monospacedDigit()
                                                    } label: {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(item.name)
                                                                .font(.callout)
                                                            
                                                            if let detail = item.detail, !detail.isEmpty {
                                                                Text(detail)
                                                                    .font(.footnote)
                                                                    .foregroundStyle(.secondary)
                                                                    .lineLimit(2)
                                                            }
                                                        }
                                                    }
                                                    .frame(minHeight: 44)
                                                    .contentShape(.rect)
                                                } trailingActions: { _ in
                                                    SwipeAction {
                                                        do {
                                                            try deleteItem(for: item)
                                                            dataByAssetKind[assetKind]?.removeAll {
                                                                $0.id == item.id
                                                            }
                                                        } catch {
                                                            print(error)
                                                        }
                                                    } label: { _ in
                                                        Label("Delete", systemImage: "trash")
                                                            .font(.footnote)
                                                            .foregroundStyle(.red)
                                                    } background: { _ in
                                                        Color(.secondarySystemBackground)
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                        .padding(.bottom)
                                    }
                                    
                                    if index < sortedDataByCategory.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            do {
                dataByAssetKind = try DownloadSettingsHelper.fetchAllLocalData(with: dataController)
            } catch {
                print(error)
            }
        }
    }
    
    private func updateCategoryToggleState(_ category: LocalDataKind) {
        if categoriesToggled.contains(category) {
            categoriesToggled.remove(category)
        } else {
            categoriesToggled.insert(category)
        }
    }
    
    private func deleteItem(for item: LocalDownloadItem) throws {
        try dataController.delete(item.model)
        
        if var downloadableModel = item.model as? Downloadable {
            downloadableModel.isDownloadedLocally = false
        }
    }
}

#Preview {
    DownloadSettings(dataController: SwiftDataController(modelContext: previewContainer.mainContext))
}
