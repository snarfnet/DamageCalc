import SwiftUI

enum InjuryType {
    case mild
    case severe
}

enum VictimRole {
    case breadwinner
    case spouse
    case other
}

class DamageCalcViewModel: ObservableObject {
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

    // 弁護士基準（赤い本）入通院慰謝料 別表I（重傷）万円
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

    // 弁護士基準（赤い本）入通院慰謝料 別表II（軽傷・むちうち等）万円
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

    // 後遺障害等級別 弁護士基準慰謝料（万円）
    private let disabilityLawyerIsharyou: [Int: Int] = [
        1: 2800, 2: 2370, 3: 1990, 4: 1670, 5: 1400,
        6: 1180, 7: 1000, 8: 830, 9: 690, 10: 550,
        11: 420, 12: 290, 13: 180, 14: 110
    ]

    // 後遺障害等級別 自賠責基準慰謝料（万円）
    private let disabilityJibaiseki: [Int: Int] = [
        1: 1150, 2: 998, 3: 861, 4: 737, 5: 618,
        6: 512, 7: 419, 8: 331, 9: 249, 10: 190,
        11: 136, 12: 94, 13: 57, 14: 32
    ]

    // 労働能力喪失率
    private let lossRates: [Int: Double] = [
        1: 1.0, 2: 1.0, 3: 1.0, 4: 0.92, 5: 0.79,
        6: 0.67, 7: 0.56, 8: 0.45, 9: 0.35, 10: 0.27,
        11: 0.20, 12: 0.14, 13: 0.09, 14: 0.05
    ]

    func calculateInjury() {
        let hospMonths = min(Int(hospitalizationMonths) ?? 0, 14)
        let outMonths = min(Int(outpatientMonths) ?? 0, 14)
        let visitDays = Int(actualVisitDays) ?? 0
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        // 自賠責基準: 4,300円 × min(実通院日数×2, 通院期間日数)
        let totalDays = hospMonths * 30 + outMonths * 30
        let jibaisekiDays = min(visitDays * 2 + hospMonths * 30, totalDays)
        let jibaisekiBase = jibaisekiDays * 4300

        // 弁護士基準: 表から読み取り
        let table = injuryType == .mild ? mildTable : severeTable
        let row = min(hospMonths, table.count - 1)
        let col = min(outMonths, (table.first?.count ?? 1) - 1)
        let lawyerBase = table[row][col] * 10000

        // 任意保険基準: 自賠責と弁護士の中間（概算）
        let insuranceBase = Int(Double(jibaisekiBase + lawyerBase) / 2.0 * 0.8)

        // 過失相殺
        jibaisekiAmount = Int(Double(jibaisekiBase) * (1.0 - fault))
        insuranceAmount = Int(Double(insuranceBase) * (1.0 - fault))
        lawyerAmount = Int(Double(lawyerBase) * (1.0 - fault))
        lostIncome = 0

        if lawyerAmount > 0 && insuranceAmount > 0 {
            let mult = Double(lawyerAmount) / Double(insuranceAmount)
            multiplierText = String(format: "%.1f", mult)
        }

        showResult = true
    }

    func calculateDisability() {
        let grade = disabilityGrade
        let income = (Int(annualIncome) ?? 400) * 10000
        let currentAge = Int(age) ?? 35
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        let jibaisekiIsharyou = (disabilityJibaiseki[grade] ?? 32) * 10000
        let lawyerIsharyou = (disabilityLawyerIsharyou[grade] ?? 110) * 10000
        let insuranceIsharyou = Int(Double(jibaisekiIsharyou + lawyerIsharyou) / 2.0 * 0.8)

        // 逸失利益 = 年収 × 労働能力喪失率 × ライプニッツ係数
        let lossRate = lossRates[grade] ?? 0.05
        let yearsToRetirement = max(67 - currentAge, 0)
        let leibniz = leibnizCoefficient(years: yearsToRetirement)
        let lostIncomeBase = Int(Double(income) * lossRate * leibniz)

        jibaisekiAmount = Int(Double(jibaisekiIsharyou) * (1.0 - fault))
        insuranceAmount = Int(Double(insuranceIsharyou) * (1.0 - fault))
        lawyerAmount = Int(Double(lawyerIsharyou) * (1.0 - fault))
        lostIncome = Int(Double(lostIncomeBase) * (1.0 - fault))

        if lawyerAmount > 0 && insuranceAmount > 0 {
            let mult = Double(lawyerAmount) / Double(insuranceAmount)
            multiplierText = String(format: "%.1f", mult)
        }

        showResult = true
    }

    func calculateDeath() {
        let income = (Int(annualIncome) ?? 400) * 10000
        let currentAge = Int(age) ?? 35
        let fault = Double(Int(faultPercent) ?? 0) / 100.0

        // 死亡慰謝料
        let lawyerIsharyou: Int
        switch victimRole {
        case .breadwinner: lawyerIsharyou = 28000000
        case .spouse: lawyerIsharyou = 25000000
        case .other: lawyerIsharyou = 20000000
        }
        let jibaisekiIsharyou = 4000000 // 自賠責: 本人400万
        let insuranceIsharyou = Int(Double(jibaisekiIsharyou + lawyerIsharyou) / 2.0 * 0.7)

        // 逸失利益 = 年収 × (1-生活費控除率) × ライプニッツ係数
        let livingExpenseRate: Double
        switch victimRole {
        case .breadwinner: livingExpenseRate = 0.35
        case .spouse: livingExpenseRate = 0.30
        case .other: livingExpenseRate = 0.50
        }

        let yearsToRetirement = max(67 - currentAge, 0)
        let leibniz = leibnizCoefficient(years: yearsToRetirement)
        let lostIncomeBase = Int(Double(income) * (1.0 - livingExpenseRate) * leibniz)

        jibaisekiAmount = Int(Double(jibaisekiIsharyou) * (1.0 - fault))
        insuranceAmount = Int(Double(insuranceIsharyou) * (1.0 - fault))
        lawyerAmount = Int(Double(lawyerIsharyou) * (1.0 - fault))
        lostIncome = Int(Double(lostIncomeBase) * (1.0 - fault))

        if lawyerAmount > 0 && insuranceAmount > 0 {
            let mult = Double(lawyerAmount) / Double(insuranceAmount)
            multiplierText = String(format: "%.1f", mult)
        }

        showResult = true
    }

    private func leibnizCoefficient(years: Int) -> Double {
        guard years > 0 else { return 0 }
        let rate = 0.03 // 民法改正後の法定利率3%
        return (1.0 - pow(1.0 + rate, Double(-years))) / rate
    }
}
