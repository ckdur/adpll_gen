# CLAUDE.md

Guidance for Claude Code (and humans) working in this repository.

## What this is

An all-digital PLL (ADPLL) generator. The PLL is written in Verilog (`src/`) on top of a small set of
technology cells (`PLL_CELL_*`). The flow synthesizes it with yosys, turns the netlists into SPICE with
openroad, characterizes the analog blocks (delay cells, injection, symmetric mux, DCO) in ngspice, and
converts those results into Verilog delay models for fast digital simulations of the whole PLL.

## Layout

- `settings.mk`: shared by `sim/` and `syn/`. PDK selection, sources, tools (native or docker), per-PDK rules.
- `lib/<PDK>_settings.tcl`: liberty/LEF/CDL/SPICE paths of each PDK (read by the tcl scripts).
- ics55 has two standard cell libraries, selected with `SCL` (exported as `STD_CELL_LIBRARY`, which the
  LibreLane configs of the PDK read): `ics55_LLSC_H7CR` (7-track, default) and `ICsprout55_9TSVT_basic`
  (private 9-track, cell map `src/pll_cells_ICsprout55_9TSVT_basic.v`). Its cells have well pins `VNW`/`VPW`,
  tied to VDD/VSS by global connections (`SCL_POWER_PINS`/`SCL_GROUND_PINS`, `syn/tcl/netlist.tcl`).
- `src/`: RTL, testbenches (`*_tb.v`, `test_*.v`, `test_*.sp`) and the Python post-processing.
  - `pll_cells_<PDK>.v`: maps `PLL_CELL_*` to the standard cells of the PDK. The `` `ifdef YOSYS `` section
    declares those standard cells as blackboxes for synthesis.
- `syn/`: `Makefile`, `tcl/` (yosys, openroad, sta scripts), `escape_names.py`, `spice_ports.py`.
- `sim/`: `Makefile` and `tests.mk` (all the simulation targets).
- Outputs are per technology (`TECH`): `syn/outputs/<PDK>/` and `sim/outputs/<PDK>/` (`SYN_OUT`, `SIM_OUT`, also
  `pnr/` and `signoff/`), or `<PDK>-<SCL>` when the library is not the default one.

## Commands

```sh
# PDK is ics55 or ihp-sg13g2 (the default is set in settings.mk)
make PDK=ics55                                 # whole flow: syn all -> pnr all -> signoff (gds, KLayout DRC and LVS)
make PDK=ics55 SCL=ICsprout55_9TSVT_basic      # the same with the private 9-track library
make -C syn PDK=ics55 TOP=FINE_DELAY all gen   # synthesize + powered SPICE netlist
make -C sim PDK=ics55 test_fine_delay          # ngspice delay characterization (also mid/coarse)
make -C sim PDK=ics55 test_pll_injection test_sym_delay
make -C sim PDK=ics55 test_dco_noise           # DCO phase noise (ISF method, ~1h on 10 cores)
make -C sim PDK=ics55 test_pll_digital         # iverilog, uses the models made from the ngspice results
make -C sim PDK=ics55 clean                    # only this PDK; clean_all removes every PDK
```

Simulations depend on their netlists, so a `sim` target synthesizes what it needs (`make -C syn TOP=...`).

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
- The dynamic loads (`PLL_CELL_NAND3X*`) need `A0` on the NMOS next to VSS, or the fine/mid delays
  decrease with the code. Check the stack order in the CDL when mapping a new library (H7R: `A`, 9T: `C`).
- `PLL_CELL_BUFFX0` (testbench loads) is defined per PDK in the generated `models.inc`, together with the
  model `.LIB` and the standard-cell SPICE include.

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
- Thread count goes in the generated `.spiceinit` (`NGSPICE_THREADS`), not on the command line.

## DCO phase noise (ISF)

ngspice has no oscillator phase-noise analysis and no device noise in transient. `test_dco_noise` uses the
Hajimiri-Lee ISF method: `src/create_isf.py` (writes the runs), `src/isf_phase_noise.py` (analysis),
`src/spice_netlist.py` (flattens the netlist to the transistor wrappers). Knobs: `ISF_NPHASE`, `ISF_NPER`,
`ISF_DQ`, `ISF_TWARM`, `ISF_JOBS`. The reference run injects zero current on purpose (the pulse breakpoints
alone shift the edges ~80 fs). `src/dco_shape.ipynb` reads `sim/outputs/<PDK>/test_dco_noise.csv`.

## Make gotchas

- `ROOT_DIR` must be defined by the Makefile that includes `settings.mk` (`syn/Makefile`, `sim/Makefile`).
- `models.inc` and `.spiceinit` depend on `settings.mk` but are only replaced when their content changes,
  so editing `settings.mk` does not re-run the simulations. Editing `syn/Makefile` does re-synthesize
  everything (the netlists depend on it).
- Recipes run in bash with `pipefail` (through `SHELLOPTS`; `.SHELLFLAGS` does not exist in make 3.81, the
  macOS one), so a tool failing behind `| tee` fails the target.
- Long runs: the full transistor-level `test_pll` takes ~27 min per 200 ns of simulated time in ngspice.

## Known issues

- `test_pll_rcx` needs Calibre extraction outputs.
- The `view_*` targets use `WAVEVIEW` (default `gaw`) for the ngspice rawfiles.
