#set document(title: "Qiskit 雙 qubit 模型建置說明", author: "QC final project")
#set page(paper: "a4", margin: 22mm, footer: context align(center, counter(page).display("1")))
#set text(font: ("Noto Serif TC", "Arial"), size: 11pt, lang: "zh")
#set par(justify: true, leading: 0.7em)
#set heading(numbering: "1.1")

#align(center, text(size: 20pt, weight: "bold")[Qiskit 雙 qubit 模型建置說明])
#align(center)[建置範圍：Plan 第 3.1 節｜2026-11-12]

= 範圍與目前狀態
以 `../Plan/plan.typ` 為依據，僅建立雙 qubit 的自由演化與 XX＋ZZ 耦合。Qiskit 負責電路，Qiskit Aer 負責 density matrix 模擬。第 3.2 節起的光照排程、介入、比較與最佳化均未實作。第 6 節僅參考基礎驗證與版本保存概念。

*目前套件安裝因執行環境 DNS 解析失敗而中止；尚未實際執行 Aer 或物理測試。* 程式及測試已備妥，須完成 README 的安裝步驟後才能確認可執行性。此文件亦尚未經 Typst 編譯驗證。

= 模型與單位
時間以小時為單位，取 $planck=1$，定義
$ H_0 = (omega_1 / 2) Y_1 + (omega_2 / 2) Y_2
      + J_x X_1 X_2 + J_z Z_1 Z_2, quad omega_i = (2 pi) / T_i. $
預設 $T_1=24.5$、$T_2=25.2$ 小時，$J_x=J_z=0.01$ 每小時。週期與耦合皆為示範有效參數，沒有經生理資料校準。

計畫中的 $q_1$（SCN）對應 Qiskit qubit 0，$q_2$（肝臟）對應 qubit 1。Qiskit 基底順序為 $|q_2 q_1 chevron.r$，因此 $Y_1$ 的 Pauli label 為 `IY`，$Y_2$ 為 `YI`。這是矩陣表示順序的變換，沒有交換兩個組織的物理角色。

初態預設為 $|00 chevron.r$。每個 qubit 可由 `RY(theta)` 後接 `RZ(phi)` 準備純態，保留不同初始方向的設定空間。目前只支援純態乘積初態；保存及演化皆使用完整 4×4 density matrix，不以兩個獨立 Bloch 向量代替耦合系統。

= 電路演化
令 $H_A=(omega_1 Y_1+omega_2 Y_2)/2$，$H_B=J_x X_1X_2+J_z Z_1Z_2$。單步使用二階 Strang 分解：
$ U(delta t) approx exp(-upright(i) H_A delta t / 2)
  exp(-upright(i) H_B delta t)
  exp(-upright(i) H_A delta t / 2). $
每段自由旋轉半步使用 `RY(omega_i * dt / 2)`；耦合整步使用 `RXX(2 * Jx * dt)` 及 `RZZ(2 * Jz * dt)`。XX 與 ZZ 互相 commute，但與自由項一般不 commute；因此整體仍有步長誤差，固定觀測時間下全域誤差為 $O(delta t^2)$。

模擬採 `AerSimulator(method="density_matrix")`、CPU 執行，不需要遠端帳號。使用同一條累積電路於輸出時刻儲存 snapshot，避免反覆模擬相同的前綴。輸出期望值直接由 density matrix 計算，不含 shots 抽樣。預設模擬 48 小時，每 0.1 小時儲存，最大積分步長 0.05 小時；積分步長與輸出頻率分開設定。

本次只有 unitary evolution：
$ rho(t)=U(t)rho(0)U(t)^dagger. $
採用 density matrix 是為了保存完整狀態與方便日後擴充，並不代表已經加入 Lindblad dissipation。

= 觀測量與數值驗證
每個時間點對完整狀態取 partial trace，輸出兩個 qubit 的 X、Y、Z 分量。主要訊號為
$ s_1(t)=tr(rho(t)Z_1), quad s_2(t)=tr(rho(t)Z_2). $
這些是有效節律指標，不能直接解讀為睡眠、代謝或褪黑激素。完整系統 purity 與局部 Bloch 長度也需區分：糾纏可能使局部態變成 mixed state，而本次封閉系統的總 purity 應維持 1。

預備測試包含：
+ 無耦合且從零態出發時，$s_i(t)=cos(omega_i t)$，並檢查 X 分量與 qubit 順序。
+ 無耦合時，只改肝臟初態不影響 SCN。
+ 有耦合時，以 SciPy 獨立組裝矩陣及 `expm` 作數值參考；此工具只用於測試。
+ 步長減半後誤差約縮為四分之一；檢查 trace、Hermitian 性、非負特徵值及總 purity。
+ 設定錯誤與無法整除的最終時間。

以上尚未執行，不構成已完成的收斂報告。只有取得套件並通過測試後，才應開始使用基礎模擬結果。

= 結構與後續擴充
`configs/` 管理 TOML 參數；`src/qc_clock/` 分為設定、模型、模擬與 CLI；`tests/` 管理物理檢查；`outputs/` 只放執行產物。更換參數時複製設定檔，不修改核心模型。每次執行保存 CSV、完整狀態 NPZ、參數與實際套件版本，且拒絕覆寫已存在的輸出資料夾。

後續若增加光照，應另外定義時間相依係數並處理排程切換邊界；若增加 dissipation，則需另外建立 CPTP 通道及對應測試。目前不預先建立未實作的介入或分析介面，以免把未完成的能力混入現有模型。

= 執行與官方參考
於本資料夾執行 `setup.ps1` 完成安裝及測試，再依 `README.md` 的命令列範例執行。腳本成功後才會保存實際依賴版本快照。目前因安裝中斷，尚無已驗證版本快照。

+ #link("https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.RXXGate")[IBM Quantum：RXXGate]
+ #link("https://qiskit.github.io/qiskit-aer/stubs/qiskit_aer.AerSimulator.html")[Qiskit Aer：AerSimulator]
+ #link("https://qiskit.github.io/qiskit-aer/tutorials/1_aersimulator.html")[Qiskit Aer：模擬器教學]
