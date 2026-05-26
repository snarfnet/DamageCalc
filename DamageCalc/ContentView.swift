import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DamageCalcViewModel()
    @State private var selectedMode: DamageMode = .injury

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: 0x111827), Color(hex: 0x1E1B4B)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        heroSection
                        modePicker
                        inputSection
                        if viewModel.showResult {
                            resultSection
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 76)
                }
            }
            .navigationTitle("損害賠償計算機")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                BannerAdView(adUnitID: "ca-app-pub-9404799280370656/DAMAGECALC_B")
                    .frame(height: 50)
                    .background(.ultraThinMaterial)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LEGAL ESTIMATE")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text("保険会社提示額と弁護士基準の差を見える化")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
            }

            Text("交通事故の入通院、後遺障害、死亡事故の概算に対応。過失割合も反映します。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(20)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.12)))
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(DamageMode.allCases) { mode in
                Button {
                    selectedMode = mode
                    viewModel.showResult = false
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                        Text(mode.title)
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedMode == mode ? .black : .white.opacity(0.74))
                .background(selectedMode == mode ? .orange : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        switch selectedMode {
        case .injury:
            formCard(title: "入通院慰謝料") {
                numberField("入院期間", text: $viewModel.hospitalizationMonths, suffix: "か月")
                numberField("通院期間", text: $viewModel.outpatientMonths, suffix: "か月")
                numberField("実通院日数", text: $viewModel.actualVisitDays, suffix: "日")
                segmented("症状区分", selection: $viewModel.injuryType, values: InjuryType.allCases)
                numberField("自分の過失", text: $viewModel.faultPercent, suffix: "%")
                primaryButton("入通院で計算", action: viewModel.calculateInjury)
            }
        case .disability:
            formCard(title: "後遺障害") {
                Stepper("後遺障害 \(viewModel.disabilityGrade)級", value: $viewModel.disabilityGrade, in: 1...14)
                    .font(.subheadline.weight(.semibold))
                numberField("年収", text: $viewModel.annualIncome, suffix: "万円")
                numberField("年齢", text: $viewModel.age, suffix: "歳")
                numberField("自分の過失", text: $viewModel.faultPercent, suffix: "%")
                primaryButton("後遺障害で計算", action: viewModel.calculateDisability)
            }
        case .death:
            formCard(title: "死亡事故") {
                segmented("被害者の立場", selection: $viewModel.victimRole, values: VictimRole.allCases)
                numberField("年収", text: $viewModel.annualIncome, suffix: "万円")
                numberField("年齢", text: $viewModel.age, suffix: "歳")
                numberField("自分の過失", text: $viewModel.faultPercent, suffix: "%")
                primaryButton("死亡事故で計算", action: viewModel.calculateDeath)
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.resultTitle)
                    .font(.title3.bold())
                Text(viewModel.resultNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                amountRow("自賠責基準", viewModel.jibaisekiAmount)
                amountRow("任意保険基準の目安", viewModel.insuranceAmount)
                amountRow("弁護士基準", viewModel.lawyerAmount, color: .orange)
                if viewModel.lostIncome > 0 {
                    amountRow("逸失利益", viewModel.lostIncome, color: .purple)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("上乗せ余地")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(viewModel.upliftAmount))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                }
                Spacer()
                Text("約\(viewModel.multiplierText)倍")
                    .font(.headline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.orange.opacity(0.16), in: Capsule())
                    .foregroundStyle(.orange)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            Text("この計算は一般的な基準による概算です。実際の請求額は事故状況、証拠、治療経過、後遺障害認定で変わります。重要な判断は弁護士へ相談してください。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func formCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func numberField(_ title: String, text: Binding<String>, suffix: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.headline)
                .frame(width: 90)
            Text(suffix)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func segmented<T: Identifiable & Hashable>(_ title: String, selection: Binding<T>, values: [T]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(values) { value in
                    Text(label(for: value)).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "function")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private func amountRow(_ title: String, _ amount: Int, color: Color = .primary) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(viewModel.formatCurrency(amount))
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
    }

    private func label<T>(for value: T) -> String {
        if let value = value as? InjuryType { return value.label }
        if let value = value as? VictimRole { return value.label }
        return "\(value)"
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}
