//
//  ProposalResultView.swift
//  DemoScheduleProposalApp
//

//
//  選択した区間の提案結果と読み込み状態を表示し、不足する場所の設定を受け付ける。

import SwiftUI

struct ProposalResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var locationTarget: ProposalEvent?
    @State private var viewModel: ProposalResultViewModel

    init(request: ProposalRequest) {
        _viewModel = State(initialValue: ProposalResultViewModel(request: request))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("選んだ区間に、車での移動と休憩を提案します。予定への保存は行いません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if viewModel.isLoading {
                        ProgressView("移動時間を確認中…")
                    }
                    ForEach(viewModel.request.intervals) { interval in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(interval.start, format: .dateTime.month().day().weekday())
                                .font(.headline)
                            if let from = interval.from {
                                proposalCard(from)
                            } else {
                                NowCard(now: viewModel.currentOrigin?.start ?? interval.start)
                                if let error = viewModel.locationError {
                                    Label(error, systemImage: "location.slash")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let gap = viewModel.gaps[interval.id] {
                                ProposalGapView(gap: gap)
                            }
                            proposalCard(interval.to)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("提案スケジュール")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("選択に戻る") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("再試行") { viewModel.attempt += 1 }
                        .disabled(viewModel.isLoading)
                }
            }
        }
        .sheet(item: $locationTarget) { event in
            LocationPicker { location in
                viewModel.setLocation(location, for: event)
            }
        }
        .task(id: viewModel.attempt) {
            await viewModel.load()
        }
    }
    private func proposalCard(_ event: ProposalEvent) -> some View {
        let resolved = viewModel.resolved(event)
        return EventCard(
            title: resolved.title, start: resolved.start, end: resolved.end,
            locationName: resolved.location?.name, memo: resolved.memo,
            setLocation: viewModel.needsLocation(event) ? { locationTarget = event } : nil
        )
        .disabled(viewModel.isLoading)
    }
}
