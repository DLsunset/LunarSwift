# Lunar Swift (Date Extension API)

当前对外推荐入口是 `Date` 扩展：

```swift
import LunarSwift

let snapshot = Date().lunarFeatures(timeZone: .current)
print(snapshot.ganZhi)      // 四柱干支
print(snapshot.shengXiao)   // 四柱生肖
print(snapshot.jieQi)       // 当日节气（若无则空）
print(snapshot.zhiShen)     // 值神
```

也支持单项计算属性：

```swift
import LunarSwift

let date = Date()
print(date.dayYi)      // 每日宜
print(date.timeJi)     // 时辰忌
print(date.jianChu)    // 建除十二神
print(date.zhiShen)    // 值神
print(date.caiShen)    // 财神方位
```

说明：若同一页面要读取很多字段，优先使用 `lunarFeatures()` 一次获取，避免重复计算。

## API 

- 星座
- 干支
- 生肖
- 节气（含前后节气）
- 数九
- 三伏
- 纳音五行
- 每日宜忌
- 时辰宜忌
- 吉神方位（财神、喜神、福神、阳神、阴神）
- 胎神方位
- 彭祖百忌
- 冲煞
- 八字
- 建除十二神
- 吉神凶煞
- 二十八星宿
- 值神

数据来自于https://github.com/6tail/lunar-javascript
