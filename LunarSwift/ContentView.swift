import SwiftUI
import LunarSwift

struct ContentView: View {
    @State private var date: Date = Date()
    @State private var useNow: Bool = true

    private var snapshot: LunarFeatureSnapshot {
        let input = useNow ? Date() : date
        return input.lunarFeatures(timeZone: .current)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("使用当前时间", isOn: $useNow)
                            .onChange(of: useNow) { newValue in
                                if newValue { date = Date() }
                            }
                        DatePicker("选择日期时间", selection: $date)
                            .disabled(useNow)
                    }

                    InfoSection(title: "核心") {
                        [
                            ("星座", snapshot.constellation),
                            ("节气", snapshot.jieQi.isEmpty ? "无" : snapshot.jieQi),
                            ("数九", periodText(snapshot.shuJiu)),
                            ("三伏", periodText(snapshot.sanFu)),
                            ("建除十二神", snapshot.jianChu),
                            ("值神", "\(snapshot.zhiShen.name) / \(snapshot.zhiShen.kind) / \(snapshot.zhiShen.luck)")
                        ]
                    }

                    InfoSection(title: "干支 生肖 五行") {
                        [
                            ("四柱干支", snapshot.ganZhi.joined(separator: "  ")),
                            ("四柱生肖", snapshot.shengXiao.joined(separator: "  ")),
                            ("八字", snapshot.baZi.joined(separator: "  ")),
                            ("纳音", snapshot.naYin),
                            ("五行", snapshot.wuXing.joined(separator: "  "))
                        ]
                    }

                    InfoSection(title: "宜忌") {
                        [
                            ("每日宜", join(snapshot.dayYi)),
                            ("每日忌", join(snapshot.dayJi)),
                            ("时辰宜", join(snapshot.timeYi)),
                            ("时辰忌", join(snapshot.timeJi)),
                            ("吉神", join(snapshot.jiShen)),
                            ("凶煞", join(snapshot.xiongSha))
                        ]
                    }

                    InfoSection(title: "方位") {
                        [
                            ("财神", snapshot.directions.caiShen),
                            ("喜神", snapshot.directions.xiShen),
                            ("福神", snapshot.directions.fuShen),
                            ("阳神", snapshot.directions.yangShen),
                            ("阴神", snapshot.directions.yinShen),
                            ("胎神", snapshot.taiShen)
                        ]
                    }

                    InfoSection(title: "其他") {
                        [
                            ("彭祖百忌", snapshot.pengZu),
                            ("冲", snapshot.chong),
                            ("煞", snapshot.sha),
                            ("二十八宿", "\(snapshot.xiu.xiu)\(snapshot.xiu.zheng)\(snapshot.xiu.animal)"),
                            ("上一节气", jqText(snapshot.prevJieQi)),
                            ("下一节气", jqText(snapshot.nextJieQi))
                        ]
                    }
                }
                .padding()
            }
            .navigationTitle("Lunar 功能验证")
        }
    }

    private func join(_ values: [String]) -> String {
        values.isEmpty ? "无" : values.joined(separator: "、")
    }

    private func periodText(_ period: LunarPeriodDay?) -> String {
        guard let period else { return "无" }
        return "\(period.name) 第\(period.dayIndex)天"
    }

    private func jqText(_ jq: LunarJieQiNode?) -> String {
        guard let jq else { return "无" }
        return "\(jq.name) (\(jq.solarYmd))"
    }
}

#Preview {
    ContentView()
}

private struct InfoSection: View {
    let title: String
    let items: [(String, String)]

    init(title: String, items: [(String, String)]) {
        self.title = title
        self.items = items
    }

    init(title: String, _ builder: () -> [(String, String)]) {
        self.title = title
        self.items = builder()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(item.1)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                    if idx != items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
