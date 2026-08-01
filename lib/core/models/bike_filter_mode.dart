/// 篩選模式（站點卡片列表用的篩選器，beta 功能）。
///
/// 預設 [all] 表示不篩選車種；[regularOnly] 只顯示有一般車的站點；
/// [electricOnly] 只顯示有電輔車的站點。兩者都用原始欄位 (`sbi` / `eyb`)
/// 作為門檻，與原始資料契合。
enum BikeFilterMode {
  all,
  regularOnly,
  electricOnly,
}
