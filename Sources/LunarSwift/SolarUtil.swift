import Foundation

/// 公历基础算法工具（内部使用）。
///
/// 提供：
/// - 闰年判定
/// - 月天数/年天数计算
/// - 年内日序与两日期天数差计算
enum SolarUtil {
    static let DAYS_OF_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    static let XINGZUO = [
        "白羊", "金牛", "双子", "巨蟹", "狮子", "处女",
        "天秤", "天蝎", "射手", "摩羯", "水瓶", "双鱼"
    ]

    static func isLeapYear(_ year: Int) -> Bool {
        // 兼容 1600 年前后规则差异
        if year < 1600 {
            return year % 4 == 0
        }
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    static func getDaysOfMonth(_ year: Int, _ month: Int) -> Int {
        // 1582 年 10 月为改历月，仅有 21 天
        if year == 1582 && month == 10 {
            return 21
        }
        guard (1...12).contains(month) else {
            preconditionFailure("wrong solar month \(month)")
        }
        let index = month - 1
        var days = DAYS_OF_MONTH[index]
        if index == 1 && isLeapYear(year) {
            days += 1
        }
        return days
    }

    static func getDaysOfYear(_ year: Int) -> Int {
        if year == 1582 {
            return 355
        }
        return isLeapYear(year) ? 366 : 365
    }

    static func getDaysInYear(_ year: Int, _ month: Int, _ day: Int) -> Int {
        // 计算“该日是当年第几天”，用于跨年天数差
        guard (1...12).contains(month) else {
            preconditionFailure("wrong solar month \(month)")
        }
        guard (1...31).contains(day) else {
            preconditionFailure("wrong solar day \(day)")
        }
        var days = 0
        if month > 1 {
            for m in 1..<(month) {
                days += getDaysOfMonth(year, m)
            }
        }
        var d = day
        if year == 1582 && month == 10 {
            if day >= 15 {
                d -= 10
            } else if day > 4 {
                preconditionFailure("wrong solar year \(year) month \(month) day \(day)")
            }
        }
        days += d
        return days
    }

    static func getDaysBetween(_ ay: Int, _ am: Int, _ ad: Int, _ by: Int, _ bm: Int, _ bd: Int) -> Int {
        // 返回 B - A 的天数差（可正可负）
        var days = 0
        if ay == by {
            return getDaysInYear(by, bm, bd) - getDaysInYear(ay, am, ad)
        } else if ay > by {
            days = getDaysOfYear(by) - getDaysInYear(by, bm, bd)
            if by + 1 <= ay - 1 {
                for y in (by + 1)..<ay {
                    days += getDaysOfYear(y)
                }
            }
            days += getDaysInYear(ay, am, ad)
            return -days
        } else {
            days = getDaysOfYear(ay) - getDaysInYear(ay, am, ad)
            if ay + 1 <= by - 1 {
                for y in (ay + 1)..<by {
                    days += getDaysOfYear(y)
                }
            }
            days += getDaysInYear(by, bm, bd)
            return days
        }
    }

}
