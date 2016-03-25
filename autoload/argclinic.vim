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
function! argclinic#FindDelim(rev,igstr)
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
            " TODO: if already in str, stay in str?
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

" dir 1,-1
" adjust -1, 0, 1
" TODO: not as intended when adjusting forward?
" ^(^ arg, arg2) jumps to arg2, should to arg?
function! argclinic#moveDelim(dir,igstr, adjust)
    if a:adjust*a:dir < 0 && match(s:ch(), s:re_spec) == -1
        if a:adjust > 0
            call search('\S','Wb')
        else
            call search('\S','W')
        endif
    endif
    let cur0 = s:saveCur()
    let status = argclinic#FindDelim(a:dir<0, a:igstr)
    if status[0] == 0
        execute cur0
    endif
    if a:adjust
        if a:adjust > 0
            call search('\S','W')
        else
            call search('\S','Wb')
        endif
    endif
endfunction


function! s:outerArg()
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
        let res = argclinic#FindDelim(1,1)
        if res[0] == 0
            return []
        endif
        let ostart = res
    endif
    if oend == []
        let res = argclinic#FindDelim(0,1)
        if res[0] == 0
            return []
        endif
        let oend = res
    endif
    return [ostart, oend]
endfunction

function! argclinic#innerArg()
    let [ostart, oend] = s:outerArg()
    call cursor(ostart[0], ostart[1])
    let res = search('\S','W')
    let st = getpos('.')[1:2]
    call cursor(oend[0], oend[1])
    let res = search('\S','Wb')
    let en = getpos('.')[1:2]
    return [st, en]
endfunction

function! argclinic#select(mode, start, end)
    execute "normal! ".a:mode
    call cursor(a:start[0], a:start[1])
    normal! o
    call cursor(a:end[0], a:end[1])
    if &selection ==# 'exclusive'
        normal! l
    endif
endfunction

function! argclinic#selectinner()
    let [start, end] = argclinic#innerArg()
    call argclinic#select('v', start, end)
endfunction

" kinda "barf to register"
" TODO: respect regspec
function! argclinic#DeleteArg(register)
    let cur0 = s:saveCur()
    echo v:register
    execute "normal \"".a:register."y\<Plug>(argclinic-selectarg)"
    execute cur0

    let [ostart, oend] = s:outerArg()
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

" kinda "slurp from register"
function! argclinic#PutArg(before)
    let ch = s:ch()
    let [ostart, oend] = s:outerArg()
    let regsave = [getreg('0'), getregtype('0')]
    let text = getreg(v:register)

    let before = a:before
    if stridx(s:beg, ch) > -1
        let before = 1
    elseif stridx(s:end, ch) > -1
        let before = 0
    endif
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
    endif
    call setreg('0', regsave[0], regsave[1])
endfunction
