#!python

# Minimal SPICE netlist reader, enough to flatten the testbenches down to
# the transistors (the 4-terminal d g s b model wrappers of the PDKs).
# The names of the nets follow the ngspice convention for the saved vectors:
# instance path joined by ".", lowercase (e.g. xdco.xcoarse/stage_8_impl/dwn_impl.net6)

import os, re

GROUND = {"0", "gnd"}

def _logical_lines(fil, seen=None):
    """Lines of a file with continuations joined and the .inc/.include files expanded.
    .lib sections (the models) are skipped."""
    seen = set() if seen is None else seen
    fil = os.path.abspath(fil)
    if fil in seen:
        return []
    seen.add(fil)
    lines = []
    with open(fil, errors="replace") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.startswith("+"):
                if lines:
                    lines[-1] += " " + line[1:]
                continue
            lines.append(line)
    out = []
    for line in lines:
        s = line.strip()
        if not s or s.startswith("*"):
            continue
        s = s.split("$ ")[0].strip()
        m = re.match(r'^\.inc(?:lude)?\s+["\']?([^"\']+)["\']?', s, re.I)
        if m:
            inc = m.group(1)
            if not os.path.isabs(inc):
                inc = os.path.join(os.path.dirname(fil), inc)
            out += _logical_lines(inc, seen)
            continue
        out.append(s)
    return out

def _split_params(tokens):
    """Splits the tokens of an instance into (connections + master, params dict)"""
    pos = []
    params = {}
    text = " ".join(tokens)
    # Join "k = v" into "k=v"
    text = re.sub(r'\s*=\s*', '=', text)
    for tok in text.split():
        if "=" in tok:
            k, v = tok.split("=", 1)
            params[k.lower()] = v
        else:
            pos.append(tok)
    return pos, params

class Netlist:
    def __init__(self, fil):
        self.subckts = {}   # name -> (ports, default params, body lines)
        self.top = []
        cur = None
        for s in _logical_lines(fil):
            low = s.lower()
            if low.startswith(".subckt"):
                pos, params = _split_params(s.split()[1:])
                cur = (pos[0].lower(), [p.lower() for p in pos[1:]], params, [])
                continue
            if low.startswith(".ends"):
                if cur:
                    self.subckts[cur[0]] = cur[1:]
                cur = None
                continue
            if low.startswith("."):
                continue
            (cur[3] if cur else self.top).append(s)

    def devices(self, is_device, prefix=""):
        """Flattens the top level. is_device(master) returns 'n', 'p' or None.
        Returns a list of dicts: name, type, master, d, g, s, b (full net names), params."""
        found = []
        self._flatten(self.top, prefix, {}, {}, is_device, found)
        return found

    def _flatten(self, lines, path, netmap, ctx, is_device, found):
        def net(n):
            n = n.lower()
            if n in GROUND:
                return "0"
            if n in netmap:
                return netmap[n]
            return f"{path}.{n}" if path else n

        for s in lines:
            if s[0].lower() not in "xm":
                continue
            pos, params = _split_params(s.split())
            name, conns, master = pos[0].lower(), pos[1:-1], pos[-1].lower()
            params = {k: _resolve(v, ctx) for k, v in params.items()}
            full = f"{path}.{name}" if path else name
            kind = is_device(master)
            if kind:
                d, g, src, b = [net(c) for c in conns[:4]]
                found.append(dict(name=full, type=kind, master=master,
                                  d=d, g=g, s=src, b=b, params=params))
                continue
            if name[0] != "x" or master not in self.subckts:
                continue
            ports, defaults, body = self.subckts[master]
            sub_ctx = {k: _resolve(v, ctx) for k, v in defaults.items()}
            sub_ctx.update(params)
            sub_map = {p: net(c) for p, c in zip(ports, conns)}
            self._flatten(body, full, sub_map, sub_ctx, is_device, found)

def _resolve(v, ctx):
    """Substitutes a parameter by its value in the parent context (only plain names)"""
    key = v.strip("'{}").lower()
    return ctx.get(key, v)

def nets_of_subckt_instance(netlist, prefix):
    """All the nets (full names) of the devices under the instance path prefix"""
    return sorted({n for d in netlist for n in (d["d"], d["g"], d["s"]) if n.startswith(prefix + ".")})
