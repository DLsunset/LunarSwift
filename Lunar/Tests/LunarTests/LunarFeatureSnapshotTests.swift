import XCTest
@testable import LunarSwift

final class LunarFeatureSnapshotTests: XCTestCase {
    func testDateExtensionReturnsRequestedFeatures() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 10, minute: 30, second: 0))!

        let snapshot = date.lunarFeatures(timeZone: calendar.timeZone)

        XCTAssertFalse(snapshot.constellation.isEmpty)
        XCTAssertEqual(snapshot.ganZhi.count, 4)
        XCTAssertEqual(snapshot.shengXiao.count, 4)
        XCTAssertFalse(snapshot.naYin.isEmpty)
        XCTAssertEqual(snapshot.wuXing.count, 4)
        XCTAssertEqual(snapshot.baZi.count, 4)
        XCTAssertFalse(snapshot.jianChu.isEmpty)
        XCTAssertFalse(snapshot.zhiShen.name.isEmpty)
        XCTAssertFalse(snapshot.xiu.xiu.isEmpty)
    }

    func testDateComputedPropertiesMatchSnapshot() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 10, minute: 30, second: 0))!

        let snapshot = date.lunarFeatures(timeZone: calendar.timeZone)

        XCTAssertEqual(date.dayYi, snapshot.dayYi)
        XCTAssertEqual(date.dayJi, snapshot.dayJi)
        XCTAssertEqual(date.timeYi, snapshot.timeYi)
        XCTAssertEqual(date.timeJi, snapshot.timeJi)
        XCTAssertEqual(date.jianChu, snapshot.jianChu)
        XCTAssertEqual(date.zhiShen, snapshot.zhiShen)
        XCTAssertEqual(date.caiShen, snapshot.directions.caiShen)
    }
}
