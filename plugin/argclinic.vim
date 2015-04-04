" apparently, this is how it's done:
noremap <expr> <Plug>(argclinic-deletearg) ':call argclinic#DeleteArg("' . escape(v:register,'"') . '")<cr>'

" TODO: should work with repeat, count, and stuff.
noremap <Plug>(argclinic-putarg) :<c-u>call argclinic#PutArg(0)<cr>
noremap <Plug>(argclinic-putarg-before) :<c-u>call argclinic#PutArg(1)<cr>

" TODO: should work with count
noremap <Plug>(argclinic-nextarg) :<c-u>call argclinic#moveDelim(1,1,1)<cr>
noremap <Plug>(argclinic-prevarg) :<c-u>call argclinic#moveDelim(-1,1,1)<cr>
noremap <Plug>(argclinic-nextend) :<c-u>call argclinic#moveDelim(1,1,-1)<cr>
noremap <Plug>(argclinic-prevend) :<c-u>call argclinic#moveDelim(-1,1,-1)<cr>
