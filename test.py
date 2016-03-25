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
        print(line)
        print(posdef)
        print(targets)
        print(status)
        eq(status, len(targets)*'.')


def test_simple_movement():
    move("<Plug>(argclinic-nextarg)",
         "mycall(arg, b, 3 + 4, 'arg')",
         "       a    b  c      d    e",
        #"      abbbbbcccdddddeeeeeee "  intended
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

