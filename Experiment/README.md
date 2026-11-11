# 雙 qubit 節律模型：Qiskit 基礎環境

依據 `../Plan/plan.typ`，目前範圍停在 **3.1 Local evolution 與 coupling**。使用 Qiskit 建立 RY、RXX、RZZ 電路，再由 Qiskit Aer 的 CPU density-matrix simulator 演化；不是以 SciPy 求解器取代 Qiskit。SciPy 只用於測試中的獨立矩陣指數參考。

## 所有組員的安裝與執行

先取得完整專案（下載 ZIP 後解壓縮，或使用 Git clone），不要只下載 `Experiment` 裡的單一檔案。每個人都要在自己的電腦建立 `.venv`。

以下 `你的專案路徑` 請換成自己實際儲存的位置。所有安裝、測試與執行命令都要在 `Experiment` 資料夾內進行；可用 `dir`（Windows）或 `ls`（macOS）確認看得到 `pyproject.toml`、`configs` 和 `src`。路徑含空格時保留雙引號。

### Windows：PowerShell

```powershell
cd "你的專案路徑\QC final project\Experiment"
py -3.11 --version
$env:PYTHONUTF8 = "1"
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
.\.venv\Scripts\python.exe -m pip install -e ".[test]"
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -m pytest
```

確認安裝和測試成功後執行：

```powershell
.\.venv\Scripts\python.exe -m qc_clock.cli --config configs/baseline.toml --output outputs/baseline_001
```

也可用現有的安裝腳本取代安裝及測試步驟：`powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Python python`。此處 `python` 須指向 3.11–3.13；也可傳入自己的 Python 執行檔完整路徑。上述直接呼叫虛擬環境 Python 的方式不需要執行 Activate，也不需要更改全機執行原則。

### Windows：命令提示字元 CMD



```bat
cd /d "你的專案路徑\QC final project\Experiment"
py -3.11 --version
set "PYTHONUTF8=1"
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
.\.venv\Scripts\python.exe -m pip install -e ".[test]"
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m qc_clock.cli --config configs/baseline.toml --output outputs/baseline_001
```


### macOS：Terminal（Apple Silicon／Intel）


```bash
cd "/你的專案路徑/QC final project/Experiment"
python3.11 --version
export PYTHONUTF8=1
python3.11 -m venv .venv
./.venv/bin/python -m pip install --upgrade pip setuptools wheel
./.venv/bin/python -m pip install -e '.[test]'
./.venv/bin/python -m pip check
./.venv/bin/python -m pytest
./.venv/bin/python -m qc_clock.cli --config configs/baseline.toml --output outputs/baseline_001
```


### 版本紀錄與團隊重現

`pyproject.toml` 是所有平台共用的相依版本範圍；每次模擬的 `metadata.json` 記錄實際 Python、平台與套件版本，分享結果時請一併提供設定檔及此檔案。目前 Windows／macOS 的實際安裝與執行均尚未完成驗證。

`setup.ps1` 成功安裝並通過測試後才產生 `requirements-lock.txt`，記錄實際解析的依賴版本。目前尚無已驗證的鎖定檔。此快照主要用於同平台、同 Python 版本重現；不同平台先依 `pyproject.toml` 安裝並各自測試，不強制共用 Windows 產生的快照。

需要手動保存相依快照時，在安裝及測試成功後執行（請勿將整個 `.venv` 加入 Git）：

```powershell
# Windows PowerShell
.\.venv\Scripts\python.exe -m pip freeze --exclude-editable | Set-Content requirements-windows.txt -Encoding utf8
```

```bash
# macOS Terminal
./.venv/bin/python -m pip freeze --exclude-editable > requirements-macos.txt
```

同平台重建時，先建立新的虛擬環境，用該環境的 Python 執行 `-m pip install -r requirements-windows.txt`（Mac 改用對應檔名），再執行 `-m pip install --no-deps -e .`，最後重新執行測試。

## 模型與 qubit 順序

時間單位為小時，ℏ = 1：

`H0 = (π/T_scn) Y_scn + (π/T_liver) Y_liver + Jx XX + Jz ZZ`。

| 計畫符號 | Qiskit qubit | Pauli label | 意義 |
| --- | --- | --- | --- |
| q₁ | 0 | IY、IZ | SCN，預設週期 24.5 h |
| q₂ | 1 | YI、ZI | 肝臟，預設週期 25.2 h |

Qiskit 的矩陣基底排列為 `|q_liver q_scn>`，與計畫書以 SCN 放左側的張量書寫方式不同，但局部作用及物理意義一致。預設初態為 `|00>`；每個 qubit 可設定 `RY(theta)` 後接 `RZ(phi)`，支援任意純態乘積初態。每個 qubit 是抽象節律狀態，不是器官的微觀量子態。

單步採二階 Strang 分解：自由旋轉半步 → XX、ZZ 耦合整步 → 自由旋轉半步。RY 的每個半步角度為 `ω_i dt/2`，RXX、RZZ 角度分別為 `2 Jx dt`、`2 Jz dt`。XX 與 ZZ 互相 commute，因此耦合兩項可依序精確實現；耦合與自由旋轉之間仍有離散誤差。固定總時間的全域誤差為 O(dt²)，不是任意步長都能視為精確解。

預設非零耦合 `Jx = Jz = 0.01 h⁻¹` 僅作模型建置示範，沒有經生理資料擬合。這裡沒有執行模型組別比較、週期估計或相位分析。

## 檔案與擴充方式

| 路徑 | 責任 |
| --- | --- |
| `configs/baseline.toml` | 模型參數、初態角度與模擬時間設定 |
| `src/qc_clock/config.py` | 型別結構、數值範圍與未知設定鍵檢查 |
| `src/qc_clock/model.py` | Hamiltonian、初態電路與單步 gate 實現 |
| `src/qc_clock/simulator.py` | 時間網格、Aer 演化、partial trace 與合法性檢查 |
| `src/qc_clock/cli.py` | 命令列入口、結果與版本紀錄 |
| `tests/test_baseline.py` | 解析解、獨立參考、步長收斂及 qubit 對應測試 |
| `model_setup.typ` | 模型建置說明，不依賴原計畫的本機 Typst 模板 |
| `outputs/` | 執行產物，自動建立並排除於 Git |

改參數時複製一份 TOML，再指定新的 `--config` 與 `--output`；不必改核心程式。輸出資料夾若已存在，程式會拒絕覆寫。`output_step_h` 只控制儲存頻率，`max_step_h` 控制積分最大步長；最後不足一個輸出間隔時仍儲存指定終點。每一輸出區間會等分成不超過最大步長的小步。

未來新增時間相依輸入時，應另外增加輸入設定與係數函式，於演化步中取樣並在不連續時間點切步。不要把排程或實驗條件硬寫進 CLI。未來若加入 Lindblad 通道，需另外實作 CPTP channel 與通道測試；**目前 density-matrix backend 並不代表已實作 dissipation**。也尚未提供任意混態／糾纏初態介面。

本次未實作 3.2 光暗排程、3.3 模型比較、第 4 節介入、第 5 節相位／恢復分析，以及第 7 節最佳化。第 6 節僅採用基礎驗證與保存參數的想法，將 QuTiP 流程改為 Qiskit。

## 輸出與簡單驗證

每次執行產生：

- `observables.csv`：時間、兩個 qubit 的 X/Y/Z、完整系統 purity、最小特徵值、trace 與 Hermitian 誤差。
- `states.npz`：完整 4×4 複數 density matrix、時間及 Bloch 向量，可用 `numpy.load` 讀取。
- `metadata.json`：完整設定、實際套件／Python 版本、qubit 對應、步數與診斷。

Aer 使用單一累積電路及多個 snapshot，避免每個時間點重跑完整前綴。這些是直接從模擬 density matrix 計算的 expectation values，沒有測量抽樣誤差。記憶體及電路大小隨步數和儲存點數增加，延長模擬前應調整輸出頻率。

測試涵蓋：無耦合時 `Z_i(t)=cos(2πt/T_i)`、X 分量及 qubit 順序；無耦合下只改肝臟初態不影響 SCN；有耦合時與獨立 `expm` 解吻合、步長減半誤差約降為四分之一；density matrix 合法性、總 purity 守恆與非整除終點。這些是數值正確性檢查，不是研究結果或生理驗證。

## 官方參考

- [Qiskit RXXGate 與角度慣例](https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.RXXGate)
- [AerSimulator（density_matrix）](https://qiskit.github.io/qiskit-aer/stubs/qiskit_aer.AerSimulator.html)
- [Aer 模擬器教學](https://qiskit.github.io/qiskit-aer/tutorials/1_aersimulator.html)

### Windows editable path repair

Python 3.11 may read Hatchling's UTF-8 `.pth` using a legacy locale codec even with UTF-8 mode enabled. `setup.ps1` now runs `fix_editable_path.py` with `-S` before installation (for recovery) and after installation. It preserves editable imports using an ASCII-only Python path literal. After a manual editable reinstall, run:

```bat
.\.venv\Scripts\python.exe -S fix_editable_path.py
```

### Visualize an existing run

No additional packages required (SVG):

```bat
.\.venv\Scripts\python.exe -m qc_clock.plot_svg --input outputs/baseline_003
```

Open `outputs/baseline_003/figures/observables.svg` in a browser. The four panels show X/Y/Z expectations and reduced-state purity. Local purity below one can arise from entanglement in this globally pure unitary simulation; it does not imply environmental decoherence.

For PNG figures including 3D Bloch trajectories and numerical checks, install matplotlib and run:

```bat
.\.venv\Scripts\python.exe -m pip install "matplotlib>=3.8,<4"
.\.venv\Scripts\python.exe -m qc_clock.plot --input outputs/baseline_003
```
