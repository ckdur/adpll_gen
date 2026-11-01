#!python

# Models of the ADPLL (src/pll.v) used by the design notebook (src/pll_design.ipynb)
#
# Three levels, all fed by the same characterization results (sim/outputs/<PDK>):
#
# 1. Characterization: the ngspice results of the delay cells, the symmetric mux/SS-BBPD and the
#    injection window (load_characterization), and the DCO phase noise of the ISF analysis.
# 2. Linear model (LinearModel): z-domain model of the loop sampled at f_REF, with the bang-bang
#    phase detector linearized with its describing function (K_BB = sqrt(2/pi)/sigma, solved
#    self-consistently with the jitter). Gives the bandwidth, the margins, the noise transfer
#    functions and the phase noise of every contributor, without and with injection.
# 3. Behavioral model (simulate): time-domain, one step per DCO period, with the same integer
#    arithmetic of the RTL (loop filter, filter-to-fine-code mapping, 1st order DSM at f_DCO/2),
#    a sign() phase detector and the injection (edge replacement every REF period).
#    It contains every nonlinearity (bang-bang limit cycles, DSM, saturation), and with the noise
#    sources disabled it reproduces the iverilog simulation of the RTL (test_pll_digital).
#
# Units: seconds and Hz. "Timing error" x is the delay of an OUT edge with respect to the ideal
# edge (n * T_REF / N). Phase noise: L(f) = (2 pi f0)^2 S_x(f) / 2, with S_x one-sided.

import os, re
from dataclasses import dataclass, field, replace
import numpy as np

_trapz = getattr(np, "trapezoid", None) or np.trapz  # numpy < 2 has only trapz

try:
    from spice_io import read_meas, meas_until_failed
except ImportError:  # When imported from the notebook (cwd = src)
    from .spice_io import read_meas, meas_until_failed


###############################################################################
# 1. Characterization results
###############################################################################

@dataclass
class Characterization:
    fine: np.ndarray            # Delay of FINE_DELAY for code 0..31 (s)
    mid: np.ndarray             # Delay of MID_DELAY for code 0..15 (s)
    coarse: np.ndarray          # Delay of COARSE_DELAY for code 0..15 (s)
    tmux: float                 # FINE_OUT -> OUT through the symmetric mux (s)
    tssbbpd: float              # FINE_OUT -> SS_BBPD (s)
    tedge: float = None         # REF fall -> INJ_EDGE fall (s)
    twin_start: float = None    # REF fall -> INJ_WIN rise (s)
    twin_len: float = None      # INJ_WIN width (s)
    dco_pn: dict = None         # ISF result: freq, L, L_white, L_flicker (dBc/Hz)
    dco_pn_f0: float = None     # Oscillation frequency of the ISF simulation (Hz)
    dco_pn_spectre: dict = None # Spectre PSS+pnoise reference (test_dco_spectre): freq, L (dBc/Hz)
    dco_pn_spectre_f0: float = None
    source: str = ""

    def half_period(self, coarse, mid, fine):
        """Half period of the ring for the given codes (number of ones of each thermometer)."""
        return self.coarse[coarse] + self.mid[mid] + np.interp(fine, np.arange(len(self.fine)), self.fine) + self.tmux

    def period(self, coarse, mid, fine):
        return 2 * self.half_period(coarse, mid, fine)

    @property
    def fine_lsb(self):
        """Average change of the DCO period per fine code (s/code)."""
        return 2 * (self.fine[-1] - self.fine[0]) / (len(self.fine) - 1)


def load_characterization(sim_out):
    """Reads the ngspice logs of sim/outputs/<PDK>. Missing optional results are left as None."""
    p = lambda f: os.path.join(sim_out, f)
    fine = np.array(meas_until_failed(p("test_fine_delay.log"), "tdel"))
    mid = np.array(meas_until_failed(p("test_mid_delay.log"), "tdel"))
    coarse = np.array(meas_until_failed(p("test_coarse_delay.log"), "tdel"))
    sym = read_meas(p("test_sym_delay.log"))
    ch = Characterization(fine=fine, mid=mid, coarse=coarse,
                          tmux=sym["tmux"], tssbbpd=sym["tssbbpd"], source=os.path.abspath(sim_out))
    if os.path.exists(p("test_pll_injection.log")):
        inj = read_meas(p("test_pll_injection.log"))
        ch.tedge, ch.twin_start, ch.twin_len = inj.get("tedge_start"), inj.get("twin_start"), inj.get("twin_len")
    if os.path.exists(p("test_dco_noise.csv")):
        d = np.genfromtxt(p("test_dco_noise.csv"), delimiter=",", names=True)
        ch.dco_pn = dict(freq=d["freq"], L=d["L_dBc_Hz"], L_white=d["L_white_dBc_Hz"], L_flicker=d["L_flicker_dBc_Hz"])
        if os.path.exists(p("test_dco_noise.txt")):
            m = re.search(r"f0\s*=\s*([\d.eE+-]+)\s*GHz", open(p("test_dco_noise.txt")).read())
            ch.dco_pn_f0 = float(m.group(1)) * 1e9 if m else None
    if os.path.exists(p("test_dco_spectre.csv")):
        d = np.genfromtxt(p("test_dco_spectre.csv"), delimiter=",", names=True)
        ch.dco_pn_spectre = dict(freq=d["freq"], L=d["L_dBc_Hz"])
        if os.path.exists(p("test_dco_spectre.txt")):
            m = re.search(r"f0\s*=\s*([\d.eE+-]+)\s*GHz", open(p("test_dco_spectre.txt")).read())
            ch.dco_pn_spectre_f0 = float(m.group(1)) * 1e9 if m else None
    return ch


###############################################################################
# Noise sources
###############################################################################

@dataclass
class DCONoise:
    """Free-running DCO phase noise L(f) = a/f^2 + b/f^(2+ef) (linear units, 1/Hz)."""
    a: float = 0.0              # White FM (thermal): L(f) = a / f^2
    b: float = 0.0              # Flicker FM: L(f) = b / f^(2+ef)
    ef: float = 1.0             # Exponent of the flicker noise (1: the usual 1/f^3 region)

    @classmethod
    def from_dBc(cls, L_white_at, f_white, corner=0.0):
        """From L at f_white (dBc/Hz, of the 1/f^2 part) and the 1/f^3 corner (Hz)."""
        a = 10 ** (L_white_at / 10) * f_white ** 2
        return cls(a=a, b=a * corner)

    @classmethod
    def from_isf(cls, dco_pn, fmin=1e4, fmax=1e8):
        """Fits the thermal (-20 dB/dec) and the flicker part (slope from the data) of the ISF result."""
        f = dco_pn["freq"]
        m = (f >= fmin) & (f <= fmax)
        a = np.exp(np.mean(np.log(10 ** (dco_pn["L_white"][m] / 10) * f[m] ** 2)))
        lf = dco_pn["L_flicker"][m] / 10 * np.log(10)          # ln L_flicker
        ok = np.isfinite(lf) & (dco_pn["L_flicker"][m] > -290)
        if ok.sum() < 2:
            return cls(a=a)
        slope, icpt = np.polyfit(np.log(f[m][ok]), lf[ok], 1)  # ln L = icpt + slope ln f
        return cls(a=a, b=float(np.exp(icpt)), ef=float(-slope - 2))

    @property
    def corner(self):
        """Frequency where the flicker and the white parts are equal (Hz)."""
        return (self.b / self.a) ** (1 / self.ef) if self.a > 0 and self.b > 0 else 0.0

    def L(self, f):
        return self.a / f ** 2 + self.b / f ** (2 + self.ef)

    def scaled(self, f_from, f_to):
        """Same delay cells at another frequency: c = sigma_T^2/T is kept, so L scales with f0^2."""
        k = (f_to / f_from) ** 2
        return DCONoise(a=self.a * k, b=self.b * k, ef=self.ef)

    def period_jitter(self, f0):
        """rms period jitter of the white part (s): sigma_T^2 = a / f0^3."""
        return np.sqrt(self.a / f0 ** 3)


@dataclass
class RefNoise:
    """Phase noise of the reference at the input of the PLL: floor + flicker (dBc/Hz at f_REF)."""
    floor_dBc: float = -150.0   # White phase noise floor (crystal + input buffer)
    L_1k_dBc: float = -200.0    # Close-in (1/f^3) phase noise at 1 kHz offset

    def L(self, f):
        return 10 ** (self.floor_dBc / 10) + 10 ** (self.L_1k_dBc / 10) * (1e3 / f) ** 3


def colored_sequence(n, fs, psd, rng):
    """Real Gaussian sequence of n samples at fs with one-sided PSD psd(f) (units^2/Hz)."""
    nfft = 1 << int(np.ceil(np.log2(n)))
    f = np.fft.rfftfreq(nfft, 1 / fs)
    s = np.zeros_like(f)
    s[1:] = psd(f[1:])
    # Each bin: variance psd*df split in real/imag parts
    amp = np.sqrt(s * fs * nfft / 4)
    spec = amp * (rng.standard_normal(len(f)) + 1j * rng.standard_normal(len(f)))
    spec[0] = 0
    spec[-1] = spec[-1].real * np.sqrt(2)
    return np.fft.irfft(spec, nfft)[:n]


###############################################################################
# PLL configuration (the inputs and parameters of pll.v)
###############################################################################

@dataclass
class PLLConfig:
    f_ref: float = 100e6
    N: int = 10                 # f_OUT = N * f_REF (the freq. lock targets FCW = N - 2)
    KP: int = 3967
    KI: int = 257
    filter_bits: int = 16
    fine_bits: int = 5          # $clog2(FINE_NDELS)
    dsm: bool = True            # IS_DSM
    dsm_div: int = 2            # DSM clock = f_OUT / DSM_DIV
    fine_map: str = "linear"    # Filter -> fine code: "linear" (code = OUT/2^11, pll_logic.v), or "legacy"
                                # (FCWI = {OUT[15:12],0}, FCWF = OUT[11:0], the mapping before the fix)
    inj: bool = False           # INJ_EN
    sigma_bbpd: float = 0.3e-12 # rms input-referred noise of the SS-BBPD (s)

    @property
    def f_out(self):
        return self.N * self.f_ref

    @property
    def code_lsb(self):
        """Filter LSBs per fine code, as seen by the loop in lock (local slope of the mapping).
        "linear": 2^11. "legacy": the DSM fraction has 12 bits, so 2^12 (plus a jump of 1 code every 2^12)."""
        return 2 ** (self.filter_bits - self.fine_bits + (1 if self.fine_map == "legacy" else 0))


def fine_code_mean(cfg, filt):
    """Average fine code (time average of the DSM output) for a filter output value."""
    filt = np.asarray(filt, dtype=float)
    fb = cfg.filter_bits - cfg.fine_bits + 1          # 12 fractional bits of the DSM
    if not cfg.dsm:
        return np.floor(filt / 2 ** (cfg.filter_bits - cfg.fine_bits))
    if cfg.fine_map == "legacy":
        q = np.floor(filt / 2 ** fb)
        return 2 * q + (filt - q * 2 ** fb) / 2 ** fb
    return filt / 2 ** (fb - 1)


###############################################################################
# 2. Linear model
###############################################################################

@dataclass
class LinearModel:
    """Linearized loop: the phase detector samples at f_REF, the DCO is continuous (hybrid model).

    Discrete loop (one BBPD decision per REF period), T = 1/f_REF, z = exp(j 2 pi f T):
        e[k]   timing error at the BBPD (DCO edge - injected edge)
        b[k]   = K_BB e[k] + q[k]   sign() detector: K_BB = sqrt(2/pi)/sigma_e, var(q) = 1 - 2/pi
        c[k]   = -H(z) b[k],  H(z) = KP + KI/(1 - z^-1)        (filter LSB)
        A      = N Kt: timing change of the DCO in one REF period per filter LSB (s/LSB)

    Without injection the DCO integrates the control:   G(z) = K_BB A H(z) z^-1/(1 - z^-1)
    The output (continuous) sees the control through a ZOH and the integrator of the DCO:
        G_c(f) = G(z) sinc^2(f T)  (= G at low frequency, decays above f_REF/2)
        REF -> out: G_c/(1+G)   DCO -> out: 1 - G_c/(1+G)   q -> out: -G_c/(K_BB (1+G))

    With injection (edge replacement every REF period, beta = 1, as an MDLL) the BBPD measures the
    error accumulated in one period, so the loop controls the frequency:  G_i(z) = K_BB A H(z) z^-1
        Z(f) = (1 - e^-sT)/(sT)                 (the injected edge is held for the N output edges)
        R(f) = (1 - e^-sT (1 + sT))/(sT)^2      (ramp of the control, reset by each injection)
        REF -> out: Z - A K_BB H R (z^-1 - 1)/(1+G_i)
        DCO -> out: (1 - Z) - A K_BB H R (1 - z^-1)/(1+G_i)
        q   -> out: -A H R/(1+G_i)

    The sampling (aliasing) of the DCO noise is taken into account for sigma_e (the sequence of
    errors at the BBPD), not for the output spectra.

    The describing function only covers random errors. The deterministic ones (limit cycle of the
    bang-bang loop, tones of the DeltaSigma) are measured with a noise-free run of the behavioral
    model (calibrate_deterministic) and added in power to sigma_e and to the output jitter.
    """
    cfg: PLLConfig
    Kt: float                   # DCO period change per filter LSB (s/LSB)
    dco: DCONoise
    ref: RefNoise
    K_bb: float = None          # Solved by solve_kbb() if None
    fine_lsb: float = 0.0       # DCO period per fine code (s), for the DeltaSigma quantization noise
    sigma_det_e: float = 0.0    # Deterministic rms error at the detector (s)
    sigma_det_out: float = 0.0  # Deterministic rms timing error at the output (s)

    @classmethod
    def from_characterization(cls, cfg, ch, dco=None, ref=None):
        Kt = ch.fine_lsb / cfg.code_lsb
        if dco is None:
            dco = DCONoise.from_isf(ch.dco_pn) if ch.dco_pn is not None else DCONoise()
        return cls(cfg=cfg, Kt=Kt, dco=dco, ref=ref or RefNoise(), fine_lsb=ch.fine_lsb)

    def calibrate_deterministic(self, ch, coarse, mid, n_ref=1 << 13):
        """Runs the behavioral model without noise and keeps its rms errors (detector and output)."""
        r = simulate(self.cfg, ch, coarse, mid, n_ref=n_ref, noise=False)
        k = len(r.e) // 4
        self.sigma_det_e = float(np.std(r.e[k:]))
        self.sigma_det_out = float(np.std(r.x[k * self.cfg.N:]))
        return self.sigma_det_e, self.sigma_det_out

    @property
    def A(self):
        return self.cfg.N * self.Kt

    def _zi(self, f):
        return np.exp(-2j * np.pi * np.asarray(f, dtype=float) / self.cfg.f_ref)

    def _sT(self, f):
        return 2j * np.pi * np.asarray(f, dtype=float) / self.cfg.f_ref

    def dlf(self, f):
        return self.cfg.KP + self.cfg.KI / (1 - self._zi(f))

    def open_loop(self, f, K_bb=None):
        """Discrete loop gain G(z) (or G_i(z) with injection)."""
        K = self.K_bb if K_bb is None else K_bb
        zi = self._zi(f)
        if self.cfg.inj:
            return K * self.A * self.dlf(f) * zi
        return K * self.A * self.dlf(f) * zi / (1 - zi)

    def _Z(self, f):
        sT = self._sT(f)
        return np.where(np.abs(sT) > 1e-9, (1 - np.exp(-sT)) / np.where(sT == 0, 1, sT), 1.0)

    def _R(self, f):
        sT = self._sT(f)
        safe = np.where(np.abs(sT) > 1e-4, sT, 1e-4)
        return np.where(np.abs(sT) > 1e-4, (1 - np.exp(-safe) * (1 + safe)) / safe ** 2, 0.5)

    # Noise transfer functions: output timing / source timing (q: output timing per unit of q)
    def ntf_ref(self, f):
        G = self.open_loop(f)
        if self.cfg.inj:
            zi = self._zi(f)
            return self._Z(f) - self.A * self.K_bb * self.dlf(f) * self._R(f) * (zi - 1) / (1 + G)
        return G * np.sinc(np.asarray(f) / self.cfg.f_ref) ** 2 / (1 + G)

    def ntf_dco(self, f):
        G = self.open_loop(f)
        if self.cfg.inj:
            zi = self._zi(f)
            return (1 - self._Z(f)) - self.A * self.K_bb * self.dlf(f) * self._R(f) * (1 - zi) / (1 + G)
        return 1 - G * np.sinc(np.asarray(f) / self.cfg.f_ref) ** 2 / (1 + G)

    def ntf_bbpd(self, f):
        G = self.open_loop(f)
        if self.cfg.inj:
            return -self.A * self.dlf(f) * self._R(f) / (1 + G)
        return -G * np.sinc(np.asarray(f) / self.cfg.f_ref) ** 2 / (self.K_bb * (1 + G))

    # Spectra of the sources, as one-sided timing PSDs (s^2/Hz)
    def sx_dco(self, f):
        return 2 * self.dco.L(f) / (2 * np.pi * self.cfg.f_out) ** 2

    def _fold(self, f):
        """Frequency folded into [0, f_REF/2] (the reference and q are sequences at f_REF)."""
        fr = self.cfg.f_ref
        g = np.mod(np.asarray(f, dtype=float), fr)
        return np.maximum(np.minimum(g, fr - g), fr * 1e-9)

    def sx_ref(self, f):
        return 2 * self.ref.L(self._fold(f)) / (2 * np.pi * self.cfg.f_ref) ** 2

    def sx_q(self, f):
        # Quantization noise of the sign() detector: white, variance 1 - 2/pi in [0, f_REF/2]
        return np.full_like(np.asarray(f, dtype=float), 2 * (1 - 2 / np.pi) / self.cfg.f_ref)

    def sx_dsm(self, f):
        """Quantization of the fine code by the 1st-order DeltaSigma (clocked at f_OUT/DSM_DIV).
        The code error (uniform, variance 1/12, shaped by 1 - z^-1) is integrated by the DCO, which gives
        a white timing error of DSM_DIV * fine_lsb * eps, held for DSM_DIV periods."""
        f = np.asarray(f, dtype=float)
        if not self.cfg.dsm:
            return np.zeros_like(f)
        fd = self.cfg.f_out / self.cfg.dsm_div
        v = (self.cfg.dsm_div * self.fine_lsb) ** 2 / 12 * 2 / fd
        return np.where(f < fd / 2, v * np.sinc(f / fd) ** 2, 0.0)

    def contributions(self, f):
        """Output timing PSDs (s^2/Hz) of each source."""
        ndco = np.abs(self.ntf_dco(f)) ** 2
        return dict(
            REF=self.sx_ref(f) * np.abs(self.ntf_ref(f)) ** 2,
            DCO=self.sx_dco(f) * ndco,
            BBPD=self.sx_q(f) * np.abs(self.ntf_bbpd(f)) ** 2,
            DSM=self.sx_dsm(f) * ndco,
        )

    def L_out(self, f):
        """Phase noise L(f) (dBc/Hz) of each contribution and the total."""
        c = self.contributions(f)
        tot = sum(c.values())
        k = 0.5 * (2 * np.pi * self.cfg.f_out) ** 2
        return {n: 10 * np.log10(k * v + 1e-300) for n, v in dict(c, Total=tot).items()}

    def L_free(self, f):
        """Free-running DCO."""
        return 10 * np.log10(self.dco.L(f))

    def sigma_e(self, K_bb):
        """rms of the timing error at the BBPD input (random part), for a given K_BB."""
        fr = self.cfg.f_ref
        # Sequence noises (REF, q) in [0, f_REF/2]; the DCO folds, so integrate it further
        f1 = np.linspace(fr * 1e-5, fr / 2, 8192)
        f2 = np.geomspace(fr * 1e-5, fr * 64, 1 << 16)
        def E(f):
            G = self.open_loop(f, K_bb)
            zi = self._zi(f)
            if self.cfg.inj:
                return (zi - 1) / (1 + G), (1 - zi) / (1 + G), -self.A * self.dlf(f) * zi / (1 + G)
            return -1 / (1 + G), 1 / (1 + G), -(G / K_bb) / (1 + G)
        er, _, eq = E(f1)
        _, ed, _ = E(f2)
        v = _trapz(self.sx_ref(f1) * np.abs(er) ** 2 + self.sx_q(f1) * np.abs(eq) ** 2, f1)
        v += _trapz(self.sx_dco(f2) * np.abs(ed) ** 2, f2)
        return np.sqrt(v + self.cfg.sigma_bbpd ** 2 + self.sigma_det_e ** 2)

    def solve_kbb(self, iters=200):
        """K_BB = sqrt(2/pi)/sigma_e, with sigma_e depending on K_BB: fixed point iteration."""
        K = np.sqrt(2 / np.pi) / 1e-12
        for _ in range(iters):
            Kn = np.sqrt(2 / np.pi) / self.sigma_e(K)
            if abs(Kn - K) < 1e-6 * K:
                break
            K = np.sqrt(K * Kn)  # Geometric relaxation
        self.K_bb = K
        return K

    def loop_metrics(self):
        """Loop gain crossover and phase margin (discrete loop), jitter transfer bandwidth and peaking."""
        fr = self.cfg.f_ref
        f = np.geomspace(fr * 1e-6, fr / 2, 6000)
        G = self.open_loop(f)
        i = np.argmax(np.abs(G) < 1)
        fu = f[i] if np.abs(G[i]) < 1 else np.nan
        pm = 180 + np.degrees(np.angle(G[i])) if np.isfinite(fu) else np.nan
        fh = np.geomspace(fr * 1e-6, fr, 6000)
        H = np.abs(self.ntf_ref(fh))
        j = np.argmax(H < 1 / np.sqrt(2))
        f3 = fh[j] if H[j] < 1 / np.sqrt(2) else np.nan
        return dict(K_bb=self.K_bb, sigma_e=np.sqrt(2 / np.pi) / self.K_bb, f_unity=fu, phase_margin=pm,
                    f_3dB=f3, peaking_dB=20 * np.log10(H.max()),
                    beta_p=self.A * self.cfg.KP,       # Proportional step per REF period (s)
                    beta_i=self.A * self.cfg.KI,       # Integral step per REF period^2 (s)
                    stability_factor=self.cfg.KI / self.cfg.KP)

    def jitter(self, f1, f2, n=4000):
        """Integrated rms jitter (s) of each contribution between f1 and f2. "Deterministic" is the
        calibrated limit cycle/DeltaSigma part (its spectrum is not modeled: it is not band-limited)."""
        f = np.geomspace(f1, f2, n)
        c = self.contributions(f)
        j = {k: np.sqrt(_trapz(v, f)) for k, v in c.items()}
        # The noise-free calibration already contains the DeltaSigma quantization: do not count it twice
        rand = [v for k, v in c.items() if not (k == "DSM" and self.sigma_det_out > 0)]
        j["Random"] = np.sqrt(_trapz(sum(rand), f))
        j["Deterministic"] = self.sigma_det_out
        # The quantization "noise" of the describing function and the limit cycle measured without noise
        # are the same error of the sign() detector: keep the larger one (instead of adding both)
        j["Total"] = np.sqrt(j["REF"] ** 2 + j["DCO"] ** 2 + (0 if self.sigma_det_out else j["DSM"] ** 2)
                             + max(j["BBPD"], self.sigma_det_out) ** 2)
        return j


###############################################################################
# 3. Behavioral time-domain model
###############################################################################

@dataclass
class SimResult:
    x: np.ndarray               # Timing error of every OUT edge (one per DCO period) (s)
    period: np.ndarray          # DCO periods (s)
    filt: np.ndarray            # Loop filter output per REF period
    bbpd: np.ndarray            # BBPD decision per REF period (+1: DCO early -> slow down)
    e: np.ndarray               # Timing error seen by the BBPD per REF period (s)
    cfg: PLLConfig = None

    @property
    def f0(self):
        return self.cfg.f_out


def simulate(cfg, ch, coarse, mid, n_ref=1 << 14, filt0=None, dco=None, ref=None,
             noise=True, seed=1, phase_offset=0.0, f_offset=0.0, pd_early_range=None):
    """Cycle-based simulation of the locked loop (coarse and mid fixed, as after the freq. lock).

    phase_offset: static offset of the BBPD (s), f_offset: error of the reference frequency (relative).
    pd_early_range: the detector says "DCO early" for errors in (-pd_early_range, 0) and "late" for
    the rest of the DCO period (the error wraps every period, which matters when the phase slips).
    T_OUT/2 is a symmetric detector; None is an ideal sign() without wrapping.
    Returns the timing error of every OUT edge, and the loop variables per REF period.
    """
    rng = np.random.default_rng(seed)
    N = cfg.N
    T_ref = 1 / (cfg.f_ref * (1 + f_offset))
    T_ideal = 1 / cfg.f_ref / N            # Ideal output period (x is measured against it)
    n_dco = n_ref * N

    # Noise sequences
    if noise and dco is not None and (dco.a > 0 or dco.b > 0):
        f0 = cfg.f_out
        dT = colored_sequence(n_dco, f0, lambda f: 2 * (dco.a + dco.b / f ** dco.ef) / f0 ** 4, rng)
    else:
        dT = np.zeros(n_dco)
    if noise and ref is not None:
        xr = colored_sequence(n_ref, cfg.f_ref, lambda f: 2 * ref.L(f) / (2 * np.pi * cfg.f_ref) ** 2, rng)
    else:
        xr = np.zeros(n_ref)
    nb = rng.standard_normal(n_ref) * cfg.sigma_bbpd if noise else np.zeros(n_ref)

    # Delay tables (half period without the fine part, and fine delay per code)
    base = 2 * (ch.coarse[coarse] + ch.mid[mid] + ch.tmux)
    fine_T = 2 * ch.fine
    fmax = len(ch.fine) - 1

    fb = cfg.filter_bits - cfg.fine_bits + 1       # DSM fractional bits (12)
    fmask = (1 << fb) - 1
    top = (1 << cfg.filter_bits) - 1
    if filt0 is None:
        # Start at the filter value that makes the mean period ideal
        codes = np.linspace(0, fmax, 1024)
        Tm = base + np.interp(codes, np.arange(fmax + 1), fine_T)
        target = np.interp(T_ideal, Tm, codes)
        cand = np.arange(0, top + 1, 16)
        filt0 = int(cand[np.argmin(np.abs(fine_code_mean(cfg, cand) - target))])
    integ = int(filt0)

    x = np.zeros(n_dco)
    per = np.zeros(n_dco)
    filt_log = np.zeros(n_ref, dtype=np.int64)
    b_log = np.zeros(n_ref, dtype=np.int8)
    e_log = np.zeros(n_ref)

    xt = 0.0            # Timing error of the current edge
    acc = 0             # DSM accumulator
    fcwi = fcwf = 0     # Registered DSM inputs
    code = 0
    filt = integ
    n = 0
    # The DSM clock runs at f_OUT/dsm_div: count DCO periods
    for k in range(n_ref):
        # N DCO periods in this REF period, with the filter output computed at the previous REF edge
        for i in range(N):
            if n % cfg.dsm_div == 0:
                if cfg.dsm:
                    s = fcwf + acc
                    carry = s >> fb
                    acc = s & fmask
                    code = min(fcwi + carry, fmax)
                    if cfg.fine_map == "legacy":
                        fcwi = (filt >> fb) << 1
                        fcwf = filt & fmask
                    else:
                        fcwi = filt >> (fb - 1)
                        fcwf = (filt & ((1 << (fb - 1)) - 1)) << 1
                else:
                    code = filt >> (cfg.filter_bits - cfg.fine_bits)
            T = base + fine_T[code] + dT[n]
            per[n] = T
            xt += T - T_ideal
            x[n] = xt
            n += 1
        # REF edge k: the reference timing error is the deviation of the REF edge from the ideal grid
        xref = xr[k] + (k + 1) * (T_ref - N * T_ideal)
        e = xt - xref - phase_offset
        en = e + nb[k]
        if pd_early_range is not None:
            en = (en + pd_early_range) % T_ideal - pd_early_range
        b = 1 if en < 0 else -1                   # DCO early (edge before REF): slow down
        e_log[k] = e
        b_log[k] = b
        # Loop filter (pll_digital_loop_filter): saturating integrator, proportional output
        if b > 0:
            filt = min(integ + cfg.KP, top)
            integ = min(integ + cfg.KI, top)
        else:
            filt = max(integ - cfg.KP, 0)
            integ = max(integ - cfg.KI, 0)
        filt_log[k] = filt
        if cfg.inj:
            # Edge replacement: the next edge starts from the reference edge
            xt = xref + phase_offset
            x[n - 1] = xt
    return SimResult(x=x, period=per, filt=filt_log, bbpd=b_log, e=e_log, cfg=cfg)


###############################################################################
# Jitter and phase noise from edge times
###############################################################################

def phase_noise_from_tie(x, f0, nperseg=None, detrend="linear"):
    """L(f) in dBc/Hz from the timing error of consecutive edges (sampled at f0), Welch average."""
    from scipy.signal import welch
    x = np.asarray(x) - np.mean(x)
    if nperseg is None:
        nperseg = min(len(x), 1 << 16)
    f, S = welch(x, fs=f0, nperseg=nperseg, window="blackmanharris", detrend=detrend, scaling="density")
    f, S = f[1:], S[1:]
    return f, 10 * np.log10(0.5 * (2 * np.pi * f0) ** 2 * S + 1e-300)


def integrated_jitter(f, L_dBc, f1, f2, f0):
    """rms absolute jitter (s) from L(f) integrated between f1 and f2: sqrt(2 int L df) / (2 pi f0)."""
    m = (f >= f1) & (f <= f2)
    return np.sqrt(2 * _trapz(10 ** (L_dBc[m] / 10), f[m])) / (2 * np.pi * f0)


def jitter_metrics(x, f0):
    """Time-domain jitter of an edge sequence: TIE, period and cycle-to-cycle (rms and peak-to-peak)."""
    x = np.asarray(x)
    tie = x - np.polyval(np.polyfit(np.arange(len(x)), x, 1), np.arange(len(x)))
    p = np.diff(x)
    c2c = np.diff(p)
    return dict(tie_rms=np.std(tie), tie_pp=np.ptp(tie), per_rms=np.std(p), per_pp=np.ptp(p),
                c2c_rms=np.std(c2c), c2c_pp=np.ptp(c2c))


def rad_rms(jitter_s, f0):
    return 2 * np.pi * f0 * jitter_s


###############################################################################
# RTL simulation (iverilog) results: the edge log of src/pll_test.v
###############################################################################

def read_edge_log(fil):
    """{kind: (times in s, values)} from test_pll[_inj]_edges.txt (see pll_test.v for the kinds)."""
    data = {}
    with open(fil) as f:
        for line in f:
            p = line.split()
            if len(p) != 3:
                continue
            data.setdefault(p[0], []).append((int(p[1]), int(p[2])))
    out = {}
    for k, v in data.items():
        a = np.array(v, dtype=np.int64)
        out[k] = (a[:, 0] * 1e-15, a[:, 1])
    return out


def analyze_rtl(fil, f_ref, N, tmux=0.0, settle=200e-9):
    """Lock time, codes, jitter and glitches of an RTL simulation, from its edge log.

    tmux: delay FINE_OUT -> OUT of the mux, to place the natural edge of the DCO at the output.
    """
    ev = read_edge_log(fil)
    r = dict(file=fil)
    tL, vL = ev.get("L", (np.array([]), np.array([])))
    t_lock = tL[vL == 1][0] if np.any(vL == 1) else None
    r["t_lock"] = t_lock
    tO, vO = ev["O"]
    pop = lambda v: bin(int(v)).count("1")
    for k, name in (("K", "coarse"), ("M", "mid")):
        if k in ev:
            r[name] = pop(ev[k][1][-1])
    if "C" in ev:
        r["filter_t"], r["filter"] = ev["C"]
    tA, vA = ev.get("A", (np.array([]), np.array([])))
    r["t_inj"] = tA[vA == 1][0] if np.any(vA == 1) else None
    if t_lock is None:
        return r
    # LOCKED comes after the frequency acquisition; with gear shifting the (slower) gains after LOCKED
    # still finish the pull-in, so the first 20 % of the record after LOCKED is skipped as well
    t0 = t_lock + max(settle, 0.2 * (tO[-1] - t_lock))
    rise = tO[(vO == 1) & (tO > t0)]
    half = np.diff(tO[tO > t_lock])
    r["half_min"], r["half_max"] = half.min(), half.max()
    r["glitches"] = int(np.sum(half < 0.6 / (2 * N * f_ref)))
    # Timing error of the rising edges with respect to the ideal grid n T_REF/N
    T0 = 1 / (N * f_ref)
    n = np.round((rise - rise[0]) / T0)
    x = rise - rise[0] - n * T0
    r["rise"], r["x"] = rise, x - np.mean(x)
    r["f_out"] = 1 / np.mean(np.diff(rise))
    # Natural edge of the DCO (FINE_OUT falls -> OUT rises tmux later) vs the edge at OUT:
    # with injection, the difference at the injected edges is the correction of each injection
    if "F" in ev:
        tF, vF = ev["F"]
        nat = tF[(vF == 0) & (tF > t0)] + tmux
        i = np.searchsorted(rise, nat)
        ok = (i > 0) & (i < len(rise))
        d1 = np.where(ok, rise[np.clip(i, 0, len(rise) - 1)] - nat, np.inf)
        d0 = np.where(ok, nat - rise[np.clip(i - 1, 0, len(rise) - 1)], np.inf)
        d = np.where(np.abs(d1) < np.abs(d0), d1, -d0)
        r["natural_minus_out"] = (nat[ok], -d[ok])
    return r


###############################################################################
# Design target for a technology (used by src/pll_target.py and the notebook)
###############################################################################
# The generator has fixed code widths (coarse 15, mid 15, fine 31) and a fixed architecture, so a new
# technology changes only the delays. From the characterization the design flow derives:
#   1. the band of output frequencies that the technology supports (tuning range with PVT margin,
#      continuity of the tuning curve, and the timing of the injection/SS-BBPD logic),
#   2. f_OUT = N f_REF inside that band, with the coarse/mid codes that the acquisition will find,
#   3. the loop gains: the smallest K_P (lowest jitter) that still pulls in from any initial fine code.

def injection_timing(sim_out, ch):
    """Times of the injection logic at the inputs of the mux, after the falling edge of REF (s).
    early/late: largest error of the natural DCO edge that the window accepts (see the notebook, sec. 3)."""
    m = read_meas(os.path.join(sim_out, "test_pll_injection.log"))
    s = read_meas(os.path.join(sim_out, "test_sym_delay.log"))
    t_inv = s.get("tlvl", 0.0) / 2
    t_open = ch.twin_start + s.get("twin_on", 0.0)
    t_edge = ch.tedge + t_inv
    t_close = ch.twin_start + ch.twin_len + s.get("twin_off", 0.0)
    t_ck = m.get("tbbpd_ck")
    return dict(t_open=t_open, t_edge=t_edge, t_close=t_close, t_ck=t_ck,
                early=t_edge - t_open, late=t_close - t_edge)


def codes_for(ch, f):
    """Coarse/mid codes that put f closest to the middle of the fine range: (coarse, mid, fraction)."""
    best = None
    nf = len(ch.fine) - 1
    for c in range(len(ch.coarse)):
        for m in range(len(ch.mid)):
            lo, hi = ch.period(c, m, 0), ch.period(c, m, nf)
            if lo <= 1 / f <= hi:
                r = (1 / f - lo) / (hi - lo)
                if best is None or abs(r - 0.5) < abs(best[2] - 0.5):
                    best = (c, m, r)
    return best


def technology_limits(ch, inj, margin_tune=0.2, margin_inj=0.15):
    """Band of f_OUT supported by a characterized technology, and the reason of each limit.
    margin_tune: relative margin from the ends of the tuning range (PVT, the acquisition needs headroom).
    margin_inj: margin of the injection/SS-BBPD timing (BBPD_CK and the end of the window before T/2)."""
    nc, nm, nf = len(ch.coarse) - 1, len(ch.mid) - 1, len(ch.fine) - 1
    f_lo_t, f_hi_t = 1 / ch.period(nc, nm, nf), 1 / ch.period(0, 0, 0)
    lim = {"tuning range": (f_lo_t, f_hi_t),
           "tuning range with PVT margin": (f_lo_t * (1 + margin_tune), f_hi_t / (1 + margin_tune))}
    # The SS-BBPD latch is captured BBPD_CK after the injected edge: it must happen before the next
    # (falling) edge of OUT, T/2 later. The window must also close before that edge
    if inj.get("t_ck"):
        lim["SS-BBPD capture before T/2"] = (0, 1 / (2 * (inj["t_ck"] - inj["t_edge"]) * (1 + margin_inj)))
    lim["window closes before T/2"] = (0, 1 / (2 * (inj["t_close"] - inj["t_edge"]) * (1 + margin_inj)))
    lo = max(v[0] for k, v in lim.items() if k != "tuning range")
    hi = min(v[1] for k, v in lim.items() if k != "tuning range")
    # Continuity of the tuning curve: the fine range must cover the largest mid step, the mid range the
    # largest coarse step (otherwise some frequencies cannot be reached)
    gaps = dict(fine_vs_mid=np.ptp(ch.fine) / np.max(np.diff(ch.mid)),
                mid_vs_coarse=np.ptp(ch.mid) / np.max(np.diff(ch.coarse)))
    return dict(f_lo=lo, f_hi=hi, limits=lim, coverage=gaps)


def target_period_code(ch, coarse, mid, f):
    """Fine code (fractional) that gives the output frequency f with the given coarse/mid codes."""
    codes = np.arange(len(ch.fine))
    return float(np.interp(1 / f, [ch.period(coarse, mid, c) for c in codes], codes))


def choose_frequency(ch, lims, f_ref, fcw_bits=8, frac_band=(0.25, 0.75)):
    """Highest f_OUT = N f_REF inside the supported band whose coarse/mid codes leave the target in the
    central part of the fine range (frac_band). Returns (N, coarse, mid, fraction) or None."""
    n_lo = max(3, int(np.ceil(lims["f_lo"] / f_ref)))
    n_hi = min((1 << fcw_bits) + 1, int(np.floor(lims["f_hi"] / f_ref)))
    for N in range(n_hi, n_lo - 1, -1):
        c = codes_for(ch, N * f_ref)
        if c is not None and frac_band[0] <= c[2] <= frac_band[1]:
            return (N,) + c
    for N in range(n_hi, n_lo - 1, -1):              # Relax the fine-range condition
        c = codes_for(ch, N * f_ref)
        if c is not None:
            return (N,) + c
    return None


def pull_in(cfg, ch, coarse, mid, n_ref=6000, starts=("min", "max"), f_offsets=(0.0,)):
    """Noise-free pull-in check of the bang-bang loop after the coarse/mid acquisition: the loop filter
    starts at the lowest/highest fine code and must settle at the code of f_OUT (for each reference
    frequency error in f_offsets, which moves the target code). Returns (all ok, list of results)."""
    out = []
    top = (1 << cfg.filter_bits) - 1
    for fo in f_offsets:
        target = target_period_code(ch, coarse, mid, cfg.f_out * (1 + fo))
        for s in starts:
            f0 = 0 if s == "min" else top
            r = simulate(cfg, ch, coarse, mid, n_ref=n_ref, filt0=f0, noise=False, f_offset=fo,
                         pd_early_range=0.5 / cfg.f_out)
            ok = abs(r.filt[-500:].mean() / cfg.code_lsb - target) < 1
            out.append(dict(start=s, f_offset=fo, target=target, ok=bool(ok)))
    return all(o["ok"] for o in out), out


def choose_gains(cfg, ch, coarse, mid, ratio=1/16, kps=None, safety=1.0):
    """Smallest K_P (K_I = K_P * ratio) that pulls in from both ends of the fine range, also when the
    target moves to 25 % / 75 % of the fine range (spread of the acquisition, reference error), times
    a safety factor (the 25 %/75 % cases already are the margin). Returns (KP, KI, table of the sweep).
    On ics55 at 1 GHz this gives K_P = 4096 (the hand-tuned design of the repository is 3967)."""
    if kps is None:
        kps = np.unique(np.round(np.geomspace(32, 32768, 21)).astype(int))
    nf = len(ch.fine) - 1
    # Reference errors that move the target code to 25 % and 75 % of the fine range
    Tlo, Thi = ch.period(coarse, mid, 0.25 * nf), ch.period(coarse, mid, 0.75 * nf)
    f_offs = tuple(1 / (cfg.f_out * T) - 1 for T in (1 / cfg.f_out, Tlo, Thi))
    rows = []
    kp_min = None
    for kp in kps:
        ki = max(1, int(round(kp * ratio)))
        ok, res = pull_in(replace(cfg, KP=int(kp), KI=ki), ch, coarse, mid, f_offsets=f_offs)
        rows.append((int(kp), ki, ok))
        if ok and kp_min is None:
            kp_min = int(kp)
    if kp_min is None:
        return None, None, rows
    KP = int(min(round(kp_min * safety), (1 << cfg.filter_bits) - 1))
    KI = max(1, int(round(KP * ratio)))
    # The chosen gains must pass too (a larger K_P can break the pull-in through a limit cycle)
    ok, _ = pull_in(replace(cfg, KP=KP, KI=KI), ch, coarse, mid, f_offsets=f_offs)
    if not ok:
        KP, KI = kp_min, max(1, int(round(kp_min * ratio)))
    return KP, KI, rows


def beta_p(cfg, ch, KP=None):
    """Proportional step of the loop in one REF period, relative to T_OUT (A K_P / T)."""
    return cfg.N * ch.fine_lsb / cfg.code_lsb * (cfg.KP if KP is None else KP) * cfg.f_out


def design(ch, inj, f_ref, N=None, KP=None, KI=None, ratio=1/16, fcw_bits=8, beta_max=0.01, log=print):
    """Design target of a technology: f_OUT = N f_REF and the loop gains (see the functions above).
    N/KP/KI given: they are kept (only checked). Otherwise N is the highest multiple of f_REF inside the
    supported band for which a K_P exists that pulls in with a proportional step beta_p <= beta_max T_OUT.
    A bang-bang loop has no frequency detector: at high f_OUT the drift per REF period, relative to T/2,
    gets large, the pull-in needs a large K_P, and the limit cycle (~beta_p) dominates the jitter."""
    lims = technology_limits(ch, inj)
    if N is None:
        n_lo = max(3, int(np.ceil(lims["f_lo"] / f_ref)))
        n_hi = min((1 << fcw_bits) + 1, int(np.floor(lims["f_hi"] / f_ref)))
        cands = list(range(n_hi, n_lo - 1, -1))
    else:
        cands = [int(N)]
    tried = []
    for n in cands:
        c = codes_for(ch, n * f_ref)
        if c is None:
            tried.append((n, None, None, "no coarse/mid codes"))
            continue
        cfg = PLLConfig(f_ref=f_ref, N=n)
        if KP is None:
            kp, ki, rows = choose_gains(cfg, ch, c[0], c[1], ratio=ratio)
        else:
            kp, ki = int(KP), int(KI)
            ok, _ = pull_in(replace(cfg, KP=kp, KI=ki), ch, c[0], c[1])
            rows = [(kp, ki, ok)]
        bp = beta_p(cfg, ch, kp) if kp else None
        good = kp is not None and (KP is not None or N is not None or bp <= beta_max)
        why = "ok" if good else ("no K_P pulls in" if kp is None else f"beta_p = {100*bp:.2f} % T > {100*beta_max:g} %")
        tried.append((n, c, kp, why))
        log(f"N = {n} (f_OUT = {n*f_ref/1e9:.4g} GHz): coarse/mid = {c[0]}/{c[1]}, fine at {100*c[2]:.0f} %, "
            f"K_P/K_I = {kp}/{ki}, beta_p = {100*bp:.2f} % T: {why}" if kp else f"N = {n}: {why}")
        if good:
            return dict(N=n, f_out=n * f_ref, f_ref=f_ref, coarse=c[0], mid=c[1], frac=c[2], KP=kp, KI=ki,
                        beta_p=bp, limits=lims, gain_sweep=rows, tried=tried)
    return dict(N=None, limits=lims, tried=tried)


# Assumptions that are not simulated (shared by the notebook and pll_target.py)
ASSUMED_REF = dict(floor_dBc=-150, L_1k_dBc=-130)   # Reference phase noise at f_REF (crystal + buffer)
ASSUMED_SIGMA_BBPD = 0.3e-12                         # rms input-referred noise of the SS-BBPD (s)
ASSUMED_JITTER_BAND = (10e3, 100e6)                  # Integration band of the rms jitter


def dco_noise_for(ch, f_out):
    """DCO noise of the ISF result scaled to f_out, or None when test_dco_noise has not been run."""
    if ch.dco_pn is None:
        return None
    d = DCONoise.from_isf(ch.dco_pn)
    return d.scaled(ch.dco_pn_f0 or f_out, f_out)


def choose_locked_gains(cfg, ch, coarse, mid, dco, kp_max, ratios=(1/16, 1/32, 1/64), n_ref=1 << 14,
                        hold_codes=3, log=print):
    """Gains after LOCKED (gear shifting): minimum of the sum of the rms jitter without and with injection
    (behavioral model with the DCO/reference/SS-BBPD noise), among the gains that hold the lock: they
    must pull in from +/- hold_codes fine codes around the target (the residual error at LOCKED).
    Returns (KP, KI, jitter without injection, jitter with injection, table)."""
    ref = RefNoise(**ASSUMED_REF)
    cfg = replace(cfg, sigma_bbpd=ASSUMED_SIGMA_BBPD)
    target = target_period_code(ch, coarse, mid, cfg.f_out)
    top = (1 << cfg.filter_bits) - 1
    kps = [k for k in np.unique(np.round(np.geomspace(64, 16384, 17)).astype(int)) if k <= kp_max]
    rows, best = [], None
    for ratio in ratios:
        for kp in kps:
            ki = max(1, int(round(kp * ratio)))
            c = replace(cfg, KP=int(kp), KI=ki)
            hold = True
            for d in (-hold_codes, hold_codes):
                f0 = int(np.clip((target + d) * c.code_lsb, 0, top))
                r = simulate(c, ch, coarse, mid, n_ref=4000, filt0=f0, noise=False, pd_early_range=0.5 / c.f_out)
                hold &= bool(abs(r.filt[-500:].mean() / c.code_lsb - target) < 1)
            j = []
            for inj in (False, True):
                r = simulate(replace(c, inj=inj), ch, coarse, mid, n_ref=n_ref, dco=dco, ref=ref, noise=True,
                             pd_early_range=0.5 / c.f_out)
                x = r.x[len(r.x) // 8:]
                fr, L = phase_noise_from_tie(x, c.f_out, nperseg=min(1 << 17, len(x)))
                j.append(integrated_jitter(fr, L, *ASSUMED_JITTER_BAND, c.f_out))
            rows.append((int(kp), ki, hold, j[0], j[1]))
            if hold and (best is None or j[0] + j[1] < best[2] + best[3]):
                best = (int(kp), ki, j[0], j[1])
    if best is None:
        return None
    log(f"Gains after LOCKED: K_P/K_I = {best[0]}/{best[1]}: {best[2]*1e12:.2f} ps / {best[3]*1e12:.2f} ps rms "
        f"(no injection / injection, {ASSUMED_JITTER_BAND[0]/1e3:g} kHz - {ASSUMED_JITTER_BAND[1]/1e6:g} MHz)")
    return best + (rows,)
