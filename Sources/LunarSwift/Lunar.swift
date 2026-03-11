import Foundation

/// 农历主模型（内部核心）。
///
/// 说明：
/// - 负责从 `Solar` 计算农历年月日时、干支、节气等索引。
/// - `Date+LunarFeatures` 中的所有对外能力最终都依赖本类。
final class Lunar {
    private var lang: String
    private let year: Int
    private let month: Int
    private let day: Int
    private let hour: Int
    private let minute: Int
    private let second: Int

    private let timeGanIndex: Int
    private let timeZhiIndex: Int
    private let dayGanIndex: Int
    private let dayZhiIndex: Int
    private let dayGanIndexExact: Int
    private let dayZhiIndexExact: Int
    private let dayGanIndexExact2: Int
    private let dayZhiIndexExact2: Int

    private let monthGanIndex: Int
    private let monthZhiIndex: Int
    private let monthGanIndexExact: Int
    private let monthZhiIndexExact: Int

    private let yearGanIndex: Int
    private let yearZhiIndex: Int
    private let yearGanIndexByLiChun: Int
    private let yearZhiIndexByLiChun: Int
    private let yearGanIndexExact: Int
    private let yearZhiIndexExact: Int

    private let weekIndex: Int

    private var jieQi: [String: Solar]
    private var jieQiList: [String]

    private let solar: Solar
    private var eightChar: EightChar?

    /// 文本透传（保留给多语言扩展，当前固定中文）
    private func t(_ text: String) -> String { text }
    /// 数组透传（保留给多语言扩展，当前固定中文）
    private func ta(_ list: [String]) -> [String] { list }

    private init(lang: String,
                 year: Int,
                 month: Int,
                 day: Int,
                 hour: Int,
                 minute: Int,
                 second: Int,
                 timeGanIndex: Int,
                 timeZhiIndex: Int,
                 dayGanIndex: Int,
                 dayZhiIndex: Int,
                 dayGanIndexExact: Int,
                 dayZhiIndexExact: Int,
                 dayGanIndexExact2: Int,
                 dayZhiIndexExact2: Int,
                 monthGanIndex: Int,
                 monthZhiIndex: Int,
                 monthGanIndexExact: Int,
                 monthZhiIndexExact: Int,
                 yearGanIndex: Int,
                 yearZhiIndex: Int,
                 yearGanIndexByLiChun: Int,
                 yearZhiIndexByLiChun: Int,
                 yearGanIndexExact: Int,
                 yearZhiIndexExact: Int,
                 weekIndex: Int,
                 jieQi: [String: Solar],
                 jieQiList: [String],
                 solar: Solar) {
        self.lang = lang
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeGanIndex = timeGanIndex
        self.timeZhiIndex = timeZhiIndex
        self.dayGanIndex = dayGanIndex
        self.dayZhiIndex = dayZhiIndex
        self.dayGanIndexExact = dayGanIndexExact
        self.dayZhiIndexExact = dayZhiIndexExact
        self.dayGanIndexExact2 = dayGanIndexExact2
        self.dayZhiIndexExact2 = dayZhiIndexExact2
        self.monthGanIndex = monthGanIndex
        self.monthZhiIndex = monthZhiIndex
        self.monthGanIndexExact = monthGanIndexExact
        self.monthZhiIndexExact = monthZhiIndexExact
        self.yearGanIndex = yearGanIndex
        self.yearZhiIndex = yearZhiIndex
        self.yearGanIndexByLiChun = yearGanIndexByLiChun
        self.yearZhiIndexByLiChun = yearZhiIndexByLiChun
        self.yearGanIndexExact = yearGanIndexExact
        self.yearZhiIndexExact = yearZhiIndexExact
        self.weekIndex = weekIndex
        self.jieQi = jieQi
        self.jieQiList = jieQiList
        self.solar = solar
    }

    // MARK: - Factory
    // 这组工厂方法统一汇聚到 `new(...)`，保证索引计算逻辑只有一份。

    static func fromSolar(_ solar: Solar) -> Lunar {
        // 根据“距离农历月首的天数”定位到对应农历年月日
        var lunarYear = 0
        var lunarMonth = 0
        var lunarDay = 0
        let ly = LunarYear.fromYear(solar.getYear())
        let lms = ly.getMonths()
        for m in lms {
            let days = solar.subtract(Solar.fromJulianDay(m.getFirstJulianDay()))
            if days < m.getDayCount() {
                lunarYear = m.getYear()
                lunarMonth = m.getMonth()
                lunarDay = days + 1
                break
            }
        }
        return new(year: lunarYear, month: lunarMonth, day: lunarDay,
                   hour: solar.getHour(), minute: solar.getMinute(), second: solar.getSecond(),
                   solar: solar, lunarYear: ly)
    }

    static func fromDate(_ date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> Lunar {
        return fromSolar(Solar.fromDate(date, calendar: calendar))
    }

    static func fromYmd(_ y: Int, _ m: Int, _ d: Int) -> Lunar {
        return fromYmdHms(y, m, d, 0, 0, 0)
    }

    static func fromYmdHms(_ lunarYear: Int, _ lunarMonth: Int, _ lunarDay: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Lunar {
        // 先校验农历日期合法，再借助 Solar 走统一计算链
        let y = LunarYear.fromYear(lunarYear)
        guard let m = y.getMonth(lunarMonth) else {
            preconditionFailure("wrong lunar year \(lunarYear) month \(lunarMonth)")
        }
        if lunarDay < 1 { preconditionFailure("lunar day must bigger than 0") }
        let days = m.getDayCount()
        if lunarDay > days {
            preconditionFailure("only \(days) days in lunar year \(lunarYear) month \(lunarMonth)")
        }
        let noon = Solar.fromJulianDay(m.getFirstJulianDay() + Double(lunarDay - 1))
        let solar = Solar.fromYmdHms(noon.getYear(), noon.getMonth(), noon.getDay(), hour, minute, second)
        let ly = (noon.getYear() != lunarYear) ? LunarYear.fromYear(noon.getYear()) : y
        return new(year: lunarYear, month: lunarMonth, day: lunarDay, hour: hour, minute: minute, second: second, solar: solar, lunarYear: ly)
    }

    // MARK: - Core compute
    // 核心流程：节气表 -> 年柱 -> 月柱 -> 日柱 -> 时柱 -> 汇总索引

    private struct GanZhi {
        let timeGanIndex: Int
        let timeZhiIndex: Int
        let dayGanIndex: Int
        let dayZhiIndex: Int
        let dayGanIndexExact: Int
        let dayZhiIndexExact: Int
        let dayGanIndexExact2: Int
        let dayZhiIndexExact2: Int
        let monthGanIndex: Int
        let monthZhiIndex: Int
        let monthGanIndexExact: Int
        let monthZhiIndexExact: Int
        let yearGanIndex: Int
        let yearZhiIndex: Int
        let yearGanIndexByLiChun: Int
        let yearZhiIndexByLiChun: Int
        let yearGanIndexExact: Int
        let yearZhiIndexExact: Int
        let weekIndex: Int
        let jieQi: [String: Solar]
        let jieQiList: [String]
    }

    private static func computeJieQi(_ ly: LunarYear) -> (list: [String], map: [String: Solar]) {
        // 将节气儒略日表转换为 Solar 结构，便于日期比较
        var list: [String] = []
        var map: [String: Solar] = [:]
        let julianDays = ly.getJieQiJulianDays()
        for (i, key) in LunarUtil.JIE_QI_IN_USE.enumerated() {
            list.append(key)
            map[key] = Solar.fromJulianDay(julianDays[i])
        }
        return (list, map)
    }

    private static func computeYear(_ solar: Solar, _ year: Int, _ jieQi: [String: Solar]) -> (Int, Int, Int, Int, Int, Int) {
        // 年柱有 3 套：常规、按立春、按立春时刻精确
        let offset = year - 4
        var yearGanIndex = offset % 10
        var yearZhiIndex = offset % 12
        if yearGanIndex < 0 { yearGanIndex += 10 }
        if yearZhiIndex < 0 { yearZhiIndex += 12 }

        var g = yearGanIndex
        var z = yearZhiIndex
        var gExact = yearGanIndex
        var zExact = yearZhiIndex

        let solarYear = solar.getYear()
        let solarYmd = solar.toYmd()
        let solarYmdHms = solar.toYmdHms()

        var liChun = jieQi["LI_CHUN"] ?? jieQi["立春"] ?? solar
        if liChun.getYear() != solarYear {
            liChun = jieQi["LI_CHUN"] ?? jieQi["立春"] ?? liChun
        }
        let liChunYmd = liChun.toYmd()
        let liChunYmdHms = liChun.toYmdHms()

        if year == solarYear {
            if solarYmd < liChunYmd { g -= 1; z -= 1 }
            if solarYmdHms < liChunYmdHms { gExact -= 1; zExact -= 1 }
        } else if year < solarYear {
            if solarYmd >= liChunYmd { g += 1; z += 1 }
            if solarYmdHms >= liChunYmdHms { gExact += 1; zExact += 1 }
        }

        let yearGanIndexByLiChun = (g < 0 ? g + 10 : g) % 10
        let yearZhiIndexByLiChun = (z < 0 ? z + 12 : z) % 12
        let yearGanIndexExact = (gExact < 0 ? gExact + 10 : gExact) % 10
        let yearZhiIndexExact = (zExact < 0 ? zExact + 12 : zExact) % 12

        return (yearGanIndex, yearZhiIndex, yearGanIndexByLiChun, yearZhiIndexByLiChun, yearGanIndexExact, yearZhiIndexExact)
    }

    private static func computeMonth(_ solar: Solar, _ yearGanIndexByLiChun: Int, _ yearGanIndexExact: Int, _ jieQi: [String: Solar]) -> (Int, Int, Int, Int) {
        // 月柱按“节”切换（不是中气），并保留按日/按时刻两套口径
        let size = LunarUtil.JIE_QI_IN_USE.count
        var start: Solar? = nil
        var index = -3
        var end: Solar = Solar.fromYmd(1900,1,1)
        for i in stride(from: 0, to: size, by: 2) {
            end = jieQi[LunarUtil.JIE_QI_IN_USE[i]]!
            let ymd = solar.toYmd()
            let symd = start == nil ? ymd : start!.toYmd()
            if ymd >= symd && ymd < end.toYmd() { break }
            start = end
            index += 1
        }
        var offset = (((yearGanIndexByLiChun + (index < 0 ? 1 : 0)) % 5 + 1) * 2) % 10
        let monthGanIndex = ((index < 0 ? index + 10 : index) + offset) % 10
        let monthZhiIndex = ((index < 0 ? index + 12 : index) + LunarUtil.BASE_MONTH_ZHI_INDEX) % 12

        start = nil
        index = -3
        for i in stride(from: 0, to: size, by: 2) {
            end = jieQi[LunarUtil.JIE_QI_IN_USE[i]]!
            let time = solar.toYmdHms()
            let stime = start == nil ? time : start!.toYmdHms()
            if time >= stime && time < end.toYmdHms() { break }
            start = end
            index += 1
        }
        offset = (((yearGanIndexExact + (index < 0 ? 1 : 0)) % 5 + 1) * 2) % 10
        let monthGanIndexExact = ((index < 0 ? index + 10 : index) + offset) % 10
        let monthZhiIndexExact = ((index < 0 ? index + 12 : index) + LunarUtil.BASE_MONTH_ZHI_INDEX) % 12

        return (monthGanIndex, monthZhiIndex, monthGanIndexExact, monthZhiIndexExact)
    }

    private static func computeDay(_ solar: Solar, _ hour: Int, _ minute: Int) -> (Int, Int, Int, Int, Int, Int) {
        // 日柱计算基于儒略日，23:00 后按“子时换日”修正精确口径
        let noon = Solar.fromYmdHms(solar.getYear(), solar.getMonth(), solar.getDay(), 12, 0, 0)
        let offset = Int(floor(noon.getJulianDay())) - 11
        var dayGanIndex = offset % 10
        var dayZhiIndex = offset % 12
        var dayGanExact = dayGanIndex
        var dayZhiExact = dayZhiIndex
        let hm = String(format: "%02d:%02d", hour, minute)
        if hm >= "23:00" && hm <= "23:59" {
            dayGanExact += 1
            if dayGanExact >= 10 { dayGanExact -= 10 }
            dayZhiExact += 1
            if dayZhiExact >= 12 { dayZhiExact -= 12 }
        }
        return (dayGanIndex, dayZhiIndex, dayGanExact, dayZhiExact, dayGanExact, dayZhiExact)
    }

    private static func computeTime(_ dayGanIndexExact: Int, _ hour: Int, _ minute: Int) -> (Int, Int) {
        // 时柱：先定时支，再按“日干起时”得到时干
        let timeZhiIndex = LunarUtil.getTimeZhiIndex(String(format: "%02d:%02d", hour, minute))
        let timeGanIndex = (dayGanIndexExact % 5 * 2 + timeZhiIndex) % 10
        return (timeGanIndex, timeZhiIndex)
    }

    private static func computeWeek(_ solar: Solar) -> Int {
        return solar.getWeek()
    }

    private static func compute(_ year: Int, _ hour: Int, _ minute: Int, _ second: Int, _ solar: Solar, _ ly: LunarYear) -> GanZhi {
        let (list, map) = computeJieQi(ly)
        let (yg, yz, ygByLC, yzByLC, ygExact, yzExact) = computeYear(solar, year, map)
        let (mg, mz, mgExact, mzExact) = computeMonth(solar, ygByLC, ygExact, map)
        let (dg, dz, dgExact, dzExact, dgExact2, dzExact2) = computeDay(solar, hour, minute)
        let (tg, tz) = computeTime(dgExact, hour, minute)
        let week = computeWeek(solar)
        return GanZhi(
            timeGanIndex: tg,
            timeZhiIndex: tz,
            dayGanIndex: dg,
            dayZhiIndex: dz,
            dayGanIndexExact: dgExact,
            dayZhiIndexExact: dzExact,
            dayGanIndexExact2: dgExact2,
            dayZhiIndexExact2: dzExact2,
            monthGanIndex: mg,
            monthZhiIndex: mz,
            monthGanIndexExact: mgExact,
            monthZhiIndexExact: mzExact,
            yearGanIndex: yg,
            yearZhiIndex: yz,
            yearGanIndexByLiChun: ygByLC,
            yearZhiIndexByLiChun: yzByLC,
            yearGanIndexExact: ygExact,
            yearZhiIndexExact: yzExact,
            weekIndex: week,
            jieQi: map,
            jieQiList: list
        )
    }

    private static func new(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, solar: Solar, lunarYear: LunarYear) -> Lunar {
        // 所有基础索引一次性算完，后续 getter 只做查表拼装
        let gz = compute(year, hour, minute, second, solar, lunarYear)
        return Lunar(
            lang: "chs",
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            timeGanIndex: gz.timeGanIndex,
            timeZhiIndex: gz.timeZhiIndex,
            dayGanIndex: gz.dayGanIndex,
            dayZhiIndex: gz.dayZhiIndex,
            dayGanIndexExact: gz.dayGanIndexExact,
            dayZhiIndexExact: gz.dayZhiIndexExact,
            dayGanIndexExact2: gz.dayGanIndexExact2,
            dayZhiIndexExact2: gz.dayZhiIndexExact2,
            monthGanIndex: gz.monthGanIndex,
            monthZhiIndex: gz.monthZhiIndex,
            monthGanIndexExact: gz.monthGanIndexExact,
            monthZhiIndexExact: gz.monthZhiIndexExact,
            yearGanIndex: gz.yearGanIndex,
            yearZhiIndex: gz.yearZhiIndex,
            yearGanIndexByLiChun: gz.yearGanIndexByLiChun,
            yearZhiIndexByLiChun: gz.yearZhiIndexByLiChun,
            yearGanIndexExact: gz.yearGanIndexExact,
            yearZhiIndexExact: gz.yearZhiIndexExact,
            weekIndex: gz.weekIndex,
            jieQi: gz.jieQi,
            jieQiList: gz.jieQiList,
            solar: solar
        )
    }

    // MARK: - Basic getters

    func getYear() -> Int { year }
    func getMonth() -> Int { month }
    func getDay() -> Int { day }
    func getHour() -> Int { hour }
    func getMinute() -> Int { minute }
    func getSecond() -> Int { second }

    func getTimeGanIndex() -> Int { timeGanIndex }
    func getTimeZhiIndex() -> Int { timeZhiIndex }
    func getDayGanIndex() -> Int { dayGanIndex }
    func getDayGanIndexExact() -> Int { dayGanIndexExact }
    func getDayGanIndexExact2() -> Int { dayGanIndexExact2 }
    func getDayZhiIndex() -> Int { dayZhiIndex }
    func getDayZhiIndexExact() -> Int { dayZhiIndexExact }
    func getDayZhiIndexExact2() -> Int { dayZhiIndexExact2 }
    func getMonthGanIndex() -> Int { monthGanIndex }
    func getMonthGanIndexExact() -> Int { monthGanIndexExact }
    func getMonthZhiIndex() -> Int { monthZhiIndex }
    func getMonthZhiIndexExact() -> Int { monthZhiIndexExact }
    func getYearGanIndex() -> Int { yearGanIndex }
    func getYearGanIndexByLiChun() -> Int { yearGanIndexByLiChun }
    func getYearGanIndexExact() -> Int { yearGanIndexExact }
    func getYearZhiIndex() -> Int { yearZhiIndex }
    func getYearZhiIndexByLiChun() -> Int { yearZhiIndexByLiChun }
    func getYearZhiIndexExact() -> Int { yearZhiIndexExact }

    func getGan() -> String { getYearGan() }
    func getZhi() -> String { getYearZhi() }

    func getYearGan() -> String { t(LunarUtil.GAN[yearGanIndex + 1]) }
    func getYearGanByLiChun() -> String { t(LunarUtil.GAN[yearGanIndexByLiChun + 1]) }
    func getYearGanExact() -> String { t(LunarUtil.GAN[yearGanIndexExact + 1]) }
    func getYearZhi() -> String { t(LunarUtil.ZHI[yearZhiIndex + 1]) }
    func getYearZhiByLiChun() -> String { t(LunarUtil.ZHI[yearZhiIndexByLiChun + 1]) }
    func getYearZhiExact() -> String { t(LunarUtil.ZHI[yearZhiIndexExact + 1]) }

    func getYearInGanZhi() -> String { getYearGan() + getYearZhi() }
    func getYearInGanZhiByLiChun() -> String { getYearGanByLiChun() + getYearZhiByLiChun() }
    func getYearInGanZhiExact() -> String { getYearGanExact() + getYearZhiExact() }

    func getMonthGan() -> String { t(LunarUtil.GAN[monthGanIndex + 1]) }
    func getMonthGanExact() -> String { t(LunarUtil.GAN[monthGanIndexExact + 1]) }
    func getMonthZhi() -> String { t(LunarUtil.ZHI[monthZhiIndex + 1]) }
    func getMonthZhiExact() -> String { t(LunarUtil.ZHI[monthZhiIndexExact + 1]) }
    func getMonthInGanZhi() -> String { getMonthGan() + getMonthZhi() }
    func getMonthInGanZhiExact() -> String { getMonthGanExact() + getMonthZhiExact() }

    func getDayGan() -> String { t(LunarUtil.GAN[dayGanIndex + 1]) }
    func getDayGanExact() -> String { t(LunarUtil.GAN[dayGanIndexExact + 1]) }
    func getDayGanExact2() -> String { t(LunarUtil.GAN[dayGanIndexExact2 + 1]) }
    func getDayZhi() -> String { t(LunarUtil.ZHI[dayZhiIndex + 1]) }
    func getDayZhiExact() -> String { t(LunarUtil.ZHI[dayZhiIndexExact + 1]) }
    func getDayZhiExact2() -> String { t(LunarUtil.ZHI[dayZhiIndexExact2 + 1]) }

    func getDayInGanZhi() -> String { getDayGan() + getDayZhi() }
    func getDayInGanZhiExact() -> String { getDayGanExact() + getDayZhiExact() }
    func getDayInGanZhiExact2() -> String { getDayGanExact2() + getDayZhiExact2() }

    func getTimeGan() -> String { t(LunarUtil.GAN[timeGanIndex + 1]) }
    func getTimeZhi() -> String { t(LunarUtil.ZHI[timeZhiIndex + 1]) }
    func getTimeInGanZhi() -> String { getTimeGan() + getTimeZhi() }

    func getShengxiao() -> String { getYearShengXiao() }
    func getYearShengXiao() -> String { t(LunarUtil.SHENGXIAO[yearZhiIndex + 1]) }
    func getYearShengXiaoByLiChun() -> String { t(LunarUtil.SHENGXIAO[yearZhiIndexByLiChun + 1]) }
    func getYearShengXiaoExact() -> String { t(LunarUtil.SHENGXIAO[yearZhiIndexExact + 1]) }
    func getMonthShengXiao() -> String { t(LunarUtil.SHENGXIAO[monthZhiIndex + 1]) }
    func getMonthShengXiaoExact() -> String { t(LunarUtil.SHENGXIAO[monthZhiIndexExact + 1]) }
    func getDayShengXiao() -> String { t(LunarUtil.SHENGXIAO[dayZhiIndex + 1]) }
    func getTimeShengXiao() -> String { t(LunarUtil.SHENGXIAO[timeZhiIndex + 1]) }

    func getYearInChinese() -> String {
        let y = String(year)
        var s = ""
        for ch in y {
            let idx = Int(String(ch)) ?? 0
            s += LunarUtil.NUMBER[idx]
        }
        return s
    }

    func getMonthInChinese() -> String {
        let m = month
        let name = (m < 0 ? "闰" : "") + LunarUtil.MONTH[abs(m)]
        return name
    }

    func getDayInChinese() -> String {
        return LunarUtil.DAY[day]
    }

    func getPengZuGan() -> String { t(LunarUtil.PENGZU_GAN[dayGanIndex + 1]) }
    func getPengZuZhi() -> String { t(LunarUtil.PENGZU_ZHI[dayZhiIndex + 1]) }

    func getPositionXi() -> String { getDayPositionXi() }
    func getPositionXiDesc() -> String { getDayPositionXiDesc() }
    func getPositionYangGui() -> String { getDayPositionYangGui() }
    func getPositionYangGuiDesc() -> String { getDayPositionYangGuiDesc() }
    func getPositionYinGui() -> String { getDayPositionYinGui() }
    func getPositionYinGuiDesc() -> String { getDayPositionYinGuiDesc() }
    func getPositionFu() -> String { getDayPositionFu() }
    func getPositionFuDesc() -> String { getDayPositionFuDesc() }
    func getPositionCai() -> String { getDayPositionCai() }
    func getPositionCaiDesc() -> String { getDayPositionCaiDesc() }

    func getDayPositionXi() -> String { t(LunarUtil.POSITION_XI[dayGanIndex + 1]) }
    func getDayPositionXiDesc() -> String { t(LunarUtil.POSITION_DESC[getDayPositionXi()] ?? "") }
    func getDayPositionYangGui() -> String { t(LunarUtil.POSITION_YANG_GUI[dayGanIndex + 1]) }
    func getDayPositionYangGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getDayPositionYangGui()] ?? "") }
    func getDayPositionYinGui() -> String { t(LunarUtil.POSITION_YIN_GUI[dayGanIndex + 1]) }
    func getDayPositionYinGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getDayPositionYinGui()] ?? "") }
    func getDayPositionFu(_ sect: Int = 2) -> String { t((sect == 1 ? LunarUtil.POSITION_FU : LunarUtil.POSITION_FU_2)[dayGanIndex + 1]) }
    func getDayPositionFuDesc(_ sect: Int = 2) -> String { t(LunarUtil.POSITION_DESC[getDayPositionFu(sect)] ?? "") }
    func getDayPositionCai() -> String { t(LunarUtil.POSITION_CAI[dayGanIndex + 1]) }
    func getDayPositionCaiDesc() -> String { t(LunarUtil.POSITION_DESC[getDayPositionCai()] ?? "") }

    func getTimePositionXi() -> String { t(LunarUtil.POSITION_XI[timeGanIndex + 1]) }
    func getTimePositionXiDesc() -> String { t(LunarUtil.POSITION_DESC[getTimePositionXi()] ?? "") }
    func getTimePositionYangGui() -> String { t(LunarUtil.POSITION_YANG_GUI[timeGanIndex + 1]) }
    func getTimePositionYangGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getTimePositionYangGui()] ?? "") }
    func getTimePositionYinGui() -> String { t(LunarUtil.POSITION_YIN_GUI[timeGanIndex + 1]) }
    func getTimePositionYinGuiDesc() -> String { t(LunarUtil.POSITION_DESC[getTimePositionYinGui()] ?? "") }
    func getTimePositionFu(_ sect: Int = 2) -> String { t((sect == 1 ? LunarUtil.POSITION_FU : LunarUtil.POSITION_FU_2)[timeGanIndex + 1]) }
    func getTimePositionFuDesc(_ sect: Int = 2) -> String { t(LunarUtil.POSITION_DESC[getTimePositionFu(sect)] ?? "") }
    func getTimePositionCai() -> String { t(LunarUtil.POSITION_CAI[timeGanIndex + 1]) }
    func getTimePositionCaiDesc() -> String { t(LunarUtil.POSITION_DESC[getTimePositionCai()] ?? "") }

    func getDayPositionTaiSui(_ sect: Int = 2) -> String {
        let dayInGanZhi: String
        let yearZhiIndex: Int
        switch sect {
        case 1:
            dayInGanZhi = getDayInGanZhi()
            yearZhiIndex = self.yearZhiIndex
        case 3:
            dayInGanZhi = getDayInGanZhi()
            yearZhiIndex = yearZhiIndexExact
        default:
            dayInGanZhi = getDayInGanZhiExact2()
            yearZhiIndex = yearZhiIndexByLiChun
        }
        let p: String
        let s1 = ["甲子", "乙丑", "丙寅", "丁卯", "戊辰", "己巳"].joined(separator: ",")
        let s2 = ["丙子", "丁丑", "戊寅", "己卯", "庚辰", "辛巳"].joined(separator: ",")
        let s3 = ["戊子", "己丑", "庚寅", "辛卯", "壬辰", "癸巳"].joined(separator: ",")
        let s4 = ["庚子", "辛丑", "壬寅", "癸卯", "甲辰", "乙巳"].joined(separator: ",")
        let s5 = ["壬子", "癸丑", "甲寅", "乙卯", "丙辰", "丁巳"].joined(separator: ",")
        if s1.contains(dayInGanZhi) {
            p = "震"
        } else if s2.contains(dayInGanZhi) {
            p = "离"
        } else if s3.contains(dayInGanZhi) {
            p = "中"
        } else if s4.contains(dayInGanZhi) {
            p = "兑"
        } else if s5.contains(dayInGanZhi) {
            p = "坎"
        } else {
            p = LunarUtil.POSITION_TAI_SUI_YEAR[yearZhiIndex]
        }
        return t(p)
    }

    func getDayPositionTaiSuiDesc(_ sect: Int = 2) -> String {
        return t(LunarUtil.POSITION_DESC[getDayPositionTaiSui(sect)] ?? "")
    }

    func getMonthPositionTaiSui(_ sect: Int = 2) -> String {
        let monthZhiIndex = (sect == 3) ? monthZhiIndexExact : self.monthZhiIndex
        let monthGanIndex = (sect == 3) ? monthGanIndexExact : self.monthGanIndex
        var m = monthZhiIndex - LunarUtil.BASE_MONTH_ZHI_INDEX
        if m < 0 { m += 12 }
        let list = ["艮", LunarUtil.POSITION_GAN[monthGanIndex], "坤", "巽"]
        return t(list[m % 4])
    }

    func getMonthPositionTaiSuiDesc(_ sect: Int = 2) -> String {
        return t(LunarUtil.POSITION_DESC[getMonthPositionTaiSui(sect)] ?? "")
    }

    func getYearPositionTaiSui(_ sect: Int = 2) -> String {
        let index: Int
        switch sect {
        case 1: index = yearZhiIndex
        case 3: index = yearZhiIndexExact
        default: index = yearZhiIndexByLiChun
        }
        return t(LunarUtil.POSITION_TAI_SUI_YEAR[index])
    }

    func getYearPositionTaiSuiDesc(_ sect: Int = 2) -> String {
        return t(LunarUtil.POSITION_DESC[getYearPositionTaiSui(sect)] ?? "")
    }

    private func checkLang() { }

    private func getJieQiSolar(_ name: String) -> Solar? {
        checkLang()
        return jieQi[name]
    }

    private func getJieQiSolarByAliases(_ aliases: [String]) -> Solar? {
        for alias in aliases {
            if let s = getJieQiSolar(alias) {
                return s
            }
        }
        return nil
    }

    private func getDongZhiSolar() -> Solar? {
        return getJieQiSolarByAliases(["DONG_ZHI", "冬至"])
    }

    private func getXiaZhiSolar() -> Solar? {
        return getJieQiSolarByAliases(["夏至"])
    }

    private func getLiChunSolar() -> Solar? {
        return getJieQiSolarByAliases(["立春", "LI_CHUN"])
    }

    private func getLiQiuSolar() -> Solar? {
        return getJieQiSolarByAliases(["立秋"])
    }

    private func getQingMingSolar() -> Solar? {
        return getJieQiSolarByAliases(["清明"])
    }

    func getChong() -> String { getDayChong() }
    func getChongGan() -> String { getDayChongGan() }
    func getChongGanTie() -> String { getDayChongGanTie() }
    func getChongShengXiao() -> String { getDayChongShengXiao() }
    func getChongDesc() -> String { getDayChongDesc() }
    func getSha() -> String { getDaySha() }

    func getDayChong() -> String { t(LunarUtil.CHONG[dayZhiIndex]) }
    func getDayChongGan() -> String { t(LunarUtil.CHONG_GAN[dayGanIndex]) }
    func getDayChongGanTie() -> String { t(LunarUtil.CHONG_GAN_TIE[dayGanIndex]) }
    func getDayChongShengXiao() -> String {
        let chong = getChong()
        for i in 0..<LunarUtil.ZHI.count {
            if LunarUtil.ZHI[i] == chong { return LunarUtil.SHENGXIAO[i] }
        }
        return ""
    }
    func getDayChongDesc() -> String { "(\(getDayChongGan())\(getDayChong()))\(getDayChongShengXiao())" }
    func getDaySha() -> String { t(LunarUtil.SHA[getDayZhi()] ?? "") }

    func getTimeChong() -> String { t(LunarUtil.CHONG[timeZhiIndex]) }
    func getTimeChongGan() -> String { t(LunarUtil.CHONG_GAN[timeGanIndex]) }
    func getTimeChongGanTie() -> String { t(LunarUtil.CHONG_GAN_TIE[timeGanIndex]) }
    func getTimeChongShengXiao() -> String {
        let chong = getTimeChong()
        for i in 0..<LunarUtil.ZHI.count {
            if LunarUtil.ZHI[i] == chong { return LunarUtil.SHENGXIAO[i] }
        }
        return ""
    }
    func getTimeChongDesc() -> String { "(\(getTimeChongGan())\(getTimeChong()))\(getTimeChongShengXiao())" }
    func getTimeSha() -> String { t(LunarUtil.SHA[getTimeZhi()] ?? "") }

    func getYearNaYin() -> String { t(LunarUtil.NAYIN[getYearInGanZhi()] ?? "") }
    func getMonthNaYin() -> String { t(LunarUtil.NAYIN[getMonthInGanZhi()] ?? "") }
    func getDayNaYin() -> String { t(LunarUtil.NAYIN[getDayInGanZhi()] ?? "") }
    func getTimeNaYin() -> String { t(LunarUtil.NAYIN[getTimeInGanZhi()] ?? "") }

    func getSeason() -> String { t(LunarUtil.SEASON[abs(month)]) }

    private func convertJieQi(_ name: String) -> String {
        // 节气键统一转中文，兼容历史数据中中英混用
        var jq = name
        if jq == "DONG_ZHI" { jq = "冬至" }
        else if jq == "DA_HAN" { jq = "大寒" }
        else if jq == "XIAO_HAN" { jq = "小寒" }
        else if jq == "LI_CHUN" { jq = "立春" }
        else if jq == "DA_XUE" { jq = "大雪" }
        else if jq == "YU_SHUI" { jq = "雨水" }
        else if jq == "JING_ZHE" { jq = "惊蛰" }
        return jq
    }

    func getJie() -> String {
        for i in stride(from: 0, to: LunarUtil.JIE_QI_IN_USE.count, by: 2) {
            let key = LunarUtil.JIE_QI_IN_USE[i]
            if let d = getJieQiSolar(key), d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return t(convertJieQi(key))
            }
        }
        return ""
    }

    func getQi() -> String {
        for i in stride(from: 1, to: LunarUtil.JIE_QI_IN_USE.count, by: 2) {
            let key = LunarUtil.JIE_QI_IN_USE[i]
            if let d = getJieQiSolar(key), d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return t(convertJieQi(key))
            }
        }
        return ""
    }

    func getJieQi() -> String {
        // 当天命中节气则返回对应名称，否则返回空字符串
        for (key, d) in jieQi {
            if d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return t(convertJieQi(key))
            }
        }
        return ""
    }

    func getWeek() -> Int { weekIndex }

    func getXiu() -> String { t(LunarUtil.XIU[getDayZhi() + String(getWeek())] ?? "") }
    func getXiuLuck() -> String { t(LunarUtil.XIU_LUCK[getXiu()] ?? "") }
    func getZheng() -> String { t(LunarUtil.ZHENG[getXiu()] ?? "") }
    func getAnimal() -> String { t(LunarUtil.ANIMAL[getXiu()] ?? "") }
    func getGong() -> String { t(LunarUtil.GONG[getXiu()] ?? "") }
    func getShou() -> String { t(LunarUtil.SHOU[getGong()] ?? "") }

    func getBaZi() -> [String] {
        let bz = getEightChar()
        return ta([bz.getYear(), bz.getMonth(), bz.getDay(), bz.getTime()])
    }


    func getZhiXing() -> String {
        var offset = dayZhiIndex - monthZhiIndex
        if offset < 0 { offset += 12 }
        return t(LunarUtil.ZHI_XING[offset + 1])
    }

    func getDayTianShen() -> String {
        let monthZhi = getMonthZhi()
        let offset = LunarUtil.ZHI_TIAN_SHEN_OFFSET[monthZhi] ?? 0
        return t(LunarUtil.TIAN_SHEN[(dayZhiIndex + offset) % 12 + 1])
    }

    func getTimeTianShen() -> String {
        let dayZhi = getDayZhiExact()
        let offset = LunarUtil.ZHI_TIAN_SHEN_OFFSET[dayZhi] ?? 0
        return t(LunarUtil.TIAN_SHEN[(timeZhiIndex + offset) % 12 + 1])
    }

    func getDayTianShenType() -> String { t(LunarUtil.TIAN_SHEN_TYPE[getDayTianShen()] ?? "") }
    func getTimeTianShenType() -> String { t(LunarUtil.TIAN_SHEN_TYPE[getTimeTianShen()] ?? "") }
    func getDayTianShenLuck() -> String { t(LunarUtil.TIAN_SHEN_TYPE_LUCK[getDayTianShenType()] ?? "") }
    func getTimeTianShenLuck() -> String { t(LunarUtil.TIAN_SHEN_TYPE_LUCK[getTimeTianShenType()] ?? "") }

    func getDayPositionTai() -> String {
        return t(LunarUtil.POSITION_TAI_DAY[LunarUtil.getJiaZiIndex(getDayInGanZhi())])
    }

    func getMonthPositionTai() -> String {
        if month < 0 { return "" }
        return t(LunarUtil.POSITION_TAI_MONTH[month - 1])
    }

    func getDayYi(_ sect: Int = 1) -> [String] {
        let s = (sect == 2) ? getMonthInGanZhiExact() : getMonthInGanZhi()
        return ta(LunarUtil.getDayYi(s, getDayInGanZhi()))
    }

    func getDayJi(_ sect: Int = 1) -> [String] {
        let s = (sect == 2) ? getMonthInGanZhiExact() : getMonthInGanZhi()
        return ta(LunarUtil.getDayJi(s, getDayInGanZhi()))
    }

    func getDayJiShen() -> [String] { ta(LunarUtil.getDayJiShen(getMonthZhiIndex(), getDayInGanZhi())) }
    func getDayXiongSha() -> [String] { ta(LunarUtil.getDayXiongSha(getMonthZhiIndex(), getDayInGanZhi())) }
    func getTimeYi() -> [String] { ta(LunarUtil.getTimeYi(getDayInGanZhiExact(), getTimeInGanZhi())) }
    func getTimeJi() -> [String] { ta(LunarUtil.getTimeJi(getDayInGanZhiExact(), getTimeInGanZhi())) }


    func getSolar() -> Solar { solar }
    func getJieQiTable() -> [String: Solar] {
        checkLang()
        var translated: [String: Solar] = [:]
        for (key, value) in jieQi {
            translated[t(key)] = value
        }
        return translated
    }
    func getJieQiList() -> [String] { checkLang(); return ta(jieQiList) }

    func getNextJie(_ wholeDay: Bool = false) -> LunarJieQi? {
        var conditions: [String] = []
        for i in 0..<(LunarUtil.JIE_QI_IN_USE.count / 2) { conditions.append(LunarUtil.JIE_QI_IN_USE[i * 2]) }
        return getNearJieQi(true, conditions, wholeDay)
    }

    func getPrevJie(_ wholeDay: Bool = false) -> LunarJieQi? {
        var conditions: [String] = []
        for i in 0..<(LunarUtil.JIE_QI_IN_USE.count / 2) { conditions.append(LunarUtil.JIE_QI_IN_USE[i * 2]) }
        return getNearJieQi(false, conditions, wholeDay)
    }

    func getNextQi(_ wholeDay: Bool = false) -> LunarJieQi? {
        var conditions: [String] = []
        for i in 0..<(LunarUtil.JIE_QI_IN_USE.count / 2) { conditions.append(LunarUtil.JIE_QI_IN_USE[i * 2 + 1]) }
        return getNearJieQi(true, conditions, wholeDay)
    }

    func getPrevQi(_ wholeDay: Bool = false) -> LunarJieQi? {
        var conditions: [String] = []
        for i in 0..<(LunarUtil.JIE_QI_IN_USE.count / 2) { conditions.append(LunarUtil.JIE_QI_IN_USE[i * 2 + 1]) }
        return getNearJieQi(false, conditions, wholeDay)
    }

    func getNextJieQi(_ wholeDay: Bool = false) -> LunarJieQi? { getNearJieQi(true, nil, wholeDay) }
    func getPrevJieQi(_ wholeDay: Bool = false) -> LunarJieQi? { getNearJieQi(false, nil, wholeDay) }

    private func buildJieQi(_ name: String, _ solar: Solar) -> LunarJieQi {
        var jie = false
        var qi = false
        for (i, item) in LunarUtil.JIE_QI.enumerated() {
            if item == name {
                if i % 2 == 0 { qi = true } else { jie = true }
                break
            }
        }
        return LunarJieQi(name: name, solar: solar, isJie: jie, isQi: qi)
    }

    private func getNearJieQi(_ forward: Bool, _ conditions: [String]?, _ wholeDay: Bool) -> LunarJieQi? {
        // 通用“最近节气”查找：
        // - forward=true: 向后找最近一个
        // - forward=false: 向前找最近一个
        // - wholeDay=true: 只按日期比较
        var name: String? = nil
        var near: Solar? = nil
        var filters: [String: Bool] = [:]
        var filter = false
        if let conditions = conditions {
            for c in conditions { filters[c] = true; filter = true }
        }
        let today = wholeDay ? solar.toYmd() : solar.toYmdHms()
        for (key, _) in jieQi {
            let jq = convertJieQi(key)
            if filter && filters[jq] != true { continue }
            if let s = getJieQiSolar(key) {
                let day = wholeDay ? s.toYmd() : s.toYmdHms()
                if forward {
                    if day <= today { continue }
                    if near == nil || day < (wholeDay ? near!.toYmd() : near!.toYmdHms()) {
                        name = jq
                        near = s
                    }
                } else {
                    if day > today { continue }
                    if near == nil || day > (wholeDay ? near!.toYmd() : near!.toYmdHms()) {
                        name = jq
                        near = s
                    }
                }
            }
        }
        if let n = name, let s = near { return buildJieQi(n, s) }
        return nil
    }

    func getCurrentJieQi() -> LunarJieQi? {
        for (key, d) in jieQi {
            if d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return buildJieQi(convertJieQi(key), d)
            }
        }
        return nil
    }

    func getCurrentJie() -> LunarJieQi? {
        for i in stride(from: 0, to: LunarUtil.JIE_QI_IN_USE.count, by: 2) {
            let key = LunarUtil.JIE_QI_IN_USE[i]
            if let d = getJieQiSolar(key), d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return buildJieQi(convertJieQi(key), d)
            }
        }
        return nil
    }

    func getCurrentQi() -> LunarJieQi? {
        for i in stride(from: 1, to: LunarUtil.JIE_QI_IN_USE.count, by: 2) {
            let key = LunarUtil.JIE_QI_IN_USE[i]
            if let d = getJieQiSolar(key), d.getYear() == solar.getYear() && d.getMonth() == solar.getMonth() && d.getDay() == solar.getDay() {
                return buildJieQi(convertJieQi(key), d)
            }
        }
        return nil
    }

    func getEightChar() -> EightChar {
        if eightChar == nil { eightChar = EightChar.fromLunar(self) }
        return eightChar!
    }

    func next(_ days: Int) -> Lunar { return solar.next(days).getLunar() }

    func getYearXun() -> String { t(LunarUtil.getXun(getYearInGanZhi())) }
    func getMonthXun() -> String { t(LunarUtil.getXun(getMonthInGanZhi())) }
    func getDayXun() -> String { t(LunarUtil.getXun(getDayInGanZhi())) }
    func getTimeXun() -> String { t(LunarUtil.getXun(getTimeInGanZhi())) }
    func getYearXunByLiChun() -> String { t(LunarUtil.getXun(getYearInGanZhiByLiChun())) }
    func getYearXunExact() -> String { t(LunarUtil.getXun(getYearInGanZhiExact())) }
    func getMonthXunExact() -> String { t(LunarUtil.getXun(getMonthInGanZhiExact())) }
    func getDayXunExact() -> String { t(LunarUtil.getXun(getDayInGanZhiExact())) }
    func getDayXunExact2() -> String { t(LunarUtil.getXun(getDayInGanZhiExact2())) }

    func getYearXunKong() -> String { t(LunarUtil.getXunKong(getYearInGanZhi())) }
    func getMonthXunKong() -> String { t(LunarUtil.getXunKong(getMonthInGanZhi())) }
    func getDayXunKong() -> String { t(LunarUtil.getXunKong(getDayInGanZhi())) }
    func getTimeXunKong() -> String { t(LunarUtil.getXunKong(getTimeInGanZhi())) }
    func getYearXunKongByLiChun() -> String { t(LunarUtil.getXunKong(getYearInGanZhiByLiChun())) }
    func getYearXunKongExact() -> String { t(LunarUtil.getXunKong(getYearInGanZhiExact())) }
    func getMonthXunKongExact() -> String { t(LunarUtil.getXunKong(getMonthInGanZhiExact())) }
    func getDayXunKongExact() -> String { t(LunarUtil.getXunKong(getDayInGanZhiExact())) }
    func getDayXunKongExact2() -> String { t(LunarUtil.getXunKong(getDayInGanZhiExact2())) }

    private func buildNameAndIndex(_ name: String, _ index: Int) -> LunarNameIndex {
        return LunarNameIndex(name: name, index: index)
    }

    func getShuJiu() -> LunarNameIndex? {
        // 数九：冬至起 81 天，每 9 天一段（“一九”到“九九”）
        let currentDay = Solar.fromYmd(solar.getYear(), solar.getMonth(), solar.getDay())
        guard var start = getDongZhiSolar() else {
            return nil
        }
        var startDay = Solar.fromYmd(start.getYear(), start.getMonth(), start.getDay())
        if currentDay.isBefore(startDay) {
            guard let dongZhi = getJieQiSolarByAliases(["冬至", "DONG_ZHI"]) else {
                return nil
            }
            start = dongZhi
            startDay = Solar.fromYmd(start.getYear(), start.getMonth(), start.getDay())
        }
        let endDay = Solar.fromYmd(start.getYear(), start.getMonth(), start.getDay()).next(81)
        if currentDay.isBefore(startDay) || (!currentDay.isBefore(endDay)) { return nil }
        let days = currentDay.subtract(startDay)
        return buildNameAndIndex(LunarUtil.NUMBER[Int(floor(Double(days) / 9.0)) + 1] + "九", days % 9 + 1)
    }

    func getFu() -> LunarNameIndex? {
        // 三伏：夏至后第三个庚日为初伏起点，结合立秋判定中伏长度
        let currentDay = Solar.fromYmd(solar.getYear(), solar.getMonth(), solar.getDay())
        guard let xiaZhi = getXiaZhiSolar(), let liQiu = getLiQiuSolar() else {
            return nil
        }
        var startDay = Solar.fromYmd(xiaZhi.getYear(), xiaZhi.getMonth(), xiaZhi.getDay())
        var add = 6 - xiaZhi.getLunar().getDayGanIndex()
        if add < 0 { add += 10 }
        add += 20
        startDay = startDay.next(add)
        if currentDay.isBefore(startDay) { return nil }
        var days = currentDay.subtract(startDay)
        if days < 10 { return buildNameAndIndex("初伏", days + 1) }
        startDay = startDay.next(10)
        days = currentDay.subtract(startDay)
        if days < 10 { return buildNameAndIndex("中伏", days + 1) }
        startDay = startDay.next(10)
        let liQiuDay = Solar.fromYmd(liQiu.getYear(), liQiu.getMonth(), liQiu.getDay())
        days = currentDay.subtract(startDay)
        if liQiuDay.isAfter(startDay) {
            if days < 10 { return buildNameAndIndex("中伏", days + 11) }
            startDay = startDay.next(10)
            days = currentDay.subtract(startDay)
        }
        if days < 10 { return buildNameAndIndex("末伏", days + 1) }
        return nil
    }

}

final class LunarJieQi {
    /// 节气名称（中文）
    private let name: String
    /// 对应公历时刻
    private let solar: Solar
    /// 是否“节”
    private let jie: Bool
    /// 是否“气”
    private let qi: Bool

    init(name: String, solar: Solar, isJie: Bool, isQi: Bool) {
        self.name = name
        self.solar = solar
        self.jie = isJie
        self.qi = isQi
    }

    func getName() -> String { name }
    func getSolar() -> Solar { solar }
    func isJie() -> Bool { jie }
    func isQi() -> Bool { qi }
    func toString() -> String { name }
}

final class LunarNameIndex {
    /// 名称（如“二九”“中伏”）
    private let name: String
    /// 序号/第几天（从 1 开始）
    private let index: Int

    init(name: String, index: Int) {
        self.name = name
        self.index = index
    }

    func getName() -> String { name }
    func getIndex() -> Int { index }
    func toString() -> String { name }
    func toFullString() -> String { "\(name)第\(index)天" }
}
