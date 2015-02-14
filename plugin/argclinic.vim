" The Argument Clinic
" very WIP
function! Ch()
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endfunction

function! InStr()
    return synIDattr(synID(line("."), col("."), 0), "name") =~? "string"
endfunction

let s:beg = "([{"
let s:end = ")]}"
let s:re_spec = '\v[,(\[{)\]}]'
let s:re_spec = '\v\S'

function! SaveCur()
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
        if a:igstr && InStr()
            continue
        endif
        let ch = Ch()
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

function! XOuterArg()
    let ch = Ch()
    let pos = [line('.'), col('.')]
    let ostart = []
    let oend = []
    if stridx(s:beg.',', ch) > -1
        let ostart = pos + [ch]
    elseif stridx(s:end, ch) > -1
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

" TODO: use text-usrobjct
function! XInnerArg(ostart, oend)
    call cursor(ostart[1], ostart[2])
    let res = search('\S','W')
end

