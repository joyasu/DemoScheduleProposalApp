import SwiftUI
import SwiftData

struct EventEditor: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var viewModel: EventEditorViewModel
    @State private var confirmsDeletion = false
    @State private var showsLocationPicker = false

    init(draft: EventDraft) {
        _viewModel = State(initialValue: EventEditorViewModel(draft: draft))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("予定") {
                    TextField("タイトル", text: $viewModel.draft.title)
                        .accessibilityIdentifier("eventEditor.title")
                    Toggle("終日", isOn: $viewModel.draft.isAllDay)
                }
                Section("日時") {
                    DatePicker("開始", selection: $viewModel.start,
                               displayedComponents: viewModel.draft.isAllDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker("終了", selection: $viewModel.end,
                               displayedComponents: viewModel.draft.isAllDay ? [.date] : [.date, .hourAndMinute])
                    if viewModel.showsInvalidDates {
                        Text("終了は開始以降の日時にしてください。")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                EventLocationSection(location: $viewModel.draft.location) {
                    showsLocationPicker = true
                }
                Section("メモ") {
                    TextField("持ち物など（任意）", text: $viewModel.draft.memo, axis: .vertical)
                        .lineLimit(3...8)
                }
                if viewModel.draft.event != nil {
                    Section {
                        Button("予定を削除", role: .destructive) {
                            confirmsDeletion = true
                        }
                        .accessibilityIdentifier("eventEditor.delete")
                    }
                }
            }
            .navigationTitle(viewModel.draft.event == nil ? "予定を追加" : "予定を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .accessibilityIdentifier("eventEditor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if viewModel.save(in: context) { dismiss() }
                    }
                        .disabled(!viewModel.isValid)
                        .accessibilityIdentifier("eventEditor.save")
                }
            }
            .confirmationDialog("この予定を削除しますか？", isPresented: $confirmsDeletion, titleVisibility: .visible) {
                Button("予定を削除", role: .destructive) {
                    if viewModel.delete(in: context) { dismiss() }
                }
                .accessibilityIdentifier("eventEditor.confirmDelete")
                Button("キャンセル", role: .cancel) {}
            }
            .alert("保存できませんでした", isPresented: $viewModel.showsSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("変更は保存されていません。もう一度お試しください。")
            }
        }
        .onChange(of: calendar, initial: true) { _, calendar in
            viewModel.updateCalendar(calendar)
        }
        .sheet(isPresented: $showsLocationPicker) {
            LocationPicker { selected in
                viewModel.draft.location = selected
            }
        }
    }

}
