function! s:CsvEval(inp, line1, line2)
python3 << EOF
import vim
import re
import string
import math
from functools import reduce

inp = vim.eval("a:inp")

def cmd_round(inp):
    return round(evalword(inp))

def cmd_floor(inp):
    return float(math.floor(evalword(inp)))

def cmd_ceil(inp):
    return float(math.ceil(evalword(inp)))

def parse_args(inp, l):
    tup = re.split(",\s*(?![^()]*\))", inp)
    r = []

    for i in range(len(tup)):
        x = evalword(tup[i].strip())
        if type(x) is list:
            r = x
        else:
            r.append(x)
    return l(r)

def cmd_divide(inp):
    return parse_args(inp, lambda a: a[0] / a[1])

def cmd_multiply(inp):
    return parse_args(inp, lambda a: a[0] * a[1])

def cmd_sum(inp):
    return parse_args(inp, lambda a: sum(n for n in a))

def cmd_subtract(inp):
    return parse_args(inp, lambda a: a[0] - a[1])

def cmd_mean(inp):
    return parse_args(inp, lambda a: sum(n for n in a) / len(a))

cmds = {
    "round": cmd_round,
    "floor": cmd_floor,
    "ceil": cmd_ceil,
    "divide": cmd_divide,
    "multiply": cmd_multiply,
    "sum": cmd_sum,
    "subtract": cmd_subtract,
    "mean": cmd_mean
    }

cellregex = "[a-zA-Z]+[0-9#]+"

conf_detectdelim = vim.eval("get(g:, \"csveval_detectdelim\", 1)")
conf_forcedelim = vim.eval("get(g:, \"csveval_forcedelim\", 0)")

delim = ","

if conf_forcedelim != "0":
    delim = conf_forcedelim
elif conf_detectdelim == "1":
    delims = [",", " ", "\t", ";"]
    for d in delims:
        for l in range(0, min(len(vim.current.buffer), 10)):
            if re.search("[0-9]+" + d + "[0-9]+", vim.current.buffer[l]):
                delim = d
                break
        else:
            continue
        break

def cellpos(c):
    col = re.match("^[a-zA-Z]+", c)
    row = re.search("[0-9#]+$", c)
    if col is None or row is None:
        print("Invalid cell", file=sys.stderr)
        return 0

    cols = col.group(0)
    coln = reduce(lambda r, x: r * 26 + x + 1, map(string.ascii_uppercase.index, cols.upper()), 0) - 1
    rows = row.group(0)
    rown = 0
    if rows == "#":
        rown = vimrow
    else:
        rown = int(rows) - 1
    return coln, rown

def cell(col, row):
    v = float(vim.current.buffer[row].split(delim)[col])
    return v

def cellrange(r):
    c1, c2 = re.match("(" + cellregex + "):(" + cellregex + ")", r).groups()
    c1rn, c1cn = cellpos(c1)
    c2rn, c2cn = cellpos(c2)
    rmin, rmax = min(c1rn, c2rn), max(c1rn, c2rn)
    cmin, cmax = min(c1cn, c2cn), max(c1cn, c2cn)

    r = []

    for x in range(rmin, rmax + 1):
        for y in range(cmin, cmax + 1):
            r.append(cell(x, y))

    return r

def findarg(inp):
    str = ""
    n = 0
    for c in inp:
        if c == '(':
            n += 1
        elif c == ')':
            if n == 0:
                break
            n -= 1
        str += c
    return str

def evalword(inp):
    inp = inp.strip()
    word = re.match("[^()]+", inp).group(0)
    inp = inp.removeprefix(word)

    if inp and inp[0] == "(":
        inp = inp[1:]
        if word in cmds:
            arg = findarg(inp)
            if not arg:
                print("Missing closing bracket", file=sys.stderr)
            inp = inp.removeprefix(arg)[1:]
            return cmds[word](arg)
        else:
            print("Invalid command: " + word, file=sys.stderr)
    elif re.match(cellregex + ":" + cellregex, word):
        return cellrange(word)
    elif re.match(cellregex, word):
        return cell(*cellpos(word))
    elif re.match("^(?:[0-9]+)|(?:[0-9]\.[0-9]*)|(?:\.[0-9]+)", word):
        return float(word)
    else:
        print("Invalid input:", word, file=sys.stderr)
        return 0

line1 = int(vim.eval("a:line1")) - 1
line2 = int(vim.eval("a:line2")) - 1
vimrow = 0

for i in range(line1, line2 + 1):
    vimrow = i
    vim.current.buffer[i] += delim + str(evalword(inp)).rstrip("0").rstrip(".")

EOF
endfunction

command! -nargs=+ -range -bar CsvEval call s:CsvEval('<args>', '<line1>', '<line2>')
