import Foundation

/// 农历月模型（内部使用）。
///
/// 包含：
/// - 月份基本信息（年、月、天数、月首儒略日）
/// - 月干支与方位等派生信息
final class LunarMonth {
    private let year: Int
    private let month: Int
    private let dayCount: Int
    private let firstJulianDay: Double
    private let index: Int
    private let zhiIndex: Int

    private func t(_ text: String) -> String { text }

    private init(year: Int, month: Int, dayCount: Int, firstJulianDay: Double, index: Int) {
        self.year = year
        self.month = month
        self.dayCount = dayCount
        self.firstJulianDay = firstJulianDay
        self.index = index
        self.zhiIndex = (abs(month) - 1 + LunarUtil.BASE_MONTH_ZHI_INDEX) % 12
    }

    static func fromYm(_ lunarYear: Int, _ lunarMonth: Int) -> LunarMonth? {
        // 月对象统一从 LunarYear 查询，避免跨年闰月逻辑分散
        return LunarYear.fromYear(lunarYear).getMonth(lunarMonth)
    }

    static func create(year: Int, month: Int, dayCount: Int, firstJulianDay: Double, index: Int) -> LunarMonth {
        return LunarMonth(year: year, month: month, dayCount: dayCount, firstJulianDay: firstJulianDay, index: index)
    }

    func getIndex() -> Int { index }
    func getGanIndex() -> Int {
        // 月干由“年干起月”推算
        let offset = (LunarYear.fromYear(year).getGanIndex() + 1) % 5 * 2
        return (abs(month) - 1 + offset) % 10
    }
    func getZhiIndex() -> Int { zhiIndex }
    func getGan() -> String { t(LunarUtil.GAN[getGanIndex() + 1]) }
    func getZhi() -> String { t(LunarUtil.ZHI[zhiIndex + 1]) }
    func getGanZhi() -> String { getGan() + getZhi() }
    func getYear() -> Int { year }
    func getMonth() -> Int { month }
    func getDayCount() -> Int { dayCount }
    func getFirstJulianDay() -> Double { firstJulianDay }
    func isLeap() -> Bool { month < 0 }

    func getPositionXi() -> String { t(LunarUtil.POSITION_XI[getGanIndex() + 1]) }
    func getPositionXiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionXi()] ?? "") }
    func getPositionYangGui() -> String { t(LunarUtil.POSITION_YANG_GUI[getGanIndex() + 1]) }
    func getPositionYangGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionYangGui()] ?? "") }
    func getPositionYinGui() -> String { t(LunarUtil.POSITION_YIN_GUI[getGanIndex() + 1]) }
    func getPositionYinGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionYinGui()] ?? "") }
    func getPositionFu(_ sect: Int) -> String { t((sect == 1 ? LunarUtil.POSITION_FU : LunarUtil.POSITION_FU_2)[getGanIndex() + 1]) }
    func getPositionFuDesc(_ sect: Int) -> String { t(LunarUtil.POSITION_DESC[getPositionFu(sect)] ?? "") }
    func getPositionCai() -> String { t(LunarUtil.POSITION_CAI[getGanIndex() + 1]) }
    func getPositionCaiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionCai()] ?? "") }

    func getPositionTaiSui() -> String {
        // 月太岁方位规则：部分月份固定，其他按月干推导
        var p: String
        let m = abs(month)
        switch m {
        case 1,5,9:
            p = "艮"
        case 3,7,11:
            p = "坤"
        case 4,8,12:
            p = "巽"
        default:
            p = LunarUtil.POSITION_GAN[Solar.fromJulianDay(firstJulianDay).getLunar().getMonthGanIndex()]
        }
        return t(p)
    }

    func getPositionTaiSuiDesc() -> String { t(LunarUtil.POSITION_DESC[getPositionTaiSui()] ?? "") }

    func next(_ n: Int) -> LunarMonth? {
        // 在农历月序列中前后跳转，自动处理跨年与闰月
        if n == 0 { return LunarMonth.fromYm(year, month) }
        var rest = abs(n)
        var ny = year
        var iy = ny
        var im = month
        var months = LunarYear.fromYear(ny).getMonths()
        if n > 0 {
            while true {
                var index = 0
                for (i, m) in months.enumerated() {
                    if m.getYear() == iy && m.getMonth() == im { index = i; break }
                }
                let more = months.count - index - 1
                if rest < more { return months[index + rest] }
                rest -= more
                let lastMonth = months[months.count - 1]
                iy = lastMonth.getYear()
                im = lastMonth.getMonth()
                ny += 1
                months = LunarYear.fromYear(ny).getMonths()
            }
        } else {
            while true {
                var index = 0
                for (i, m) in months.enumerated() {
                    if m.getYear() == iy && m.getMonth() == im { index = i; break }
                }
                if rest <= index { return months[index - rest] }
                rest -= index
                let firstMonth = months[0]
                iy = firstMonth.getYear()
                im = firstMonth.getMonth()
                ny -= 1
                months = LunarYear.fromYear(ny).getMonths()
            }
        }
    }

    func toString() -> String {
        return "\(year)年\(isLeap() ? "闰" : "")\(LunarUtil.MONTH[abs(month)])月(\(dayCount))天"
    }
}
