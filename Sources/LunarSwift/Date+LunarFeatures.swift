import Foundation

/// 数九/三伏等“周期日”结构。
/// - name: 周期名称（例如“二九”“中伏”）
/// - dayIndex: 该周期中的第几天（从 1 开始）
public struct LunarPeriodDay: Equatable {
    public let name: String
    public let dayIndex: Int

    public init(name: String, dayIndex: Int) {
        self.name = name
        self.dayIndex = dayIndex
    }
}

/// 节气节点信息。
/// - name: 节气名称（中文）
/// - solarYmd: 节气对应的公历日期（yyyy-MM-dd）
public struct LunarJieQiNode: Equatable {
    public let name: String
    public let solarYmd: String

    public init(name: String, solarYmd: String) {
        self.name = name
        self.solarYmd = solarYmd
    }
}

/// 吉神方位集合（已转为中文方位描述）。
public struct LunarDirections: Equatable {
    public let caiShen: String
    public let xiShen: String
    public let fuShen: String
    public let yangShen: String
    public let yinShen: String

    public init(caiShen: String, xiShen: String, fuShen: String, yangShen: String, yinShen: String) {
        self.caiShen = caiShen
        self.xiShen = xiShen
        self.fuShen = fuShen
        self.yangShen = yangShen
        self.yinShen = yinShen
    }
}

/// 二十八宿相关信息集合。
public struct LunarXiuInfo: Equatable {
    public let xiu: String
    public let zheng: String
    public let animal: String
    public let gong: String
    public let shou: String
    public let luck: String

    public init(xiu: String, zheng: String, animal: String, gong: String, shou: String, luck: String) {
        self.xiu = xiu
        self.zheng = zheng
        self.animal = animal
        self.gong = gong
        self.shou = shou
        self.luck = luck
    }
}

/// 值神信息。
/// - name: 值日天神名
/// - kind: 天神类别（黄道/黑道等）
/// - luck: 吉凶判定
public struct LunarZhiShenInfo: Equatable {
    public let name: String
    public let kind: String
    public let luck: String

    public init(name: String, kind: String, luck: String) {
        self.name = name
        self.kind = kind
        self.luck = luck
    }
}

/// 对外暴露的“单日农历特征快照”。
/// 该结构用于一次性携带所有保留功能，适合列表页/详情页批量展示。
public struct LunarFeatureSnapshot: Equatable {
    /// 星座（白羊/金牛/...）
    public let constellation: String
    /// 四柱干支：[年柱, 月柱, 日柱, 时柱]
    public let ganZhi: [String]
    /// 四柱生肖：[年生肖, 月生肖, 日生肖, 时生肖]
    public let shengXiao: [String]
    /// 当日节气名称；若当天非节气日则为空字符串
    public let jieQi: String
    /// 上一个节气节点
    public let prevJieQi: LunarJieQiNode?
    /// 下一个节气节点
    public let nextJieQi: LunarJieQiNode?
    /// 数九信息（不在数九区间时为 `nil`）
    public let shuJiu: LunarPeriodDay?
    /// 三伏信息（不在三伏区间时为 `nil`）
    public let sanFu: LunarPeriodDay?
    /// 日纳音
    public let naYin: String
    /// 四柱五行：[年柱, 月柱, 日柱, 时柱]
    public let wuXing: [String]
    /// 每日宜
    public let dayYi: [String]
    /// 每日忌
    public let dayJi: [String]
    /// 时辰宜
    public let timeYi: [String]
    /// 时辰忌
    public let timeJi: [String]
    /// 吉神方位（财神/喜神/福神/阳神/阴神）
    public let directions: LunarDirections
    /// 胎神方位
    public let taiShen: String
    /// 彭祖百忌
    public let pengZu: String
    /// 冲（当前实现返回冲生肖）
    public let chong: String
    /// 煞方位
    public let sha: String
    /// 八字（四柱）：[年柱, 月柱, 日柱, 时柱]
    public let baZi: [String]
    /// 建除十二神
    public let jianChu: String
    /// 吉神列表
    public let jiShen: [String]
    /// 凶煞列表
    public let xiongSha: [String]
    /// 二十八宿信息
    public let xiu: LunarXiuInfo
    /// 值神信息
    public let zhiShen: LunarZhiShenInfo

    public init(constellation: String,
                ganZhi: [String],
                shengXiao: [String],
                jieQi: String,
                prevJieQi: LunarJieQiNode?,
                nextJieQi: LunarJieQiNode?,
                shuJiu: LunarPeriodDay?,
                sanFu: LunarPeriodDay?,
                naYin: String,
                wuXing: [String],
                dayYi: [String],
                dayJi: [String],
                timeYi: [String],
                timeJi: [String],
                directions: LunarDirections,
                taiShen: String,
                pengZu: String,
                chong: String,
                sha: String,
                baZi: [String],
                jianChu: String,
                jiShen: [String],
                xiongSha: [String],
                xiu: LunarXiuInfo,
                zhiShen: LunarZhiShenInfo) {
        self.constellation = constellation
        self.ganZhi = ganZhi
        self.shengXiao = shengXiao
        self.jieQi = jieQi
        self.prevJieQi = prevJieQi
        self.nextJieQi = nextJieQi
        self.shuJiu = shuJiu
        self.sanFu = sanFu
        self.naYin = naYin
        self.wuXing = wuXing
        self.dayYi = dayYi
        self.dayJi = dayJi
        self.timeYi = timeYi
        self.timeJi = timeJi
        self.directions = directions
        self.taiShen = taiShen
        self.pengZu = pengZu
        self.chong = chong
        self.sha = sha
        self.baZi = baZi
        self.jianChu = jianChu
        self.jiShen = jiShen
        self.xiongSha = xiongSha
        self.xiu = xiu
        self.zhiShen = zhiShen
    }
}

public extension Date {
    /// 计算当前 `Date` 在指定时区下的农历功能快照。
    ///
    /// 计算流程：
    /// 1. 先将 `Date` 按传入时区解释为公历年月日时分秒。
    /// 2. 用 `Solar -> Lunar` 完成换算。
    /// 3. 组装你要求保留的功能字段（干支、生肖、节气、宜忌、方位等）。
    ///
    /// - parameter timeZone: 计算所使用的时区，默认 `.current`。
    /// - returns: 当天所有保留能力的聚合快照。
    public func lunarFeatures(timeZone: TimeZone = .current) -> LunarFeatureSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let solar = Solar.fromDate(self, calendar: calendar)
        let lunar = solar.getLunar()

        // 八字按年/月/日/时四柱顺序输出
        let baZi = lunar.getBaZi()
        // 按需求仅保留“日纳音”
        let naYin = lunar.getDayNaYin()
        // 四柱五行：天干五行 + 地支五行
        let yearWuXingGan: String = LunarUtil.WU_XING_GAN[lunar.getYearGan()] ?? ""
        let yearWuXingZhi: String = LunarUtil.WU_XING_ZHI[lunar.getYearZhi()] ?? ""
        let monthWuXingGan: String = LunarUtil.WU_XING_GAN[lunar.getMonthGan()] ?? ""
        let monthWuXingZhi: String = LunarUtil.WU_XING_ZHI[lunar.getMonthZhi()] ?? ""
        let dayWuXingGan: String = LunarUtil.WU_XING_GAN[lunar.getDayGan()] ?? ""
        let dayWuXingZhi: String = LunarUtil.WU_XING_ZHI[lunar.getDayZhi()] ?? ""
        let timeWuXingGan: String = LunarUtil.WU_XING_GAN[lunar.getTimeGan()] ?? ""
        let timeWuXingZhi: String = LunarUtil.WU_XING_ZHI[lunar.getTimeZhi()] ?? ""
        let wuXing: [String] = [
            yearWuXingGan + yearWuXingZhi,
            monthWuXingGan + monthWuXingZhi,
            dayWuXingGan + dayWuXingZhi,
            timeWuXingGan + timeWuXingZhi
        ]

        // 取最近前后节气，用于页面提示“上一节气/下一节气”
        let prev = lunar.getPrevJieQi()
        let next = lunar.getNextJieQi()
        // 数九、三伏都可能不存在（不在区间内时返回 nil）
        let shuJiu = lunar.getShuJiu()
        let fu = lunar.getFu()

        return LunarFeatureSnapshot(
            constellation: solar.getXingZuo(),
            ganZhi: [lunar.getYearInGanZhi(), lunar.getMonthInGanZhi(), lunar.getDayInGanZhi(), lunar.getTimeInGanZhi()],
            shengXiao: [lunar.getYearShengXiao(), lunar.getMonthShengXiao(), lunar.getDayShengXiao(), lunar.getTimeShengXiao()],
            jieQi: lunar.getJieQi(),
            prevJieQi: prev.map { LunarJieQiNode(name: $0.getName(), solarYmd: $0.getSolar().toYmd()) },
            nextJieQi: next.map { LunarJieQiNode(name: $0.getName(), solarYmd: $0.getSolar().toYmd()) },
            shuJiu: shuJiu.map { LunarPeriodDay(name: $0.getName(), dayIndex: $0.getIndex()) },
            sanFu: fu.map { LunarPeriodDay(name: $0.getName(), dayIndex: $0.getIndex()) },
            naYin: naYin,
            wuXing: wuXing,
            dayYi: lunar.getDayYi(),
            dayJi: lunar.getDayJi(),
            timeYi: lunar.getTimeYi(),
            timeJi: lunar.getTimeJi(),
            directions: LunarDirections(
                caiShen: lunar.getDayPositionCaiDesc(),
                xiShen: lunar.getDayPositionXiDesc(),
                fuShen: lunar.getDayPositionFuDesc(),
                yangShen: lunar.getDayPositionYangGuiDesc(),
                yinShen: lunar.getDayPositionYinGuiDesc()
            ),
            taiShen: lunar.getDayPositionTai(),
            pengZu: "\(lunar.getPengZuGan()) \(lunar.getPengZuZhi())",
            chong: lunar.getDayChongShengXiao(),
            sha: lunar.getDaySha(),
            baZi: baZi,
            jianChu: lunar.getZhiXing(),
            jiShen: lunar.getDayJiShen(),
            xiongSha: lunar.getDayXiongSha(),
            xiu: LunarXiuInfo(
                xiu: lunar.getXiu(),
                zheng: lunar.getZheng(),
                animal: lunar.getAnimal(),
                gong: lunar.getGong(),
                shou: lunar.getShou(),
                luck: lunar.getXiuLuck()
            ),
            zhiShen: LunarZhiShenInfo(
                name: lunar.getDayTianShen(),
                kind: lunar.getDayTianShenType(),
                luck: lunar.getDayTianShenLuck()
            )
        )
    }
}

public extension Date {
    // MARK: - 便捷单项属性
    // 这些属性都复用 `lunarFeatures()`，便于 `date.dayYi` 这种调用方式。

    /// 星座（白羊/金牛/...）
    var constellation: String { lunarFeatures().constellation }
    /// 四柱干支：[年柱, 月柱, 日柱, 时柱]
    var ganZhi: [String] { lunarFeatures().ganZhi }
    /// 四柱生肖：[年生肖, 月生肖, 日生肖, 时生肖]
    var shengXiao: [String] { lunarFeatures().shengXiao }
    /// 当日节气名称；若当天非节气日则为空字符串
    var jieQi: String { lunarFeatures().jieQi }
    /// 上一个节气节点
    var prevJieQi: LunarJieQiNode? { lunarFeatures().prevJieQi }
    /// 下一个节气节点
    var nextJieQi: LunarJieQiNode? { lunarFeatures().nextJieQi }
    /// 数九信息（不在数九区间时为 `nil`）
    var shuJiu: LunarPeriodDay? { lunarFeatures().shuJiu }
    /// 三伏信息（不在三伏区间时为 `nil`）
    var sanFu: LunarPeriodDay? { lunarFeatures().sanFu }
    /// 日纳音
    var naYin: String { lunarFeatures().naYin }
    /// 四柱五行：[年柱, 月柱, 日柱, 时柱]
    var wuXing: [String] { lunarFeatures().wuXing }
    /// 每日宜
    var dayYi: [String] { lunarFeatures().dayYi }
    /// 每日忌
    var dayJi: [String] { lunarFeatures().dayJi }
    /// 时辰宜
    var timeYi: [String] { lunarFeatures().timeYi }
    /// 时辰忌
    var timeJi: [String] { lunarFeatures().timeJi }
    /// 吉神方位集合（财神/喜神/福神/阳神/阴神）
    var directions: LunarDirections { lunarFeatures().directions }
    /// 财神方位
    var caiShen: String { lunarFeatures().directions.caiShen }
    /// 喜神方位
    var xiShen: String { lunarFeatures().directions.xiShen }
    /// 福神方位
    var fuShen: String { lunarFeatures().directions.fuShen }
    /// 阳神方位
    var yangShen: String { lunarFeatures().directions.yangShen }
    /// 阴神方位
    var yinShen: String { lunarFeatures().directions.yinShen }
    /// 胎神方位
    var taiShen: String { lunarFeatures().taiShen }
    /// 彭祖百忌
    var pengZu: String { lunarFeatures().pengZu }
    /// 冲（当前实现返回冲生肖）
    var chong: String { lunarFeatures().chong }
    /// 煞方位
    var sha: String { lunarFeatures().sha }
    /// 八字（四柱）
    var baZi: [String] { lunarFeatures().baZi }
    /// 建除十二神
    var jianChu: String { lunarFeatures().jianChu }
    /// 吉神列表
    var jiShen: [String] { lunarFeatures().jiShen }
    /// 凶煞列表
    var xiongSha: [String] { lunarFeatures().xiongSha }
    /// 二十八宿信息
    var xiu: LunarXiuInfo { lunarFeatures().xiu }
    /// 值神信息
    var zhiShen: LunarZhiShenInfo { lunarFeatures().zhiShen }
}
