import Foundation

/// 农历年模型（内部核心）。
///
/// 负责：
/// - 计算本农历年的朔望月序列
/// - 判定闰月并生成每个月对象
/// - 预计算节气儒略日表供 `Lunar` 使用
final class LunarYear {
    private static let YUAN = ["下", "上", "中"]
    private static let YUN = ["七", "八", "九", "一", "二", "三", "四", "五", "六"]
    private static let LEAP_11: [Int] = [75, 94, 170, 265, 322, 398, 469, 553, 583, 610, 678, 735, 754, 773, 849, 887, 936, 1050, 1069, 1126, 1145, 1164, 1183, 1259, 1278, 1308, 1373, 1403, 1441, 1460, 1498, 1555, 1593, 1612, 1631, 1642, 2033, 2128, 2147, 2242, 2614, 2728, 2910, 3062, 3244, 3339, 3616, 3711, 3730, 3825, 4007, 4159, 4197, 4322, 4341, 4379, 4417, 4531, 4599, 4694, 4713, 4789, 4808, 4971, 5085, 5104, 5161, 5180, 5199, 5294, 5305, 5476, 5677, 5696, 5772, 5791, 5848, 5886, 6049, 6068, 6144, 6163, 6258, 6402, 6440, 6497, 6516, 6630, 6641, 6660, 6679, 6736, 6774, 6850, 6869, 6899, 6918, 6994, 7013, 7032, 7051, 7070, 7089, 7108, 7127, 7146, 7222, 7271, 7290, 7309, 7366, 7385, 7404, 7442, 7461, 7480, 7491, 7499, 7594, 7624, 7643, 7662, 7681, 7719, 7738, 7814, 7863, 7882, 7901, 7939, 7958, 7977, 7996, 8034, 8053, 8072, 8091, 8121, 8159, 8186, 8216, 8235, 8254, 8273, 8311, 8330, 8341, 8349, 8368, 8444, 8463, 8474, 8493, 8531, 8569, 8588, 8626, 8664, 8683, 8694, 8702, 8713, 8721, 8751, 8789, 8808, 8816, 8827, 8846, 8884, 8903, 8922, 8941, 8971, 9036, 9066, 9085, 9104, 9123, 9142, 9161, 9180, 9199, 9218, 9256, 9294, 9313, 9324, 9343, 9362, 9381, 9419, 9438, 9476, 9514, 9533, 9544, 9552, 9563, 9571, 9582, 9601, 9639, 9658, 9666, 9677, 9696, 9734, 9753, 9772, 9791, 9802, 9821, 9886, 9897, 9916, 9935, 9954, 9973, 9992]
    private static let LEAP_12: [Int] = [37, 56, 113, 132, 151, 189, 208, 227, 246, 284, 303, 341, 360, 379, 417, 436, 458, 477, 496, 515, 534, 572, 591, 629, 648, 667, 697, 716, 792, 811, 830, 868, 906, 925, 944, 963, 982, 1001, 1020, 1039, 1058, 1088, 1153, 1202, 1221, 1240, 1297, 1335, 1392, 1411, 1422, 1430, 1517, 1525, 1536, 1574, 3358, 3472, 3806, 3988, 4751, 4941, 5066, 5123, 5275, 5343, 5438, 5457, 5495, 5533, 5552, 5715, 5810, 5829, 5905, 5924, 6421, 6535, 6793, 6812, 6888, 6907, 7002, 7184, 7260, 7279, 7374, 7556, 7746, 7757, 7776, 7833, 7852, 7871, 7966, 8015, 8110, 8129, 8148, 8224, 8243, 8338, 8406, 8425, 8482, 8501, 8520, 8558, 8596, 8607, 8615, 8645, 8740, 8778, 8835, 8865, 8930, 8960, 8979, 8998, 9017, 9055, 9074, 9093, 9112, 9150, 9188, 9237, 9275, 9332, 9351, 9370, 9408, 9427, 9446, 9457, 9465, 9495, 9560, 9590, 9628, 9647, 9685, 9715, 9742, 9780, 9810, 9818, 9829, 9848, 9867, 9905, 9924, 9943, 9962, 10000]
    private static let YMC = [11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    /// 单年缓存，避免频繁重复推算同一年
    private static var cacheYear: LunarYear?

    private let year: Int
    private let ganIndex: Int
    private let zhiIndex: Int
    private var months: [LunarMonth] = []
    private var jieQiJulianDays: [Double] = []

    private func t(_ text: String) -> String { text }

    private init(year: Int) {
        self.year = year
        // 干支年索引基于 4 年甲子基准
        let offset = year - 4
        var gi = offset % 10
        var zi = offset % 12
        if gi < 0 { gi += 10 }
        if zi < 0 { zi += 12 }
        self.ganIndex = gi
        self.zhiIndex = zi
        _ = compute()
    }

    private static func inLeap(_ arr: [Int], _ n: Int) -> Bool {
        return arr.contains(n)
    }

    static func fromYear(_ lunarYear: Int) -> LunarYear {
        // 单例缓存命中时直接返回
        if let c = cacheYear, c.getYear() == lunarYear {
            return c
        }
        let y = LunarYear(year: lunarYear)
        cacheYear = y
        return y
    }

    func getYear() -> Int { year }
    func getGanIndex() -> Int { ganIndex }
    func getZhiIndex() -> Int { zhiIndex }
    func getGan() -> String { t(LunarUtil.GAN[ganIndex + 1]) }
    func getZhi() -> String { t(LunarUtil.ZHI[zhiIndex + 1]) }
    func getGanZhi() -> String { getGan() + getZhi() }
    func getJieQiJulianDays() -> [Double] { jieQiJulianDays }

    func getDayCount() -> Int {
        // 当前农历年的总天数（仅统计本年的月）
        var n = 0
        for m in months where m.getYear() == year {
            n += m.getDayCount()
        }
        return n
    }

    func getMonthsInYear() -> [LunarMonth] {
        return months.filter { $0.getYear() == year }
    }

    func getMonthCount() -> Int {
        return getMonthsInYear().count
    }

    func getMonths() -> [LunarMonth] { months }

    func getMonth(_ lunarMonth: Int) -> LunarMonth? {
        for m in months where m.getYear() == year && m.getMonth() == lunarMonth {
            return m
        }
        return nil
    }

    func getLeapMonth() -> Int {
        for m in months where m.getYear() == year && m.isLeap() {
            return abs(m.getMonth())
        }
        return 0
    }

    private func getZaoByGan(_ index: Int, _ name: String) -> String {
        var offset = index - Solar.fromJulianDay(getMonth(1)!.getFirstJulianDay()).getLunar().getDayGanIndex()
        if offset < 0 { offset += 10 }
        return name.replacingOccurrences(of: "几", with: LunarUtil.NUMBER[offset + 1])
    }

    private func getZaoByZhi(_ index: Int, _ name: String) -> String {
        var offset = index - Solar.fromJulianDay(getMonth(1)!.getFirstJulianDay()).getLunar().getDayZhiIndex()
        if offset < 0 { offset += 12 }
        return name.replacingOccurrences(of: "几", with: LunarUtil.NUMBER[offset + 1])
    }

    func getTouLiang() -> String { t(getZaoByZhi(0, "几鼠偷粮")) }
    func getCaoZi() -> String { t(getZaoByZhi(0, "草子几分")) }
    func getGengTian() -> String { t(getZaoByZhi(1, "几牛耕田")) }
    func getHuaShou() -> String { t(getZaoByZhi(3, "花收几分")) }
    func getZhiShui() -> String { t(getZaoByZhi(4, "几龙治水")) }
    func getTuoGu() -> String { t(getZaoByZhi(6, "几马驮谷")) }
    func getQiangMi() -> String { t(getZaoByZhi(9, "几鸡抢米")) }
    func getKanCan() -> String { t(getZaoByZhi(9, "几姑看蚕")) }
    func getGongZhu() -> String { t(getZaoByZhi(11, "几屠共猪")) }
    func getJiaTian() -> String { t(getZaoByGan(0, "甲田几分")) }
    func getFenBing() -> String { t(getZaoByGan(2, "几人分饼")) }
    func getDeJin() -> String { t(getZaoByGan(7, "几日得金")) }
    func getRenBing() -> String { t(getZaoByGan(2, getZaoByZhi(2, "几人几丙"))) }
    func getRenChu() -> String { t(getZaoByGan(3, getZaoByZhi(2, "几人几锄"))) }
    func getYuan() -> String { t(LunarYear.YUAN[Int(floor(Double(year + 2696) / 60.0)) % 3] + "元") }
    func getYun() -> String { t(LunarYear.YUN[Int(floor(Double(year + 2696) / 20.0)) % 9] + "运") }

    func getPositionXi() -> String { t(LunarUtil.POSITION_XI[ganIndex + 1]) }
    func getPositionXiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionXi()] ?? "") }
    func getPositionYangGui() -> String { t(LunarUtil.POSITION_YANG_GUI[ganIndex + 1]) }
    func getPositionYangGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionYangGui()] ?? "") }
    func getPositionYinGui() -> String { t(LunarUtil.POSITION_YIN_GUI[ganIndex + 1]) }
    func getPositionYinGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionYinGui()] ?? "") }
    func getPositionFu(_ sect: Int) -> String { t((sect == 1 ? LunarUtil.POSITION_FU : LunarUtil.POSITION_FU_2)[ganIndex + 1]) }
    func getPositionFuDesc(_ sect: Int) -> String { t(LunarUtil.POSITION_DESC[getPositionFu(sect)] ?? "") }
    func getPositionCai() -> String { t(LunarUtil.POSITION_CAI[ganIndex + 1]) }
    func getPositionCaiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionCai()] ?? "") }
    func getPositionTaiSui() -> String { t(LunarUtil.POSITION_TAI_SUI_YEAR[zhiIndex]) }
    func getPositionTaiSuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionTaiSui()] ?? "") }

    func toString() -> String { String(year) }
    func toFullString() -> String { "\(year)年" }

    func next(_ years: Int) -> LunarYear { LunarYear.fromYear(year + years) }

    @discardableResult
    private func compute() -> LunarYear {
        // 重新计算时先清空缓存字段
        months = []
        jieQiJulianDays = []

        var jq: [Double] = []
        var hs: [Double] = []
        var dayCounts: [Int] = []
        var monthIndex: [Int] = []

        let currentYear = year
        // 估算当年冬至附近，再向前后展开节气
        var jd = floor(Double(currentYear - 2000) * 365.2422 + 180)
        var w = floor((jd - 355 + 183) / 365.2422) * 365.2422 + 355
        if ShouXingUtil.calcQi(w) > jd {
            w -= 365.2422
        }
        for i in 0..<26 {
            jq.append(ShouXingUtil.calcQi(w + 15.2184 * Double(i)))
        }
        // 生成完整节气儒略日表（与 JIE_QI_IN_USE 顺序对应）
        for i in 0..<LunarUtil.JIE_QI_IN_USE.count {
            if i == 0 {
                jd = ShouXingUtil.qiAccurate2(jq[0] - 15.2184)
            } else if i <= 26 {
                jd = ShouXingUtil.qiAccurate2(jq[i - 1])
            } else {
                jd = ShouXingUtil.qiAccurate2(jq[25] + 15.2184 * Double(i - 26))
            }
            jieQiJulianDays.append(jd + Solar.J2000)
        }

        // 以朔日计算农历月边界
        w = ShouXingUtil.calcShuo(jq[0])
        if w > jq[0] { w -= 29.53 }
        for i in 0..<16 { hs.append(ShouXingUtil.calcShuo(w + 29.5306 * Double(i))) }
        for i in 0..<15 {
            dayCounts.append(Int(floor(hs[i + 1] - hs[i])))
            monthIndex.append(i)
        }

        let prevYear = currentYear - 1
        // 默认无闰（16 表示不在 0...14 月槽中）
        var leapIndex = 16
        if LunarYear.inLeap(LunarYear.LEAP_11, currentYear) {
            leapIndex = 13
        } else if LunarYear.inLeap(LunarYear.LEAP_12, currentYear) {
            leapIndex = 14
        } else if hs[13] <= jq[24] {
            var i = 1
            while hs[i + 1] > jq[2 * i] && i < 13 { i += 1 }
            leapIndex = i
        }
        // 闰月后的月序需回拨一位，保持月份编号连续
        if leapIndex < 15 {
            for j in leapIndex..<15 {
                monthIndex[j] -= 1
            }
        }

        var fm = -1
        var index = -1
        var y = prevYear
        // 组合出 15 个候选月，再依据闰月规则标记负月
        for i in 0..<15 {
            let dm = hs[i] + Solar.J2000
            var v2 = monthIndex[i]
            var mc = LunarYear.YMC[v2 % 12]
            if dm >= 1724360 && dm < 1729794 {
                mc = LunarYear.YMC[(v2 + 1) % 12]
            } else if dm >= 1807724 && dm < 1808699 {
                mc = LunarYear.YMC[(v2 + 1) % 12]
            } else if dm == 1729794 || dm == 1808699 {
                mc = 12
            }
            if fm == -1 {
                fm = mc
                index = mc
            }
            if mc < fm {
                y += 1
                index = 1
            }
            fm = mc
            if i == leapIndex {
                mc = -mc
            } else if dm == 1729794 || dm == 1808699 {
                mc = -11
            }
            months.append(LunarMonth.create(year: y, month: mc, dayCount: dayCounts[i], firstJulianDay: hs[i] + Solar.J2000, index: index))
            index += 1
        }
        return self
    }
}
