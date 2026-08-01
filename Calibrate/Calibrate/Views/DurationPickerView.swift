import SwiftUI

/// Chooses how long a manual pause runs. Shown after tapping Take a Pause, before anything is
/// applied — this is the last moment the decision is reversible, which is deliberate.
struct DurationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    private let onConfirm: (Int) -> Void

    init(onConfirm: @escaping (Int) -> Void) {
        self.onConfirm = onConfirm
    }

    @State private var selectedMinutes = PauseDuration.presets.first ?? 15
    @State private var isCustom = false
    @State private var customHours = 0
    @State private var customMinutes = 30

    private var resolvedMinutes: Int {
        isCustom ? customHours * 60 + customMinutes : selectedMinutes
    }

    private var isValid: Bool {
        resolvedMinutes >= PauseDuration.minimumMinutes
            && resolvedMinutes <= PauseDuration.maximumMinutes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: Theme.Metrics.stackSpacing) {
                    Text("How long would you like?")
                        .font(Theme.rounded(22, weight: .medium))
                        .foregroundStyle(Theme.primaryTextColor)
                        .padding(.top, 12)

                    presetGrid

                    customSection

                    Spacer()

                    if !isValid {
                        Text("Pauses run from \(PauseDuration.minimumMinutes) minutes to \(PauseDuration.label(minutes: PauseDuration.maximumMinutes)).")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }

                    Button("Begin") {
                        onConfirm(resolvedMinutes)
                    }
                    .buttonStyle(SoftButtonStyle(
                        tint: Theme.surfaceColor,
                        fill: isValid ? Theme.sageDeepColor : Theme.dividerColor
                    ))
                    .disabled(!isValid)
                }
                .padding(Theme.Metrics.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                        .foregroundStyle(Theme.secondaryTextColor)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(PauseDuration.presets, id: \.self) { minutes in
                Button {
                    selectedMinutes = minutes
                    isCustom = false
                } label: {
                    Text(PauseDuration.label(minutes: minutes))
                        .font(Theme.buttonLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isSelected(minutes) ? Theme.surfaceColor : Theme.sageDeepColor)
                .background(isSelected(minutes) ? Theme.sageDeepColor : Theme.sageSoftColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var customSection: some View {
        VStack(spacing: 8) {
            Button {
                isCustom.toggle()
            } label: {
                HStack {
                    Text("Something else")
                        .font(Theme.body)
                    Spacer()
                    Image(systemName: isCustom ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Theme.secondaryTextColor)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            if isCustom {
                HStack(spacing: 0) {
                    Picker("Hours", selection: $customHours) {
                        ForEach(0...12, id: \.self) { Text("\($0) hr").tag($0) }
                    }
                    .pickerStyle(.wheel)

                    Picker("Minutes", selection: $customMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 130)
            }
        }
    }

    private func isSelected(_ minutes: Int) -> Bool {
        !isCustom && selectedMinutes == minutes
    }
}
