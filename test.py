import json
import os, sys
from time import sleep

import neovim
from nose.tools import eq_ as eq, ok_ as ok

neovim.setup_logging()

child_argv = os.environ.get('NVIM_CHILD_ARGV')
listen_address = os.environ.get('NVIM_LISTEN_ADDRESS')
if child_argv is None and listen_address is None:
    child_argv = '["nvim", "-u", "NONE", "--embed"]' 

if child_argv is not None:
    vim = neovim.attach('child', argv=json.loads(child_argv))
else:
    vim = neovim.attach('socket', path=listen_address)

if sys.version_info >= (3, 0):
    # For Python3 we decode binary strings as Unicode for compatibility
    # with Python2
    vim = vim.with_decode()

vim.command("set rtp+=.")
vim.command("runtime! plugin/*.vim")

buf = vim.current.buffer
win = vim.current.window

#vim.command("call argclinic#innerArg()")


def move(movement, line, posdef, targets):
    buf[:] = [line]
    status = []
    for i,target in enumerate(targets):
        win.cursor = [1, i]
        vim.input(movement)
        vim.eval("1")
        pos = win.cursor[1]
        expected = posdef.index(target) if target != " " else i
        if pos == expected:
            status.append('.')
        elif pos > expected:
            status.append('+')
        else:
            status.append('-')


    status = ''.join(status)
    if status != len(targets)*'.':
        print(movement, file=sys.stderr)
        print(line, file=sys.stderr)
        print(posdef, file=sys.stderr)
        print(targets, file=sys.stderr)
        print(status+"\n", file=sys.stderr)
        eq(status, len(targets)*'.')


def test_simple_movement():
    move("<Plug>(argclinic-nextarg)",
         "mycall(arg, b, 3 + 4, 'arg')",
         "       a    b  c      d    e",
        #"      abbbbbcccdddddeeeeeee "  intended?
         "      bbbbcccdddddddeeeeeee ")

    move("<Plug>(argclinic-nextend)",
         "mycall(arg, b, 3 + 4, 'arg')",
         "         a  b      c      d ",
         "     aaaabbbcccccccddddddd  ")

    move("<Plug>(argclinic-prevarg)",
         "mycall(arg, b, 3 + 4, 'arg')",
         "       a    b  c      d     ",
         "        aaaaabbbcccccccddddd")

    # q is errornous
    move("<Plug>(argclinic-prevend)",
         "mycall(arg, b, 3 + 4, 'arg')",
         "     q   a  b      c      d ",
         "       qqqqaaabbbbbbbccccccc")

def test_complex_movement():
    # numbers are dubious, we might want that kind of movement
    # but it is not "nextarg"
    move("<Plug>(argclinic-nextarg)",
         "do(a[22, 3], (x, y) + 3, array([[2, 33], [44, 5]]), 'arg')",
         "   a k   l 2 bm  n  3    c     opq  r  4 st   u 567 d    e",
         "  bblll222bccnn333cccccddddddd7srr4444s66uuu55567deeeeeee ")

    move("<Plug>(argclinic-nextend)",
         "do(a[22, 3], (x, y) + 3, array([[2, 33], [44, 5]]), 'arg')",
         "      k  la   m  n    b          q   rp    t  usoc      d ",
         " aakkkllla bmmnnnbbbbbcccccccoopqrrrrp stttuuus   dddddd  ")
         #   a      b b                c        o s      ???

    move("<Plug>(argclinic-prevarg)",
         "do(a[22, 3], (x, y) + 3, array([[2, 33], [44, 5]]), 'arg')",
         "   a k   l   bm  n       c     opq  r    st   u     d    e",
         "    aakkkklaa bmmmnnnbbbbbccccc  pqqqrrpp sttttusocccddddd")
         #             a     bb          co        p

    move("<Plug>(argclinic-prevend)",
         "do(a[22, 3], (x, y) + 3, array([[2, 33], [44, 5]]), 'arg')",
         " 1 2  k  la3  m  n  0 b      456 q   rp7   t  usoc      d ",
         "   11222kkk1aa33mmmaaaaabbbbbbb4566qqqq5pp777tttp4bccccccc")
         #       k  l             b              b
