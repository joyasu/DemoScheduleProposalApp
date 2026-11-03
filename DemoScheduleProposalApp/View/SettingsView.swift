import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var viewModel = SettingsViewModel()
    @State private var confirmsDeletion = false
    let didDeleteAllData: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
            Text("設定")
                .font(.headline)
            #if DEBUG
            Button("全データを削除", systemImage: "trash", role: .destructive) {
                confirmsDeletion = true
            }
            .confirmationDialog("全データを削除しますか？", isPresented: $confirmsDeletion,
                                titleVisibility: .visible) {
                Button("全データを削除", role: .destructive) {
                    if viewModel.deleteAllData(in: context) {
                        didDeleteAllData()
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべての予定・場所・メモを削除します。この操作は取り消せません。")
            }
            #else
            Text("現在、変更できる設定はありません。")
                .foregroundStyle(.secondary)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
        }
        .alert("削除できませんでした", isPresented: $viewModel.showsDeletionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("データは削除されていません。もう一度お試しください。")
        }
    }
}
