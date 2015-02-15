" The Argument Clinic
" very WIP
function! s:ch()
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endfunction

function! s:inStr()
    return synIDattr(synID(line("."), col("."), 0), "name") =~? "string"
endfunction

let s:beg = "([{"
let s:end = ")]}"
let s:re_spec = '\v[,(\[{)\]}]'

function! s:saveCur()
    " from matchit
    let restore_cursor = virtcol(".") . "|"
    normal! g0
    let restore_cursor = line(".") . "G" .  virtcol(".") . "|zs" . restore_cursor
    normal! H
    let restore_cursor = "normal!" . line(".") . "Gzt" . restore_cursor
    execute restore_cursor
    return restore_cursor
endfunction
" maybe searchpairpos would help us but dunno how...
function! XFnd(rev,igstr)
    if !a:rev
        let flag = ''
        let stopat = s:end.','
        let matchat = s:beg
    else
        let flag = 'b'
        let stopat = s:beg.','
        let matchat = s:end
    endif
    while 1
        let res = search(s:re_spec,'W'.flag)
        if res == 0
            return [0]
        endif
        if a:igstr && s:inStr()
            continue
        endif
        let ch = s:ch()
        if stridx(stopat,ch) > -1
            let pos = getpos('.')[1:2]
            return pos + [ch]
        endif
        if stridx(matchat,ch) > -1
            normal %
            continue
        endif
        echoerr "FAIL"
        return [0]
    endwhile
endfunction

function! s:InnerArg()
    let ch = s:ch()
    let pos = [line('.'), col('.')]
    let ostart = []
    let oend = []
    if stridx(s:beg, ch) > -1
        let ostart = pos + [ch]
    elseif stridx(s:end.',', ch) > -1
        let oend = pos + [ch]
    endif
    if ostart == []
        let res = XFnd(1,1)
        if res[0] == 0
            return []
        endif
        let ostart = res
    endif
    if oend == []
        let res = XFnd(0,1)
        if res[0] == 0
            return []
        endif
        let oend = res
    endif
    return [ostart, oend]
endfunction

" TODO: use vim-textobj-user
" i e to support to yanking to named register
" and be less NIH u.s.w
function! ArgClinicInnerArg()
    let [ostart, oend] = XOuterArg()
    call cursor(ostart[0], ostart[1])
    let res = search('\S','W')
    let st = getpos('.')
    call cursor(oend[0], oend[1])
    let res = search('\S','Wb')
    let en = getpos('.')
    return ['v', st, en]
endfunction

call textobj#user#plugin('argclinic', {
\   'arg': {
\     '*select-i-function*': 'ArgClinicInnerArg',
\     'select-i': 'ie',
\   },
\ })

" kinda "barf to register"
" TODO: respect regspec
function! DeleteArg(register)
    let cur0 = s:saveCur()
    echo v:register
    execute "normal \"".a:register."y\<Plug>(textobj-argclinic-arg-i)"
    execute cur0

    let [ostart, oend] = XOuterArg()
    call cursor(ostart[0], ostart[1])
    let delstart = 1
    if stridx(s:beg,ostart[2]) > -1
        let res = search('\S','W')
        let delstart = 0
    endif
    normal! v
    call cursor(oend[0], oend[1])
    let delend = 1
    if delstart || stridx(s:end,  oend[2]) > -1
        let res = search('\S','Wb')
        let delend = 0
    endif
    normal! "_d
    "echo [delstart, delend]
    " cleanup leftover whitespace
    if !delstart && s:ch() == " "
        normal! "_dw
    endif
endfunction
" apparently, this is how it's done:
noremap <expr> <Plug>(argclinic-deletearg) ':call DeleteArg("' . escape(v:register,'"') . '")<cr>'

" kinda "slurp from register"
function! PutArg(before)
    let ch = s:ch()
    let [ostart, oend] = XOuterArg()
    let regsave = [getreg('0'), getregtype('0')]
    let text = getreg(v:register)

    let before = a:before
    if stridx(s:beg, ch) > -1
        let before = 1
    elseif stridx(s:end, ch) > -1
        let before = 0
    end
    if before
        call cursor(ostart[0], ostart[1])
        let res = search('\S','W')
        if stridx(s:end, s:ch()) == -1
            let text = text.', '
        endif
        call setreg('0', text, 'v')
        normal! "0P
    else
        call cursor(oend[0], oend[1])
        let res = search('\S','Wb')
        if stridx(s:beg, s:ch()) == -1
            let text = ', '.text
        endif
        call setreg('0', text, 'v')
        normal! "0p
    end
    call setreg('0', regsave[0], regsave[1])
endfunction

