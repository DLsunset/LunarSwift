import Foundation

/// 八字四柱轻量封装（内部使用）。
///
/// 当前版本仅保留 `Date+LunarFeatures` 所需的四柱文本输出，
/// 不包含神煞、十神等扩展计算。
final class EightChar {
    private let lunar: Lunar

    private init(lunar: Lunar) {
        self.lunar = lunar
    }

    static func fromLunar(_ lunar: Lunar) -> EightChar {
        return EightChar(lunar: lunar)
    }

    /// 年柱（采用精确口径）
    func getYear() -> String { lunar.getYearInGanZhiExact() }
    /// 月柱（采用精确口径）
    func getMonth() -> String { lunar.getMonthInGanZhiExact() }
    /// 日柱（采用子时换日后的精确口径）
    func getDay() -> String { lunar.getDayInGanZhiExact2() }
    /// 时柱
    func getTime() -> String { lunar.getTimeInGanZhi() }

}
