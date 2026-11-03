//
//  AgendaView.swift
//  DemoScheduleProposalApp
//

//
//  予定一覧と区間選択の操作を提供し、選択した区間の提案結果を表示する。

import SwiftUI
import SwiftData

struct AgendaView: View {
    let events: [ScheduleEvent]
    @Environment(\.calendar) private var calendar
    let now: Date
    let edit: (ScheduleEvent) -> Void
    let add: () -> Void
    @Environment(\.modelContext) private var context
    @State private var viewModel = AgendaViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        AgendaListView(days: viewModel.days, daysByDate: viewModel.daysByDate,
                       now: now, isSelecting: viewModel.isSelecting,
                       selection: $viewModel.selection, edit: edit,
                       toggleCompletion: { viewModel.toggleCompletion($0, in: context) }, add: add)
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                if viewModel.isSelecting {
                    HStack {
                        Button("キャンセル") {
                            viewModel.cancelSelection()
                        }
                        Spacer()
                        Text("\(viewModel.validSelection.count)区間選択")
                        Button("実行") {
                            viewModel.update(events: events, now: now, calendar: calendar)
                            viewModel.execute()
                        }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.validSelection.isEmpty)
                    }
                    .padding()
                    .background(.regularMaterial)
                } else {
                    VStack(spacing: 12) {
                        Button {
                            viewModel.beginSelection()
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.title2.weight(.semibold))
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.white)
                                .background(.teal, in: Circle())
                                .shadow(radius: 4, y: 2)
                        }
                        .accessibilityLabel("区間を選んで提案を作成")

                        Button(action: add) {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.white)
                                .background(.teal, in: Circle())
                                .shadow(radius: 4, y: 2)
                        }
                        .accessibilityLabel("予定を追加")
                        .accessibilityIdentifier("agenda.addEvent")
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
            .onChange(of: AgendaInput(events: events, now: now, calendar: calendar), initial: true) { _, _ in
                viewModel.update(events: events, now: now, calendar: calendar)
            }
            .alert("完了状態を保存できませんでした", isPresented: $viewModel.showsCompletionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("変更は保存されていません。もう一度お試しください。")
            }
            .sheet(item: $viewModel.request) { request in
                ProposalResultView(request: request)
            }
    }

}
