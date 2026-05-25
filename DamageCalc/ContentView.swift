import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DamageCalcViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("入通院").tag(0)
                    Text("後遺障害").tag(1)
                    Text("死亡").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0: injuryInputSection
                        case 1: disabilityInputSection
                        case 2: deathInputSection
                        default: EmptyView()
                        }

                        if viewModel.showResult {
                            resultSection
                        }
                    }
                    .padding()
                }

                BannerAdView(adUnitID: "ca-app-pub-9404799280370656/DAMAGECALC_B")
                    .frame(height: 50)
            }
            .navigationTitle("損害賠償計算機")
        }
    }

    private var injuryInputSection: some View {
        VStack(spacing: 16) {
            Text("交通事故の入通院慰謝料")
                .font(.headline)

            HStack {
                Text("入院期間")
                    .frame(width: 100, alignment: .leading)
                TextField("月", text: $viewModel.hospitalizationMonths)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("ヶ月")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("通院期間")
                    .frame(width: 100, alignment: .leading)
                TextField("月", text: $viewModel.outpatientMonths)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("ヶ月")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("実通院日数")
                    .frame(width: 100, alignment: .leading)
                TextField("日", text: $viewModel.actualVisitDays)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("日")
                    .foregroundColor(.secondary)
            }

            Picker("怪我の程度", selection: $viewModel.injuryType) {
                Text("むちうち等（軽症）").tag(InjuryType.mild)
                Text("骨折等（重症）").tag(InjuryType.severe)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("過失割合")
                    .frame(width: 100, alignment: .leading)
                TextField("%", text: $viewModel.faultPercent)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("% (自分の過失)")
                    .foregroundColor(.secondary)
            }

            Button(action: { viewModel.calculateInjury() }) {
                Text("計算する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var disabilityInputSection: some View {
        VStack(spacing: 16) {
            Text("後遺障害慰謝料")
                .font(.headline)

            Picker("後遺障害等級", selection: $viewModel.disabilityGrade) {
                ForEach(1...14, id: \.self) { grade in
                    Text("第\(grade)級").tag(grade)
                }
            }

            HStack {
                Text("年収")
                    .frame(width: 100, alignment: .leading)
                TextField("万円", text: $viewModel.annualIncome)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text("万円")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("年齢")
                    .frame(width: 100, alignment: .leading)
                TextField("歳", text: $viewModel.age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("歳")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("過失割合")
                    .frame(width: 100, alignment: .leading)
                TextField("%", text: $viewModel.faultPercent)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("% (自分の過失)")
                    .foregroundColor(.secondary)
            }

            Button(action: { viewModel.calculateDisability() }) {
                Text("計算する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var deathInputSection: some View {
        VStack(spacing: 16) {
            Text("死亡慰謝料")
                .font(.headline)

            Picker("被害者の立場", selection: $viewModel.victimRole) {
                Text("一家の支柱").tag(VictimRole.breadwinner)
                Text("母親・配偶者").tag(VictimRole.spouse)
                Text("その他").tag(VictimRole.other)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("年収")
                    .frame(width: 100, alignment: .leading)
                TextField("万円", text: $viewModel.annualIncome)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text("万円")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("年齢")
                    .frame(width: 100, alignment: .leading)
                TextField("歳", text: $viewModel.age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("歳")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("過失割合")
                    .frame(width: 100, alignment: .leading)
                TextField("%", text: $viewModel.faultPercent)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("% (自分の過失)")
                    .foregroundColor(.secondary)
            }

            Button(action: { viewModel.calculateDeath() }) {
                Text("計算する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var resultSection: some View {
        VStack(spacing: 16) {
            Text("算定結果")
                .font(.title2.bold())

            VStack(spacing: 12) {
                resultRow("自賠責基準", viewModel.jibaisekiAmount)
                resultRow("任意保険基準（推定）", viewModel.insuranceAmount)
                resultRow("弁護士基準（裁判基準）", viewModel.lawyerAmount)

                if viewModel.lostIncome > 0 {
                    Divider()
                    resultRow("逸失利益", viewModel.lostIncome)
                }

                Divider()

                HStack {
                    Text("保険会社提示額との差額目安")
                        .font(.caption)
                    Spacer()
                }
                Text("弁護士基準は任意保険基準の約\(viewModel.multiplierText)倍")
                    .font(.headline)
                    .foregroundColor(.indigo)
            }
            .padding()
            .background(Color.indigo.opacity(0.05))
            .cornerRadius(12)

            Text("※ 本計算は一般的な算定基準に基づく目安です。\n個別事情により金額は変動します。\n正確な金額は弁護士にご相談ください。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func resultRow(_ label: String, _ amount: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("¥\(formatNumber(amount))")
                .font(.subheadline.bold())
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
