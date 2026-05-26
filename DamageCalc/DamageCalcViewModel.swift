import SwiftUI

enum InjuryType: String, CaseIterable, Identifiable {
    case mild
    case severe

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mild: return "軽傷"
        case .severe: return "重傷"
        }
    }
}

enum VictimRole: String, CaseIterable, Identifiable {
    case breadwinner
    case spouse
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breadwinner: return "一家の支柱"
        case .spouse: return "配偶者・母親"
        case .other: return "その他"
        }
    }
}

enum DamageMode: Int, CaseIterable, Identifiable {
    case injury
    case disability
    case death

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .injury: return "入通院"
        case .disability: return "後遺障害"
        case .death: return "死亡"
        }
    }

    var icon: String {
        switch self {
        case .injury: return "cross.case.fill"
        case .disability: return "figure.walk.motion"
        case .death: return "scalemass.fill"
        }
    }
}

final class DamageCalcViewModel: ObservableObject {
    @Published var hospitalizationMonths = "0"
    @Published var outpatientMonths = "3"
    @Published var actualVisitDays = "45"
    @Published var injuryType: InjuryType = .mild
    @Published var faultPercent = "0"
    @Published var disabilityGrade = 14
    @Published var annualIncome = "400"
    @Published var age = "35"
    @Published var victimRole: VictimRole = .breadwinner
    @Published var showResult = false

    var jibaisekiAmount = 0
    var insuranceAmount = 0
    var lawyerAmount = 0
    var lostIncome = 0
    var multiplierText = "1.5"
    var resultTitle = "概算結果"
    var resultNote = "一般的な基準を使った簡易計算です。"

    private let severeTable: [[Int]] = [
        [0, 53, 101, 145, 184, 217, 244, 266, 284, 297, 306, 314, 321, 328],
        [35, 98, 139, 177, 210, 236, 260, 279, 295, 306, 314, 322, 329, 334],
        [53, 115, 154, 188, 218, 244, 267, 287, 302, 314, 322, 330, 336, 342],
        [73, 130, 165, 196, 226, 251, 274, 293, 308, 320, 328, 336, 342, 348],
        [90, 141, 173, 204, 233, 257, 280, 299, 314, 326, 334, 342, 348, 354],
        [105, 149, 181, 211, 239, 264, 286, 305, 320, 332, 340, 348, 354, 360],
        [116, 157, 188, 217, 244, 269, 292, 310, 326, 338, 346, 354, 360, 366],
        [124, 163, 194, 222, 249, 274, 296, 316, 332, 344, 352, 360, 366, 372],
        [130, 168, 199, 226, 253, 278, 300, 320, 336, 348, 356, 364, 372, 378],
        [134, 172, 203, 230, 256, 282, 304, 324, 340, 352, 360, 368, 376, 382],
        [138, 176, 207, 234, 260, 286, 308, 328, 344, 356, 364, 372, 380, 386],
        [140, 178, 209, 236, 262, 288, 310, 330, 346, 358, 366, 374, 382, 388],
        [142, 180, 211, 238, 264, 290, 312, 332, 348, 360, 368, 376, 384, 390],
        [144, 182, 213, 240, 266, 292, 314, 334, 350, 362, 370, 378, 386, 392],
        [146, 184, 215, 242, 268, 294, 316, 336, 352, 364, 372, 380, 388, 394]
    ]

    private let mildTable: [[Int]] = [
        [0, 19, 36, 53, 67, 79, 89, 97, 103, 109, 113, 117, 119, 121],
        [35, 52, 69, 83, 95, 105, 113, 119, 125, 129, 133, 135, 137, 139],
        [53, 69, 83, 95, 105, 115, 121, 127, 133, 137, 141, 143, 145, 147],
        [73, 83, 95, 105, 115, 123, 129, 135, 141, 145, 149, 151, 153, 155],
        [87, 95, 105, 115, 123, 131, 137, 143, 149, 153, 157, 159, 161, 163],
        [97, 105, 115, 123, 131, 139, 145, 151, 157, 161, 165, 167, 169, 171],
        [105, 113, 123, 131, 139, 147, 151, 157, 163, 167, 171, 173, 175, 177],
        [111, 119, 129, 137, 145, 151, 157, 163, 169, 173, 177, 179, 181, 183],
        [113, 123, 133, 141, 149, 155, 161, 167, 173, 177, 181, 183, 185, 187],
        [115, 125, 135, 143, 151, 157, 163, 169, 175, 179, 183, 185, 187, 189],
        [117, 127, 137, 145, 153, 159, 165, 171, 177, 181, 185, 187, 189, 191],
        [119, 129, 139, 147, 155, 161, 167, 173, 179, 183, 187, 189, 191, 193],
        [121, 131, 141, 149, 157, 163, 169, 175, 181, 185, 189, 191, 193, 195],
        [123, 133, 143, 151, 159, 165, 171, 177, 183, 187, 191, 193, 195, 197],
        [125, 135, 145, 153, 161, 167, 173, 179, 185, 189, 193, 195, 197, 199]
    ]

    private let disabilityLawyerIsharyou = [
        1: 2800, 2: 2370, 3: 1990, 4: 1670, 5: 1400,
        6: 1180, 7: 1000, 8: 830, 9: 690, 10: 550,
        11: 420, 12: 290, 13: 180, 14: 110
    ]

    private let disabilityJibaiseki = [
        1: 1150, 2: 998, 3: 861, 4: 737, 5: 618,
        6: 512, 7: 419, 8: 331, 9: 249, 10: 190,
        11: 136, 12: 94, 13: 57, 14: 32
    ]

    private let lossRates = [
        1: 1.0, 2: 1.0, 3: 1.0, 4: 0.92, 5: 0.79,
        6: 0.67, 7: 0.56, 8: 0.45, 9: 0.35, 10: 0.27,
        11: 0.20, 12: 0.14, 13: 0.09, 14: 0.05
    ]

    var upliftAmount: Int {
        max(lawyerAmount - insuranceAmount, 0)
    }

    var totalLawyerSide: Int {
        lawyerAmount + lostIncome
    }

    func calculateInjury() {
        let hospMonths = min(Int(hospitalizationMonths) ?? 0, 14)
        let outMonths = min(Int(outpatientMonths) ?? 0, 14)
        let visitDays = Int(actualVisitDays) ?? 0
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        let totalDays = hospMonths * 30 + outMonths * 30
        let jibaisekiDays = min(visitDays * 2 + hospMonths * 30, totalDays)
        let jibaisekiBase = jibaisekiDays * 4_300

        let table = injuryType == .mild ? mildTable : severeTable
        let lawyerBase = table[min(hospMonths, table.count - 1)][min(outMonths, table[0].count - 1)] * 10_000
        let insuranceBase = Int(Double(jibaisekiBase + lawyerBase) / 2.0 * 0.8)

        applyFault(jibaiseki: jibaisekiBase, insurance: insuranceBase, lawyer: lawyerBase, lost: 0, fault: fault)
        resultTitle = "入通院慰謝料の概算"
        resultNote = "\(injuryType.label)として、入院\(hospMonths)か月・通院\(outMonths)か月で試算しました。"
    }

    func calculateDisability() {
        let grade = disabilityGrade
        let income = (Int(annualIncome) ?? 400) * 10_000
        let currentAge = Int(age) ?? 35
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        let jibaisekiBase = (disabilityJibaiseki[grade] ?? 32) * 10_000
        let lawyerBase = (disabilityLawyerIsharyou[grade] ?? 110) * 10_000
        let insuranceBase = Int(Double(jibaisekiBase + lawyerBase) / 2.0 * 0.8)
        let lostBase = Int(Double(income) * (lossRates[grade] ?? 0.05) * leibnizCoefficient(years: max(67 - currentAge, 0)))

        applyFault(jibaiseki: jibaisekiBase, insurance: insuranceBase, lawyer: lawyerBase, lost: lostBase, fault: fault)
        resultTitle = "後遺障害 \(grade)級の概算"
        resultNote = "年収\(annualIncome)万円、\(currentAge)歳として逸失利益も試算しました。"
    }

    func calculateDeath() {
        let income = (Int(annualIncome) ?? 400) * 10_000
        let currentAge = Int(age) ?? 35
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        let lawyerBase: Int
        switch victimRole {
        case .breadwinner: lawyerBase = 28_000_000
        case .spouse: lawyerBase = 25_000_000
        case .other: lawyerBase = 20_000_000
        }

        let livingExpenseRate: Double
        switch victimRole {
        case .breadwinner: livingExpenseRate = 0.35
        case .spouse: livingExpenseRate = 0.30
        case .other: livingExpenseRate = 0.50
        }

        let jibaisekiBase = 4_000_000
        let insuranceBase = Int(Double(jibaisekiBase + lawyerBase) / 2.0 * 0.7)
        let lostBase = Int(Double(income) * (1.0 - livingExpenseRate) * leibnizCoefficient(years: max(67 - currentAge, 0)))

        applyFault(jibaiseki: jibaisekiBase, insurance: insuranceBase, lawyer: lawyerBase, lost: lostBase, fault: fault)
        resultTitle = "死亡慰謝料・逸失利益の概算"
        resultNote = "\(victimRole.label)、年収\(annualIncome)万円、\(currentAge)歳として試算しました。"
    }

    func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥\(amount)"
    }

    private func applyFault(jibaiseki: Int, insurance: Int, lawyer: Int, lost: Int, fault: Double) {
        let rate = max(0, 1.0 - fault)
        jibaisekiAmount = Int(Double(jibaiseki) * rate)
        insuranceAmount = Int(Double(insurance) * rate)
        lawyerAmount = Int(Double(lawyer) * rate)
        lostIncome = Int(Double(lost) * rate)

        if insuranceAmount > 0 {
            multiplierText = String(format: "%.1f", Double(lawyerAmount) / Double(insuranceAmount))
        }
        showResult = true
    }

    private func leibnizCoefficient(years: Int) -> Double {
        guard years > 0 else { return 0 }
        let rate = 0.03
        return (1.0 - pow(1.0 + rate, Double(-years))) / rate
    }
}
