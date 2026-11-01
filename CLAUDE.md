# CLAUDE.md

Guidance for Claude Code (and humans) working in this repository.

## What this is

An all-digital PLL (ADPLL) generator. The PLL is written in Verilog (`src/`) on top of a small set of
technology cells (`PLL_CELL_*`). The flow synthesizes it with yosys, turns the netlists into SPICE with
openroad, characterizes the analog blocks (delay cells, injection, symmetric mux, DCO) in ngspice, and
converts those results into Verilog delay models for fast digital simulations of the whole PLL.

## Layout

- `settings.mk`: shared by `sim/` and `syn/`. PDK selection, sources, tools (native or docker), the generic
  `models.inc`/`.spiceinit` rules. It includes `lib/<PDK>.mk`.
- `lib/<PDK>.mk`: makefile fragment of each PDK (PDK_ROOT, SPICE models, `.spiceinit`, gate-level models,
  design-target overrides). `lib/<PDK>_settings.tcl`: liberty/LEF/CDL/SPICE paths and supply pins (tcl scripts).
- PDKs: `ics55` (55 nm, 1.2 V), `ihp-sg13g2` (130 nm, 1.2 V), `ihp-sg13cmos5l` (130 nm CMOS 5 metals, only in
  the docker image; same devices and cell netlists as sg13g2, so its pre-layout results are identical),
  `sky130A` (130 nm, 1.8 V, `sky130_fd_sc_hd`).
- `src/`: RTL, testbenches (`*_tb.v`, `test_*.v`, `test_*.sp`) and the Python post-processing.
  - `pll_cells_<PDK>.v`: maps `PLL_CELL_*` to the standard cells of the PDK. The `` `ifdef YOSYS `` section
    declares those standard cells as blackboxes for synthesis.
- `syn/`: `Makefile`, `tcl/` (yosys, openroad, sta scripts), `escape_names.py`, `spice_ports.py`.
- `sim/`: `Makefile` and `tests.mk` (all the simulation targets).
- Outputs are per PDK: `syn/outputs/<PDK>/` and `sim/outputs/<PDK>/` (`SYN_OUT`, `SIM_OUT`).

## Commands

```sh
# PDK is ics55, ihp-sg13g2, ihp-sg13cmos5l or sky130A (the default is set in settings.mk)
make -C syn PDK=ics55 TOP=FINE_DELAY all gen   # synthesize + powered SPICE netlist
make -C sim PDK=ics55 test_fine_delay          # ngspice delay characterization (also mid/coarse)
make -C sim PDK=ics55 test_pll_injection test_sym_delay
make -C sim PDK=ics55 test_dco_noise           # DCO phase noise (ISF method, ~1h on 10 cores)
make -C sim PDK=ics55 test_dco_spectre SPECTRE=...  # optional reference: Spectre PSS+pnoise of the same DCO
make -C sim PDK=ics55 test_pll_digital         # iverilog, uses the models made from the ngspice results
make -C sim PDK=ics55 test_pll_digital_inj     # same, INJ_EN=1 (active after LOCKED); both check for glitches (PASS/FAIL)
make -C sim PDK=ics55 pll_target               # design target from the characterization (src/pll_target.py)
make -C sim PDK=ics55 report                   # executes src/pll_design.ipynb -> sim/outputs/<PDK>/report/pll_design.html
make -C sim compare                            # table of every PDK with a report -> sim/outputs/compare.{md,html}
make -C sim PDK=ics55 clean                    # only this PDK; clean_all removes every PDK
```

Simulations depend on their netlists, so a `sim` target synthesizes what it needs (`make -C syn TOP=...`).
Each block netlist also depends on its own RTL (`sim/tests.mk`), so editing e.g. `sym_mux.v` only re-runs the
characterizations of the blocks that contain it (the coarse characterization takes hours).

## Porting to a new technology (design methodology)

The architecture and the code widths (coarse 15, mid 15, fine 31) are fixed; a technology changes the delays.
1. Three files: `lib/<PDK>.mk` (copy one: `PDK_MODELS_INC` with the model `.LIB`, the standard-cell SPICE,
   `lvdd` and `PLL_CELL_BUFFX0`; `PDK_SPICEINIT`; `CELLS_SRC`/`CELLS_ADD_DEF`), `lib/<PDK>_settings.tcl`
   (`LIBS`, `LEFS`, `CDLS`, `SPICES`, `LIBS_BC/WC`, and `POWER_PINS`/`GROUND_PINS` if the cells are not VDD/VSS),
   and `src/pll_cells_<PDK>.v` (every `PLL_CELL_*`; NAND3 input A0 on the transistor next to ground).
2. If the transistors are not `nm*_lp`/`sg13_*`/`sky130_fd_pr__*fet*`, add them to `NMOS`/`PMOS` in `create_isf.py`.
3. `make -C sim PDK=<PDK> report` runs everything: characterization, ISF, `pll_target`, RTL, report.
   `pll_target.py` (functions `pll_model.design`, `choose_gains`, `choose_locked_gains`) picks:
   - the supported band: tuning range ±20 %, `BBPD_CK` and the window end before T/2 (+15 %);
   - f_OUT = N f_REF: the highest N whose smallest pull-in K_P gives beta_p <= 1 % of T_OUT (the loop must pull in
     from either end of the fine range, also with the target at 25 %/75 % of it; on ics55 this reproduces the
     hand-tuned 1 GHz, 4096/256 vs 3967/257);
   - gains after LOCKED (gear shifting) for minimum jitter with the ISF noise, if `test_dco_noise.csv` exists.
   It writes `pll_target.vh` (compiled before `pll_test.v`: `TB_REF_T`, `TB_FCW`, `TB_KP/KI[_LOCKED]`) and
   `pll_target.json` (notebook section 0). Fix any choice in `lib/<PDK>.mk`: `PLL_F_REF`, `PLL_FCW`,
   `PLL_KP`/`PLL_KI`, `PLL_KP_LOCKED`/`PLL_KI_LOCKED` (ics55 fixes its reference design).
4. Check in the report: the coverage of the tuning curve (fine range > mid step, mid range > coarse step;
   sky130 fine/mid is 0.96 and sg13g2 mid/coarse 0.99), the injection margins, and the RTL lock/glitch rows.
- Slow technologies: the sg13g2/sky130 cells are ~3x slower than ics55 (tuning ~0.2-0.7 GHz). The sg13g2 fine line
  saturates (and code 31 is faster than 30), which limits the pull-in. Use a lower `PLL_F_REF` for useful N.
- `ISF_LEN` (default 20n) must hold several DCO periods. Slow PDKs set `ISF_NPHASE/NPER/TMAX/DQ` in
  `lib/<PDK>.mk` (each ISF run is ~800 BSIM4/PSP devices; PSP is ~3x slower per step than BSIM4).
- `ISF_FROM_PDK` (lib/<PDK>.mk) reuses the ISF of an electrically identical PDK (cmos5l <- sg13g2).
- `analyze_rtl` skips 20 % of the record after LOCKED: with gear shifting the slower gains still pull in.
- Results of every PDK: `docs/technology_comparison.md` (copy of `make -C sim compare`).

## Tools and docker

Each tool (`YOSYS`, `OPENROAD`, `STA`, `IVERILOG`, `VVP`, `NGSPICE`, `PYTHON`) runs natively when it is
installed and the PDK exists locally; otherwise it runs inside `factory.symbioticeda.com/asic-all:dev`
with the repo and the PDK mounted at the same absolute paths. Force with `USE_DOCKER=1` / `USE_DOCKER=0`.
- macOS has no openroad/sta/iverilog, so those always go through docker there.
- IHP (`ihp-sg13g2`) only exists inside the image (`/usr/local/share/OpenPDKs`), so everything runs in docker.
- `PYTHON` needs numpy, scipy, matplotlib and pandas (`requirements.txt`); docker is used if they are missing.
- Variables the tcl scripts read from the environment must be listed in `DOCKER_ENV` in `settings.mk`.

## The analog flow (things that are easy to break)

- Synthesized `_net.v` netlists have no supplies (they are also used by iverilog/SDF). `syn/tcl/netlist.tcl`
  adds `VDD`/`VSS` ports and `global_connect`s every cell supply pin before `write_cdl`.
- openroad writes subcircuit ports alphabetically. `syn/spice_ports.py` reorders them to
  `VDD VSS <verilog port order, buses MSB first>`, which is what the testbenches instantiate positionally.
- `syn/escape_names.py` sanitizes yosys escaped names (including `$paramod...` modules) and must keep the
  whitespace after them.
- The netlists are flattened, so internal nodes are like `xpll.pll_dig/flock_cnt_0_` or `xpll.pll_ana_INJ_WIN`
  (see `src/test_pll_tran.sp`), not the original hierarchy.
- `PLL_CELL_BUFFX0` (testbench loads) is defined per PDK in the generated `models.inc`, together with the
  model `.LIB` and the standard-cell SPICE include.

## Injection and phase detector (things that are easy to break)

- The symmetric mux passes `INJ_EDGE_BALANCED` (NAND2) during `INJ_WIN`: the injected edge is the **rising**
  edge of OUT, the same edge the SS-BBPD compares. Both mux paths are INV + NAND2 + NAND2 with equal loads
  (the dummy inverters of `PLL_SYM` balance them and drive the level flops).
- The SS-BBPD latch is captured with `BBPD_CK` (`injection.v`, `CK_NDELS` buffers after the window), after it
  arbitrates. `il_dco.v` combines it with two level samples (`EARLY = LC ? latch : L0`) for a symmetric
  +/- T/2 characteristic. Requires `BBPD_CK - INJ_EDGE < T_OUT/2`. `SS_BBPD = 2'b01` early, `2'b10` late.
- `INJ_EN` is retimed on REF rising and gated by `LOCKED` and `PHASE_OK` (`INJ_ACT` in `pll_logic.v`).
- Fine code = `FILTER_OUT / 2^(FILTER_BITS - $clog2(FINE_NDELS))` (integer part + 1st-order DSM fraction).
- `pll_test.v` gains: `-D TB_KP=.. -D TB_KI=..` (acquisition) and `-D TB_KP_LOCKED=.. -D TB_KI_LOCKED=..`
  (after LOCKED). A low-jitter KP cannot pull in alone (see the notebook, section 7).

## Design notebook and models

- `src/pll_design.ipynb`: the design report (reads `sim/outputs/<PDK>`, or `PLL_SIM_OUT`). Executed by `make report`.
- `src/pll_model.py`: characterization loader, linear (hybrid z-domain) model, behavioral model that mimics the
  RTL arithmetic (validated against `test_pll_digital`: same noise-free TIE), and the edge-log analysis.
- `pll_test.v` writes `test_pll[_inj]_edges.txt` (edges of OUT/REF/FINE_OUT, LOCKED, INJ_ACT, filter, codes).
- `src/noise_shape.ipynb` is deprecated; `src/dco_shape.ipynb` is still the DCO-noise fit.

## SPICE conventions (ngspice)

- Parameter expressions as `'expr'` (works in ngspice and HSPICE). No bare `(param)` or bare param values.
- `GND` is ground in ngspice: never add a `vgnd GND 0` source (it is a short).
- `.SAVE` instead of `.PROBE`, no HSPICE `.OPTION`s.
- Top-level testbenches end with a `.control` block (`run`, `write <name>.raw`, `quit`), and are run as
  `ngspice -o <name>.log <name>.sp < /dev/null` (not `-b`: it runs the analysis twice and `.meas` does not
  work with `-r`). Outputs: `<name>.raw` (waveforms) and `<name>.log` (`.meas` results).
- `src/spice_io.py` reads both. ngspice prints failed `.meas` first, so never rely on the log order
  (`meas_until_failed` sorts by name).
- `test_coarse_delay.sp` needs `.OPTION minbreak=1e-15` (coincident breakpoints abort the run).
- Timing characterizations need a maximum step (`.TRAN 1p stop 0 1p`): with only `.TRAN 10n` the steps around
  the edges are ~50 ps and the `.meas` are interpolated (errors of ~10 ps).
- Thread count goes in the generated `.spiceinit` (`NGSPICE_THREADS`), not on the command line. Any `make` of
  that PDK rewrites `.spiceinit` with its own `NGSPICE_THREADS` (default 8), also while other runs are starting: run
  every `make` of a PDK with the same `NGSPICE_THREADS` while an ISF batch is going (BSIM4 models use OpenMP threads). With parallel
  runs (`ISF_JOBS`) use `NGSPICE_THREADS=1`: jobs x threads above the core count slows everything down a lot.

## Delay models (create_sim_*.py)

- All generated delays are transport delays (`OUT <= #d IN`). A blocking `OUT = #d IN` or `#d; OUT = IN` drops
  the events during the wait: glitches disappear or OUT gets stuck at the wrong level.

## DCO phase noise (ISF)

ngspice has no oscillator phase-noise analysis and no device noise in transient. `test_dco_noise` uses the
Hajimiri-Lee ISF method: `src/create_isf.py` (writes the runs), `src/isf_phase_noise.py` (analysis),
`src/spice_netlist.py` (flattens the netlist to the transistor wrappers). Knobs: `ISF_NPHASE`, `ISF_NPER`,
`ISF_DQ`, `ISF_TWARM`, `ISF_JOBS`. The reference run injects zero current on purpose (the pulse breakpoints
alone shift the edges ~80 fs). `src/dco_shape.ipynb` reads `sim/outputs/<PDK>/test_dco_noise.csv`.
- The flicker part uses the tabulated `.noise` spectra per device (log-log in frequency). Do not go back to one
  power law `K/f^ef` fitted at 1 kHz with a common exponent: NMOS (~1.3) and PMOS (~1.15) differ, and that
  overestimated L by ~6 dB at 1 MHz.
- Reference: `make test_dco_spectre` runs Spectre autonomous PSS + pnoise on the same netlist/codes/models
  (`src/spectre_dco_pnoise.py`, native only, ~10 min). Agreement with the ISF on ics55: within 1 dB from
  1 kHz to 100 MHz, same dominant contributor (`mid/inv_0`). Spectre reads the HSPICE-format PDK libraries
  in `simulator lang=spice` mode; `GND` must become `0`.
- Spectre on this machine is MMSIM 13.1 (`source 616cad`). It needs a local license server (`lmgrd`) and old
  `libreadline.so.5`/`libhistory.so.5`/`libncurses.so.5`: a directory with symlinks to the system `.so.8`/`.so.6`
  works, e.g. `make test_dco_spectre SPECTRE="source /usr/local/bin/616cad >/dev/null; LD_LIBRARY_PATH=<compat dir> spectre"`.

## Make gotchas

- `ROOT_DIR` must be defined by the Makefile that includes `settings.mk` (`syn/Makefile`, `sim/Makefile`).
- `models.inc` and `.spiceinit` depend on `settings.mk` and `lib/<PDK>.mk` but are only replaced when their content changes,
  so editing `settings.mk` does not re-run the simulations. `.spiceinit` is an order-only prerequisite
  (`| $(SIM_OUT)/.spiceinit`): changing `NGSPICE_THREADS` does not re-run the characterizations either. Editing `syn/Makefile` does re-synthesize
  everything (the netlists depend on it).
- Recipes run with `bash -o pipefail`, so a tool failing behind `| tee` fails the target.
- Long runs: the full transistor-level `test_pll` takes ~27 min per 200 ns of simulated time in ngspice.

- The netlists are copied to `sim/outputs` only when their content changes (`cmp -s || cp`), so re-generating an
  identical netlist (e.g. after editing `syn/tcl/netlist.tcl`) does not re-run the characterizations.
- `.SECONDARY:` (no prerequisites) makes every target secondary: deleting an intermediate file (e.g.
  `pll_target.vh`) does not re-make it nor its dependents. Re-make it explicitly (`make pll_target`).
- `make report` depends on `pll_target.vh`, which depends on `test_dco_noise.csv` when it exists, so editing
  `create_isf.py`/`isf_phase_noise.py` makes a report re-run the ISF (~1 h). `make -n` misreports the
  characterizations as stale (models.inc): use `make -n -d ... | grep newer` to see the real reasons.

## Known issues

- `test_pll_rcx` needs Calibre extraction outputs.
- The `view_*` targets use `WAVEVIEW` (default `gaw`) for the ngspice rawfiles.
