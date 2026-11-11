#import "@local/head:0.0.1": *
#show: head
#set figure(supplement: "Figure")
#show ref: it => {
  let eq = counter(heading).get() // 可選，主要針對方程
  let el = it.element
  if el != none and el.func() == math.equation {
    // 取得該方程式的編號數字
    let num = numbering(
      if el.numbering != none { el.numbering } else { "(1)" },
      ..counter(math.equation).at(el.location())
    )
    // 渲染成 式(1)
    [式#num]
  } else {
    it
  }
}
#let hh = {h(2em)}



#set document(title: "量子形式晝夜節律模型：計算研究方法", author: "研究計畫草案", date: datetime(year: 2026, month: 10, day: 21))
#set page(paper: "a4", margin: (x: 22mm, top: 20mm, bottom: 20mm), header: align(right, text(size: 8pt)[量子形式晝夜節律模型｜研究方法 v2.0 雙 qubit]), footer: context align(center, text(size: 9pt)[#counter(page).display("1")]))
#show heading.where(level: 1): set text(size: 18pt)
#let ket(x) = $|#x ⟩$
#let bra(x) = $⟨ #x |$
#let note(body) = block(width: 100%, inset: 10pt, fill: rgb("edf3f7"), radius: 3pt, body)
#let todo(body) = block(width: 100%, inset: 9pt, stroke: 0.5pt + rgb("9aaaba"), body)

#v(5mm)
#text(size: 25pt, weight: "bold")[量子形式晝夜節律模型]
#v(3mm)
#text(size: 14pt)[SCN 與肝臟雙 qubit：光照、時差與進食擾動]
#v(5mm)

= 研究目標與模型角色
本計畫以兩個 qubit 分別代表 SCN 中樞時鐘（$q_1$）與肝臟周邊時鐘（$q_2$）的有效節律狀態。太陽光是外部給定的古典光暗訊號，不另外設為 qubit。利用 QuTiP 模擬兩個時鐘在耦合下如何回應光照排程與局部脈衝，主要比較兩者的節律及相位差。

研究架構為：*外部光照 → SCN qubit ↔ 肝臟 qubit ← 進食脈衝*。光照只直接驅動 $q_1$，進食只直接擾動 $q_2$；兩者仍可經 coupling 間接影響對方。進食時程影響周邊時鐘的動物研究提供類比背景 [6]，不直接決定本模型的人體參數。

#note[每個 qubit 代表組織的抽象節律狀態，不代表整個器官的微觀 quantum state。XX＋ZZ coupling 與脈衝作用軸是待測試的有效模型，尚無一對一生理推導。本文件不包含已完成的模擬或擬合結果。]

= 共同數學定義與 Lindblad master equation
== Quantum state 與 Bloch sphere
兩個 qubit 的 Hilbert space 為
$ cal(H)=CC^2 ⊗ CC^2, $
總維度為 4。Pure state 用 normalized state vector 表示；為兼容 mixed state 與 open system，統一使用 density matrix：
$ rho=sum_n p_n |psi_n⟩⟨psi_n|, quad
  p_n>=0, quad sum_n p_n=1. $
其須滿足 $rho=rho^dagger$、$rho>=0$、$tr(rho)=1$。

令 $X_i,Y_i,Z_i$ 為第 $i$ 個 qubit 的 Pauli operator，例如 $X_1=X⊗I$、$X_2=I⊗X$。以 partial trace 得到 reduced density matrix，並寫為
$ rho_i=1/2(I+r_(i,x)X+r_(i,y)Y+r_(i,z)Z), quad
  r_(i,a)=tr(rho sigma_(i,a)). $
Pure state 的 Bloch vector 位於球面，mixed state 位於球內；entanglement 也可使局部狀態成為 mixed state，因此演化時仍使用完整系統。

== Unitary evolution
時間以小時為單位，設定 $ℏ=1$。無 dissipation 時，
$ (upright(d)rho)/(upright(d)t)=-upright(i)[H(t),rho], $
其中 $[A,B]=A B-B A$ 為 commutator。固定 Hamiltonian 下，
$ rho(t)=U(t)rho(0)U(t)^dagger, quad U(t)=exp(-upright(i) H t). $

== Lindblad master equation
加入 dissipation 時使用
$ (upright(d)rho)/(upright(d)t)=-upright(i)[H(t),rho]
  +sum_k (L_k rho L_k^dagger-1/2 {L_k^dagger L_k,rho}), $
其中 ${A,B}=A B+B A$ 為 anticommutator，$L_k$ 為 collapse operator [1]。初步考慮
$ L_(i,-)=sqrt(gamma_-)(|0⟩⟨1|)_i, quad
  L_(i,phi)=sqrt(gamma_phi/2)Z_i, quad i in {1,2}. $
兩者分別描述基底轉移與 pure dephasing，速率皆非負、單位為每小時。基底轉移不自動代表實際能量弛豫；這些通道尚未對應特定生理機制。全部速率為零時須還原為 unitary evolution。

加入 dissipation 主要檢查：暫態能否消退、不同 initial state 的結果能否逐漸接近，以及擾動後能否重新建立穩定的相位關係。這些不是必然結果；dissipation 也可能使振盪消失。受光強迫的週期輸出與黑暗中自持振盪須分開判斷。

= 雙 qubit 與外部光照模型
== Local evolution 與 coupling
保留繞 Y 軸的自由旋轉，以及 XX＋ZZ coupling：
$ H_0=omega_1/2 Y_1+omega_2/2 Y_2
  +J_x X_1 X_2+J_z Z_1 Z_2. $
無耦合時，單一 qubit 的 local evolution 為
$ U_i(t)=exp(-upright(i) omega_i t Y_i/2). $
從 $|0⟩$ 出發時，Bloch vector 在 X–Z 平面旋轉；耦合與外部驅動下不保證仍限制在該平面。初步使用 product initial state $|0⟩⊗|0⟩$，另比較不同初始相位。

自由週期 $T_i$ 與角頻率關係為 $omega_i=2pi/T_i$。可先沿用 $T_1=24.5$ 小時、$T_2=25.2$ 小時作示範，並與兩者皆為 24 小時比較；這些不是已驗證的 SCN／肝臟生理週期。耦合強度先比較零值與小量非零值，實際輸出週期由模擬估計。

== 古典光暗排程
主要排程採 24 小時週期、07:00–19:00 有光，白天強度由早晨逐漸增加、中午附近最強，再於傍晚減弱。令 $h=op("mod")(t,24)$ 為當地時刻的小時數，定義
$ ell_0(t)=cases(sin^2(pi (h-7)/12) & 7<=h<19,
  0 & "其他時間"). $
此設定在 07:00 與 19:00 為零，13:00 達到最大值 1；峰值位於所選日照時段的中點。它是無因次有效光輸入，用來類比日照強弱，不直接代表 lux，也不包含天氣、季節或室內活動造成的實際受光差異。光驅動為
$ H_L(t)=g_L/2 ell(t)X_1. $
時差實驗仍依下節定義平移整條光照曲線；熬夜則在此背景上另外加入夜間光脈衝。光照脈衝與正常日光皆透過同一個 $X_1$ 通道作用，不視為兩種不同生理機制。$g_L$ 為有效光反應強度，單位為每小時。

== 模型比較層次
+ *A：* 只用 $H_0$，建立無外部輸入的 unitary baseline。
+ *B：* 在 $H_0$ 上加入光照與指定脈衝，先研究 coherent response。
+ *C：* 使用與 B 相同的輸入，再加入 Lindblad dissipation，檢查收斂與恢復行為。

= 時差、熬夜與進食擾動
== 時差：整個光照排程位移
在介入時間 $t_j$ 後改用新排程：
$ ell(t)=cases(ell_0(t) & t<t_j,
  ell_0(t-Delta) & t>=t_j). $
$Delta>0$ 表示光照排程延後，$Delta<0$ 表示提前。先測試 $Delta=±6$ 小時，觀察 SCN 與肝臟如何調整。此操作只改外部排程，不直接旋轉或重設兩個 qubit。

== 熬夜：直接作用於 SCN 的夜間光脈衝
定義矩形脈衝
$ f(t;t_s,tau)=cases(1 & t_s<=t<t_s+tau,
  0 & "其他時間"). $
在正常光暗排程上增加夜間光：
$ H_("late")(t)=A_L/2 f(t;t_L,tau_L)X_1. $
初步可在 23:00 開始，持續 1 小時，再改變時間與強度。這裡的「熬夜」僅類比熬夜伴隨的額外光照，不包含光照不變的晚睡、睡眠剝奪或所有行為效應。$A_L$ 是有效驅動強度，不直接對應螢幕亮度。

== 進食：直接作用於肝臟的脈衝
加入
$ H_("meal")(t)=A_F/2 f(t;t_F,tau_F)X_2. $
$t_F$ 為擾動起點、$tau_F$ 為有效作用時間、$A_F$ 為強度。先測試一次夜間脈衝，再比較白天同強度脈衝及連續多日夜間脈衝。作用時間不必等於用餐時間，強度也不直接對應熱量。

選擇 $X_2$ 是為了讓脈衝與沿 $Y_2$ 的自由演化不 commute，並測試其對軌跡的影響；它不是進食的已知微觀 operator。單次脈衝能否產生持續相位改變仍需檢驗，不能由動物的長期進食排程研究直接推定。

== 完整 Hamiltonian 與實驗組
$ H(t)=H_0+H_L(t)+H_("late")(t)+H_("meal")(t). $
主比較一次只改一種介入，保留相同 initial state、參數與觀測窗：
+ 正常光暗排程，無額外脈衝：作為配對控制。
+ 光照排程提前／延後：研究時差。
+ 正常排程加 $q_1$ 夜間光脈衝：研究額外光照。
+ 正常排程加 $q_2$ 進食脈衝：研究周邊擾動。
+ 最後才組合時差與進食，或同時給兩種脈衝，觀察是否加重或減少相位偏離。

先以 30 天建立控制歷史，再介入並追蹤至少 10 天，每 0.1 小時輸出一次。若有穩定節律，可在一週期內選不同相位施加脈衝，建立兩種輸入各自的 phase response curve（PRC）。未形成穩定節律時，不強行建立 PRC。Unitary 模型的前置演化不代表已收斂至吸引態。

= 節律的測量與比較
== 同時觀察 SCN 與肝臟
主要節律訊號固定為
$ s_1(t)=tr(rho(t)Z_1), quad s_2(t)=tr(rho(t)Z_2). $
兩者為 Bloch vector 的 Z 投影，介於 −1 與 1，適合觀察本模型繞 Y 軸的自由旋轉。它們是有效節律指標，不直接等於清醒程度、睡眠深度、褪黑激素濃度或肝臟代謝量。其他 Bloch 分量作輔助診斷。

== 週期、振幅與相位差
+ *週期：* 由各訊號相鄰峰值的時間差估計。
+ *振幅：* 在指定週期窗內，以最大值與最小值之差的一半估計。
+ *內部相位差：* 用對應週期的峰值時間差 $d_n=t_(2,n)-t_(1,n)$，正值代表肝臟峰值較晚。保存未包裹值，並以控制週期換算圓周相位差以避免跨日誤配。

同步不要求兩者同時達峰；重點是相位差是否穩定。與配對控制比較 $d_n$ 的改變，觀察是否出現額外內部失同步。峰值相位只是模型操作定義，不能直接當作 DLMO。

== 脈衝效果與時差恢復
對每個 qubit，定義相對無介入控制的峰值提前量
$ Delta t_i=t_(i,"control")-t_(i,"perturbed"). $
正值為提前、負值為延後。脈衝後追蹤數個週期，區分當下訊號偏轉與較持續的相位改變，並記錄振幅是否降低。

時差實驗除觀察內部相位差，也計算每個 qubit 的峰值相對新開燈時間的差。只有相對新排程的相位穩定，才討論外部牽引。再同步可暫定為連續三個週期落在參考相位差的 1 小時內：短脈衝用配對控制作參考，時差用從頭採新排程的穩定控制作參考。無穩定參考則不計恢復時間，也不要求恢復至零相位差。

振幅過小、多峰或持續漂移時，標記相位／恢復時間無法可靠判定。Unitary evolution 不保證穩健牽引；模型也可能完全沒有恢復，這些均應列為結果。

= QuTiP 實作方式
兩個 qubit 的 state vector 有 4 個分量，density matrix 為 4 × 4，可用古典電腦直接求解 [5]。
+ 用 `tensor` 建立 operator 與 initial state；A、B 的 pure state 用 `sesolve`。
+ 以 `QobjEvo` 表示光照排程與局部脈衝；切換處分段求解，延續前段狀態。
+ C 用 `mesolve` 加入 collapse operators；同時輸出兩個 Z expectation values。
+ 繪製輸入時序、兩條節律曲線、相位差及各介入的 PRC／恢復比較。

必要檢查包含：無耦合無驅動時，從 $|0⟩$ 出發有 $s_i(t)=cos(omega_i t)$；無耦合時，單獨的 $q_2$ 脈衝不影響 $q_1$；所有 dissipation rates 為零時 C 回到 B。另檢查 density matrix 合法性、求解容差收斂，保存參數與版本。

= 後續最佳化與資料擬合
先完成合成實驗，再以 SciPy 的 `least_squares` 或多起點搜尋調整少量參數。保留頻率、XX／ZZ coupling、光反應、進食脈衝與 dissipation rates 的調整空間，但不一次全部開放。設定界限、loss function 及必要 regularization，檢查 identifiability。

資料按個體或連續時段切為 training／validation／test，避免相鄰資料洩漏。若有組織 clock-gene reporter 資料，可對各訊號建立尺度、基線與延遲的 observation model。人體褪黑激素／DLMO 資料只作中樞相關輸出的候選間接指標，需另建映射 [4]，不能當作肝臟節律的直接量測。

PRC 比較需對齊刺激種類、相位原點、強度、持續時間與評估窗 [3]；不混用光 PRC 與進食 PRC。未來應比較留出預測與簡單週期／古典節律模型 [2]。

#todo[*後續待填*\
資料來源與觀測對應：＿＿\
參數範圍、脈衝設定與相位判定規則：＿＿\
Loss function、regularization 與資料切分：＿＿\
擬合結果、不確定性與模型限制：＿＿]

= 預期成果與限制
預期交付可重現的雙 qubit 模擬，並比較正常光照、時差、SCN 光脈衝與肝臟進食脈衝造成的節律變化。核心問題是：兩個時鐘是否以不同方式調整、相位關係是否被破壞，以及能否重新穩定。

本模型是生理問題啟發的量子類比，不將器官間的實際溝通視為量子耦合。指定近 24 小時頻率或擬合到振盪曲線，不足以證明生理機制；進食效應也不能直接延伸為酒精效應。若無法保留節律或預測未見輸入，應報告限制，再決定是否擴充。

= 參考文獻
[1] Lindblad, G. (1976). On the generators of quantum dynamical semigroups. /Communications in Mathematical Physics, 48/, 119–130. #link("https://doi.org/10.1007/BF01608499")[DOI]

[2] Jewett, M. E., Forger, D. B., & Kronauer, R. E. (1999). Revised limit cycle oscillator model of human circadian pacemaker. /Journal of Biological Rhythms, 14/(6), 493–500. #link("https://doi.org/10.1177/074873049901400608")[DOI]

[3] Khalsa, S. B. S., et al. (2003). A phase response curve to single bright light pulses in human subjects. /The Journal of Physiology, 549/(3), 945–952. #link("https://doi.org/10.1113/jphysiol.2003.040477")[DOI]

[4] Benloucif, S., et al. (2008). Measuring melatonin in humans. /Journal of Clinical Sleep Medicine, 4/(1), 66–69. #link("https://pmc.ncbi.nlm.nih.gov/articles/PMC2276833/")[全文]

[5] Johansson, J. R., Nation, P. D., & Nori, F. (2012). QuTiP: An open-source Python framework for the dynamics of open quantum systems. /Computer Physics Communications, 183/(8), 1760–1772. #link("https://arxiv.org/abs/1110.0573")[作者預印本]

[6] Damiola, F., et al. (2000). Restricted feeding uncouples circadian oscillators in peripheral tissues from the central pacemaker in the suprachiasmatic nucleus. /Genes & Development, 14/, 2950–2961. #link("https://pmc.ncbi.nlm.nih.gov/articles/PMC317100/")[全文]
