import Foundation

/// 公历日期模型（内部使用）。
///
/// 说明：
/// - 这里不依赖系统 `DateFormatter`，而是通过数学算法进行儒略日互转，
///   以保证和原版历法数据保持一致。
/// - 保留 1582-10-05 ~ 1582-10-14 的公历缺失区间校验。
struct Solar: Equatable {
    private let year: Int
    private let month: Int
    private let day: Int
    private let hour: Int
    private let minute: Int
    private let second: Int

    /// J2000 儒略日基准（2000-01-01 12:00 TT）
    static let J2000: Double = 2451545

    private init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    static func fromYmd(_ y: Int, _ m: Int, _ d: Int) -> Solar {
        return fromYmdHms(y, m, d, 0, 0, 0)
    }

    static func fromYmdHms(_ y: Int, _ m: Int, _ d: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Solar {
        // 统一入口先做边界和合法性校验，避免后续计算出现隐式错误
        validate(y, m, d, hour, minute, second)
        return Solar(year: y, month: m, day: d, hour: hour, minute: minute, second: second)
    }

    static func fromDate(_ date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> Solar {
        // Date -> 公历组件（按外部传入 Calendar/TimeZone 解释）
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return fromYmdHms(comps.year ?? 0, comps.month ?? 0, comps.day ?? 0, comps.hour ?? 0, comps.minute ?? 0, comps.second ?? 0)
    }

    static func fromJulianDay(_ julianDay: Double) -> Solar {
        // 标准儒略日转公历算法（含格里高利历修正）
        var d = floor(julianDay + 0.5)
        var f = julianDay + 0.5 - d
        var c: Double = 0
        if d >= 2299161 {
            c = floor((d - 1867216.25) / 36524.25)
            d += 1 + c - floor(c / 4)
        }
        d += 1524
        var year = floor((d - 122.1) / 365.25)
        d -= floor(365.25 * year)
        var month = floor(d / 30.601)
        d -= floor(30.601 * month)
        var day = d
        if month > 13 {
            month -= 13
            year -= 4715
        } else {
            month -= 1
            year -= 4716
        }
        f *= 24
        var hour = floor(f)
        f -= hour
        f *= 60
        var minute = floor(f)
        f -= minute
        f *= 60
        var second = round(f)
        if second > 59 {
            second -= 60
            minute += 1
        }
        if minute > 59 {
            minute -= 60
            hour += 1
        }
        if hour > 23 {
            hour -= 24
            day += 1
        }
        return fromYmdHms(Int(year), Int(month), Int(day), Int(hour), Int(minute), Int(second))
    }

    func subtract(_ solar: Solar) -> Int {
        // 仅按“日”做差值，用于节气区间与农历日偏移计算
        return SolarUtil.getDaysBetween(solar.getYear(), solar.getMonth(), solar.getDay(), year, month, day)
    }

    func isAfter(_ solar: Solar) -> Bool {
        if year != solar.getYear() { return year > solar.getYear() }
        if month != solar.getMonth() { return month > solar.getMonth() }
        if day != solar.getDay() { return day > solar.getDay() }
        if hour != solar.getHour() { return hour > solar.getHour() }
        if minute != solar.getMinute() { return minute > solar.getMinute() }
        return second > solar.getSecond()
    }

    func isBefore(_ solar: Solar) -> Bool {
        if year != solar.getYear() { return year < solar.getYear() }
        if month != solar.getMonth() { return month < solar.getMonth() }
        if day != solar.getDay() { return day < solar.getDay() }
        if hour != solar.getHour() { return hour < solar.getHour() }
        if minute != solar.getMinute() { return minute < solar.getMinute() }
        return second < solar.getSecond()
    }

    func getYear() -> Int { year }
    func getMonth() -> Int { month }
    func getDay() -> Int { day }
    func getHour() -> Int { hour }
    func getMinute() -> Int { minute }
    func getSecond() -> Int { second }

    func getWeek() -> Int {
        // 0=周日 ... 6=周六
        return (Int(floor(getJulianDay() + 0.5)) + 7000001) % 7
    }

    func getXingZuo() -> String {
        // 以月日区间判定星座
        var index = 11
        let y = month * 100 + day
        if y >= 321 && y <= 419 {
            index = 0
        } else if y >= 420 && y <= 520 {
            index = 1
        } else if y >= 521 && y <= 621 {
            index = 2
        } else if y >= 622 && y <= 722 {
            index = 3
        } else if y >= 723 && y <= 822 {
            index = 4
        } else if y >= 823 && y <= 922 {
            index = 5
        } else if y >= 923 && y <= 1023 {
            index = 6
        } else if y >= 1024 && y <= 1122 {
            index = 7
        } else if y >= 1123 && y <= 1221 {
            index = 8
        } else if y >= 1222 || y <= 119 {
            index = 9
        } else if y <= 218 {
            index = 10
        }
        return SolarUtil.XINGZUO[index]
    }

    func toYmd() -> String {
        // 固定 yyyy-MM-dd 输出，供节气节点和页面展示使用
        var y = String(year)
        while y.count < 4 {
            y = "0" + y
        }
        let m = month < 10 ? "0\(month)" : "\(month)"
        let d = day < 10 ? "0\(day)" : "\(day)"
        return "\(y)-\(m)-\(d)"
    }

    func toYmdHms() -> String {
        let h = hour < 10 ? "0\(hour)" : "\(hour)"
        let mi = minute < 10 ? "0\(minute)" : "\(minute)"
        let s = second < 10 ? "0\(second)" : "\(second)"
        return "\(toYmd()) \(h):\(mi):\(s)"
    }

    func nextDay(_ days: Int) -> Solar {
        // 纯自然日推进/回退，处理跨月跨年与 1582 改历缺口
        var y = year
        var m = month
        var d = day
        var delta = days
        if y == 1582 && m == 10 && d > 4 {
            d -= 10
        }
        if delta > 0 {
            d += delta
            var daysInMonth = SolarUtil.getDaysOfMonth(y, m)
            while d > daysInMonth {
                d -= daysInMonth
                m += 1
                if m > 12 {
                    m = 1
                    y += 1
                }
                daysInMonth = SolarUtil.getDaysOfMonth(y, m)
            }
        } else if delta < 0 {
            while d + delta <= 0 {
                m -= 1
                if m < 1 {
                    m = 12
                    y -= 1
                }
                d += SolarUtil.getDaysOfMonth(y, m)
            }
            d += delta
        }
        if y == 1582 && m == 10 && d > 4 {
            d += 10
        }
        return Solar.fromYmdHms(y, m, d, hour, minute, second)
    }

    func next(_ days: Int) -> Solar {
        return nextDay(days)
    }

    func getLunar() -> Lunar {
        return Lunar.fromSolar(self)
    }

    func getJulianDay() -> Double {
        // 公历转儒略日：Solar 与天文节气计算之间的桥梁
        var y = year
        var m = month
        let d = Double(day) + (Double(second) / 60.0 + Double(minute)) / 60.0 / 24.0 + Double(hour) / 24.0
        var n = 0.0
        let g = y * 372 + m * 31 + Int(floor(d)) >= 588829
        if m <= 2 {
            m += 12
            y -= 1
        }
        if g {
            n = Double(y / 100)
            n = 2 - n + floor(n / 4)
        }
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + d + n - 1524.5
    }

    private static func validate(_ y: Int, _ m: Int, _ d: Int, _ hour: Int, _ minute: Int, _ second: Int) {
        // 1582-10-05 ~ 1582-10-14 在格里高利改历中不存在
        if y == 1582 && m == 10 && d > 4 && d < 15 {
            preconditionFailure("wrong solar year \(y) month \(m) day \(d)")
        }
        if m < 1 || m > 12 { preconditionFailure("wrong month \(m)") }
        if d < 1 || d > 31 { preconditionFailure("wrong day \(d)") }
        if hour < 0 || hour > 23 { preconditionFailure("wrong hour \(hour)") }
        if minute < 0 || minute > 59 { preconditionFailure("wrong minute \(minute)") }
        if second < 0 || second > 59 { preconditionFailure("wrong second \(second)") }
    }
}
