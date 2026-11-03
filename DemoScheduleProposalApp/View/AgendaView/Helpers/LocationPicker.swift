import SwiftUI

struct LocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LocationPickerViewModel()
    let select: (EventLocation) -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            List {
                Section {
                    TextField("店名・駅名・住所など", text: $viewModel.query)
                        .autocorrectionDisabled()
                } footer: {
                    Text("市区町村も入力すると、場所を絞り込めます。")
                }
                if !viewModel.searchText.isEmpty {
                    Section("自由入力") {
                        Button {
                            choose(EventLocation(name: viewModel.searchText))
                        } label: {
                            Label("「\(viewModel.searchText)」を場所に設定", systemImage: "pencil")
                        }
                    }
                }
                Section("検索結果") {
                    if viewModel.isSearching {
                        ProgressView("検索中…")
                    }
                    ForEach(viewModel.results) { location in
                        Button {
                            choose(location)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .foregroundStyle(.primary)
                                if let address = location.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if !viewModel.message.isEmpty {
                        Text(viewModel.message)
                            .foregroundStyle(.secondary)
                    }
                    if viewModel.searchText.isEmpty {
                        Text("場所を入力すると候補を検索します。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("場所を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .task(id: viewModel.searchText) {
                await viewModel.search(viewModel.searchText)
            }
        }
    }

    private func choose(_ location: EventLocation) {
        select(location)
        dismiss()
    }

}
