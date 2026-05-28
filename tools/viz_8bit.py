import tkinter as tk
from tkinter import ttk

MEM_SIZE = 256

OP = {
    0x86: ("LDA_IMM", 2), 0x87: ("LDA_DIR", 2),
    0x88: ("LDB_IMM", 2), 0x89: ("LDB_DIR", 2),
    0x96: ("STA_DIR", 2), 0x97: ("STB_DIR", 2),
    0x42: ("ADD_AB", 1), 0x43: ("SUB_AB", 1),
    0x44: ("AND_AB", 1), 0x45: ("OR_AB", 1),
    0x46: ("INCA", 1), 0x47: ("INCB", 1),
    0x48: ("DECA", 1), 0x49: ("DECB", 1),
    0x20: ("BRA", 2), 0x21: ("BMI", 2), 0x22: ("BPL", 2),
    0x23: ("BEQ", 2), 0x24: ("BNE", 2), 0x25: ("BVS", 2),
    0x26: ("BVC", 2), 0x27: ("BCS", 2), 0x28: ("BCC", 2),
}

ROM = [0x00] * 128
prog = [
    0x86, 0x05, 0x88, 0x03, 0x42, 0x96, 0xE0,
    0x86, 0xFF, 0x88, 0x01, 0x42, 0x96, 0xE1,
    0x23, 0x16,
    0x86, 0xAA, 0x96, 0xE2, 0x20, 0x1E,
    0x86, 0x55, 0x96, 0xE3,
    0x86, 0x0A, 0x88, 0x03, 0x43, 0x96, 0xE4,
    0x86, 0x0F, 0x88, 0xF0, 0x44, 0x96, 0xE5,
    0x86, 0x0F, 0x88, 0xF0, 0x45, 0x96, 0xE6,
    0x86, 0x7F, 0x46, 0x96, 0xE7,
    0x86, 0x01, 0x48, 0x96, 0xE8,
    0x20, 0x00,
]
for i, b in enumerate(prog):
    ROM[i] = b


def hex2(v):
    return f"{v & 0xFF:02X}"


def decode_rom_lines(rom, used_len):
    lines = []
    pc = 0
    while pc < used_len:
        op = rom[pc]
        name, size = OP.get(op, ("DB", 1))
        if size == 2 and pc + 1 < used_len:
            arg = rom[pc + 1]
            if name.endswith("_IMM"):
                arg_str = f"#{arg:02X}"
            else:
                arg_str = f"${arg:02X}"
            lines.append((pc, f"{pc:02X}: {op:02X} {arg:02X}   {name:<7} {arg_str}"))
        else:
            lines.append((pc, f"{pc:02X}: {op:02X}      {name}"))
        pc += size
    return lines


class CPU:
    def __init__(self):
        self.reset()

    def reset(self):
        self.pc = 0
        self.a = 0
        self.b = 0
        self.ir = 0
        self.mar = 0
        self.nzvc = [0, 0, 0, 0]  # N Z V C
        self.ram = [0] * 96
        self.out = [0] * 16
        self.inp = [0] * 16
        self.halted = False

    def flags_str(self):
        return ''.join('NZVC'[i] if v else '-' for i, v in enumerate(self.nzvc))

    def get_mem(self, addr):
        addr &= 0xFF
        if addr < 0x80:
            return ROM[addr]
        if addr < 0xE0:
            return self.ram[addr - 0x80]
        if addr < 0xF0:
            return self.out[addr - 0xE0]
        return self.inp[addr - 0xF0]

    def set_mem(self, addr, val):
        addr &= 0xFF
        val &= 0xFF
        if 0x80 <= addr < 0xE0:
            self.ram[addr - 0x80] = val
        elif 0xE0 <= addr < 0xF0:
            self.out[addr - 0xE0] = val

    def upd_nz(self, v):
        self.nzvc[0] = 1 if (v & 0x80) else 0
        self.nzvc[1] = 1 if (v & 0xFF) == 0 else 0

    def alu_add(self, x, y):
        raw = x + y
        r = raw & 0xFF
        c = 1 if raw > 0xFF else 0
        v = 1 if ((~(x ^ y) & (x ^ r)) & 0x80) else 0
        self.nzvc = [1 if r & 0x80 else 0, 1 if r == 0 else 0, 1 if v else 0, c]
        return r

    def alu_sub(self, x, y):
        raw = x - y
        r = raw & 0xFF
        c = 1 if x >= y else 0
        v = 1 if (((x ^ y) & (x ^ r)) & 0x80) else 0
        self.nzvc = [1 if r & 0x80 else 0, 1 if r == 0 else 0, 1 if v else 0, c]
        return r

    def _branch_taken(self, op):
        n, z, v, c = self.nzvc
        if op == 0x20:   # BRA
            return True
        if op == 0x21:   # BMI
            return n == 1
        if op == 0x22:   # BPL
            return n == 0
        if op == 0x23:   # BEQ
            return z == 1
        if op == 0x24:   # BNE
            return z == 0
        if op == 0x25:   # BVS
            return v == 1
        if op == 0x26:   # BVC
            return v == 0
        if op == 0x27:   # BCS
            return c == 1
        if op == 0x28:   # BCC
            return c == 0
        return False

    def step(self):
        if self.halted:
            return {
                "pc_before": self.pc,
                "pc_after": self.pc,
                "name": "HALT",
                "fetch": "FETCH: halted",
                "decode": "DECODE: halted",
                "execute": "EXEC: halted",
                "mem": "MEM: -",
                "info": "HALT",
            }

        pc0 = self.pc & 0xFF

        # FETCH
        self.mar = pc0
        self.ir = self.get_mem(self.mar)
        op = self.ir
        name, size = OP.get(op, ("UNKNOWN", 1))
        arg_addr = (pc0 + 1) & 0xFF
        arg = self.get_mem(arg_addr) if size == 2 else None

        fetch_line = f"FETCH: MAR<-PC({hex2(pc0)}), IR<-M[{hex2(self.mar)}]={hex2(op)}"
        decode_line = f"DECODE: {name} ({'2B' if size == 2 else '1B'})" + (f", operand={hex2(arg)}" if arg is not None else "")

        mem_line = "MEM: no access"
        exec_line = "EXEC: no-op"

        if op == 0x86:  # LDA_IMM
            self.a = arg
            self.upd_nz(self.a)
            self.pc = (pc0 + 2) & 0xFF
            exec_line = f"EXEC: A<-#{hex2(arg)}"
        elif op == 0x87:  # LDA_DIR
            val = self.get_mem(arg)
            self.a = val
            self.upd_nz(self.a)
            self.pc = (pc0 + 2) & 0xFF
            mem_line = f"MEM: READ M[{hex2(arg)}]={hex2(val)}"
            exec_line = f"EXEC: A<-M[{hex2(arg)}]"
        elif op == 0x88:  # LDB_IMM
            self.b = arg
            self.upd_nz(self.b)
            self.pc = (pc0 + 2) & 0xFF
            exec_line = f"EXEC: B<-#{hex2(arg)}"
        elif op == 0x89:  # LDB_DIR
            val = self.get_mem(arg)
            self.b = val
            self.upd_nz(self.b)
            self.pc = (pc0 + 2) & 0xFF
            mem_line = f"MEM: READ M[{hex2(arg)}]={hex2(val)}"
            exec_line = f"EXEC: B<-M[{hex2(arg)}]"
        elif op == 0x96:  # STA_DIR
            self.set_mem(arg, self.a)
            self.pc = (pc0 + 2) & 0xFF
            mem_line = f"MEM: WRITE M[{hex2(arg)}]<-{hex2(self.a)}"
            exec_line = f"EXEC: M[{hex2(arg)}]<-A"
        elif op == 0x97:  # STB_DIR
            self.set_mem(arg, self.b)
            self.pc = (pc0 + 2) & 0xFF
            mem_line = f"MEM: WRITE M[{hex2(arg)}]<-{hex2(self.b)}"
            exec_line = f"EXEC: M[{hex2(arg)}]<-B"
        elif op == 0x42:  # ADD_AB
            old_a = self.a
            self.a = self.alu_add(self.a, self.b)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A+B ({hex2(old_a)}+{hex2(self.b)}={hex2(self.a)})"
        elif op == 0x43:  # SUB_AB
            old_a = self.a
            self.a = self.alu_sub(self.a, self.b)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A-B ({hex2(old_a)}-{hex2(self.b)}={hex2(self.a)})"
        elif op == 0x44:  # AND_AB
            self.a = self.a & self.b
            self.upd_nz(self.a)
            self.nzvc[2] = 0
            self.nzvc[3] = 0
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A&B ({hex2(self.a)})"
        elif op == 0x45:  # OR_AB
            self.a = self.a | self.b
            self.upd_nz(self.a)
            self.nzvc[2] = 0
            self.nzvc[3] = 0
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A|B ({hex2(self.a)})"
        elif op == 0x46:  # INCA
            old_a = self.a
            self.a = self.alu_add(self.a, 1)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A+1 ({hex2(old_a)}-> {hex2(self.a)})"
        elif op == 0x47:  # INCB
            old_b = self.b
            self.b = self.alu_add(self.b, 1)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: B<-B+1 ({hex2(old_b)}-> {hex2(self.b)})"
        elif op == 0x48:  # DECA
            old_a = self.a
            self.a = self.alu_sub(self.a, 1)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: A<-A-1 ({hex2(old_a)}-> {hex2(self.a)})"
        elif op == 0x49:  # DECB
            old_b = self.b
            self.b = self.alu_sub(self.b, 1)
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: B<-B-1 ({hex2(old_b)}-> {hex2(self.b)})"
        elif 0x20 <= op <= 0x28:  # Branch group
            taken = self._branch_taken(op)
            self.pc = arg if taken else (pc0 + 2) & 0xFF
            exec_line = f"EXEC: BRANCH {'TAKEN' if taken else 'NOT TAKEN'} -> PC={hex2(self.pc)}"
        else:
            self.pc = (pc0 + 1) & 0xFF
            exec_line = f"EXEC: UNKNOWN {hex2(op)}, skip"

        info = f"PC={hex2(pc0)} IR={hex2(op)} {name}"
        return {
            "pc_before": pc0,
            "pc_after": self.pc,
            "op": op,
            "arg": arg,
            "name": name,
            "fetch": fetch_line,
            "decode": decode_line,
            "execute": exec_line,
            "mem": mem_line,
            "info": info,
        }


cpu = CPU()
PROGRAM_LINES = decode_rom_lines(ROM, len(prog))

root = tk.Tk()
root.title("8-bit Computer Visualizer")
root.geometry("1280x820")
root.configure(bg="#101820")

style = ttk.Style()
style.theme_use("clam")
style.configure("TFrame", background="#101820")
style.configure("TLabel", background="#101820", foreground="#E8F1F2", font=("Consolas", 11))
style.configure("Title.TLabel", font=("Consolas", 16, "bold"), foreground="#7CFF6B")
style.configure("Val.TLabel", font=("Consolas", 14, "bold"), foreground="#FFD166")
style.configure("TButton", font=("Consolas", 11, "bold"))

main = ttk.Frame(root, padding=12)
main.pack(fill="both", expand=True)

header = ttk.Label(main, text="8-bit Computer Visualizer", style="Title.TLabel")
header.grid(row=0, column=0, sticky="w")

status = ttk.Label(main, text="Ready")
status.grid(row=0, column=1, sticky="e")

regs = ttk.LabelFrame(main, text="CPU Registers", padding=10)
regs.grid(row=1, column=0, sticky="nsew", padx=5, pady=5)
memf = ttk.LabelFrame(main, text="Output Ports", padding=10)
memf.grid(row=1, column=1, sticky="nsew", padx=5, pady=5)
codef = ttk.LabelFrame(main, text="Program / Fetch-Decode-Execute", padding=10)
codef.grid(row=2, column=0, columnspan=2, sticky="nsew", padx=5, pady=5)

main.columnconfigure(0, weight=1)
main.columnconfigure(1, weight=1)
main.rowconfigure(1, weight=1)
main.rowconfigure(2, weight=1)

reg_vars = {}
for i, name in enumerate(["PC", "IR", "MAR", "A", "B", "CCR"]):
    ttk.Label(regs, text=name).grid(row=i, column=0, sticky="w", padx=4, pady=3)
    v = ttk.Label(regs, text="00", style="Val.TLabel")
    v.grid(row=i, column=1, sticky="w", padx=4, pady=3)
    reg_vars[name] = v

pcasm = ttk.Label(codef, text="PC: 00  |  IR: 00  |  Instr: ---")
pcasm.pack(anchor="w", pady=(0, 4))

stage_fetch = tk.StringVar(value="FETCH: -")
stage_decode = tk.StringVar(value="DECODE: -")
stage_execute = tk.StringVar(value="EXEC: -")
stage_mem = tk.StringVar(value="MEM: -")

ttk.Label(codef, textvariable=stage_fetch).pack(anchor="w")
ttk.Label(codef, textvariable=stage_decode).pack(anchor="w")
ttk.Label(codef, textvariable=stage_execute).pack(anchor="w")
ttk.Label(codef, textvariable=stage_mem).pack(anchor="w", pady=(0, 6))

pane = ttk.Frame(codef)
pane.pack(fill="both", expand=True)
pane.columnconfigure(0, weight=1)
pane.columnconfigure(1, weight=1)
pane.rowconfigure(0, weight=1)

program_text = tk.Text(pane, height=12, bg="#0B0F14", fg="#8DE9FF", insertbackground="white")
program_text.grid(row=0, column=0, sticky="nsew", padx=(0, 4))
program_text.configure(state="disabled")

log = tk.Text(pane, height=12, bg="#0B0F14", fg="#C7F9CC", insertbackground="white")
log.grid(row=0, column=1, sticky="nsew", padx=(4, 0))
log.insert("end", "GUI siap. Tekan Step atau Run.\n")
log.configure(state="disabled")

port_canvas = tk.Canvas(memf, width=500, height=500, bg="#101820", highlightthickness=0)
port_canvas.pack(fill="both", expand=True)
port_boxes = []
for i in range(16):
    x = 20 + (i % 4) * 115
    y = 20 + (i // 4) * 105
    port_canvas.create_rectangle(x, y, x + 90, y + 75, outline="#7CFF6B", width=2)
    port_canvas.create_text(x + 45, y + 12, text=f"OUT {i:02d}", fill="#E8F1F2", font=("Consolas", 10, "bold"))
    txt = port_canvas.create_text(x + 45, y + 36, text="00", fill="#FFD166", font=("Consolas", 16, "bold"))
    ascii_txt = port_canvas.create_text(x + 45, y + 50, text="'.'", fill="#8DE9FF", font=("Consolas", 10, "bold"))
    bar = port_canvas.create_rectangle(x + 10, y + 60, x + 80, y + 70, outline="#999", fill="#333")
    fill = port_canvas.create_rectangle(x + 10, y + 60, x + 10, y + 70, outline="", fill="#00C2FF")
    port_boxes.append((txt, ascii_txt, bar, fill, x, y))

# Input frame for character/byte
char_frame = ttk.LabelFrame(main, text="Send Byte to Output", padding=10)
char_frame.grid(row=4, column=0, columnspan=2, sticky="nsew", padx=5, pady=5)
ttk.Label(char_frame, text="Char / Hex:").grid(row=0, column=0, sticky="w")
char_entry = ttk.Entry(char_frame, width=5)
char_entry.grid(row=0, column=1, sticky="w", padx=4)

def send_char():
    val = char_entry.get().strip()
    if not val:
        return
    try:
        # hex mode: 0x41 or 41
        if val.lower().startswith('0x'):
            num = int(val, 16)
            src = f"hex {val}"
        elif all(c in '0123456789abcdefABCDEF' for c in val) and len(val) <= 2:
            num = int(val, 16)
            src = f"hex {val}"
        # char mode: only single character allowed
        elif len(val) == 1:
            num = ord(val)
            src = f"char '{val}'"
        else:
            append_log(f"Invalid input '{val}': pakai 1 char atau 2 digit hex")
            return
    except Exception:
        append_log(f"Invalid input '{val}'")
        return

    num &= 0xFF
    cpu.a = num
    cpu.set_mem(0xE0, num)  # write to OUT0
    ascii_view = chr(num) if 32 <= num <= 126 else '.'
    append_log(f"Sent {src} -> OUT0 = {hex2(num)} (dec {num}, ascii '{ascii_view}')")
    refresh()
send_btn = ttk.Button(char_frame, text="Send", command=send_char)
send_btn.grid(row=0, column=2, padx=6)


running = False


def render_program(current_addr):
    program_text.configure(state="normal")
    program_text.delete("1.0", "end")
    for addr, line in PROGRAM_LINES:
        marker = ">" if addr == current_addr else " "
        program_text.insert("end", f"{marker} {line}\n")
    program_text.configure(state="disabled")


def refresh(trace=None):
    reg_vars["PC"].config(text=hex2(cpu.pc))
    reg_vars["IR"].config(text=hex2(cpu.ir))
    reg_vars["MAR"].config(text=hex2(cpu.mar))
    reg_vars["A"].config(text=hex2(cpu.a))
    reg_vars["B"].config(text=hex2(cpu.b))
    reg_vars["CCR"].config(text=cpu.flags_str())

    op = cpu.ir
    name = OP.get(op, ("---", 1))[0]
    pcasm.config(text=f"PC: {hex2(cpu.pc)}  |  IR: {hex2(cpu.ir)}  |  Instr: {name}")

    current_addr = trace["pc_before"] if trace else cpu.pc
    render_program(current_addr)

    for i, (txt, ascii_txt, bar, fill, x, y) in enumerate(port_boxes):
        val = cpu.out[i]
        ch = chr(val) if 32 <= val <= 126 else '.'
        port_canvas.itemconfig(txt, text=hex2(val))
        port_canvas.itemconfig(ascii_txt, text=f"'{ch}'")
        width = 10 + int((val / 255) * 70)
        port_canvas.coords(fill, x + 10, y + 60, x + width, y + 70)

    root.update_idletasks()


def append_log(line):
    log.configure(state="normal")
    log.insert("end", line + "\n")
    log.see("end")
    log.configure(state="disabled")


def do_step():
    if cpu.pc >= 128:
        return
    trace = cpu.step()

    stage_fetch.set(trace["fetch"])
    stage_decode.set(trace["decode"])
    stage_execute.set(trace["execute"])
    stage_mem.set(trace["mem"])

    append_log(
        f"{trace['info']} | {trace['execute']} | {trace['mem']} | "
        f"A={hex2(cpu.a)} B={hex2(cpu.b)} NZVC={cpu.flags_str()}"
    )
    refresh(trace)


def run_loop():
    global running
    if not running:
        return
    do_step()
    root.after(350, run_loop)


def on_run():
    global running
    running = True
    run_loop()


def on_stop():
    global running
    running = False


def on_reset():
    global running
    running = False
    cpu.reset()

    stage_fetch.set("FETCH: -")
    stage_decode.set("DECODE: -")
    stage_execute.set("EXEC: -")
    stage_mem.set("MEM: -")

    log.configure(state="normal")
    log.delete("1.0", "end")
    log.insert("end", "Reset done.\n")
    log.configure(state="disabled")
    refresh()


btns = ttk.Frame(main)
btns.grid(row=3, column=0, columnspan=2, pady=8)
for t, cmd in [("Step", do_step), ("Run", on_run), ("Stop", on_stop), ("Reset", on_reset)]:
    ttk.Button(btns, text=t, command=cmd).pack(side="left", padx=6)

refresh()
root.mainloop()
