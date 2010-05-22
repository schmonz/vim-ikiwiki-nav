" vim: fdm=marker

" find the initial point of the completion
"
" in other words, from which position should the omni-completion be allowed to
" modify the current line
"
" TODO account for the following:
"
" asdfasd af [[adfads]] adfads 
"                         ^
" it should NOT do the completion, but as of now it does
"
" TODO account for directives [[!, they are not links and should not be
" autocompleted for now. We can write autocompletion for them too, though ;)
if !exists("s:FindCplStart") " {{{1
  function s:FindCplStart()
    let li_loc = strridx(getline('.'), '[[', col('.'))
    if li_loc < 0
      return -1
    endif
    return li_loc + 2
  endfunction
endif "}}}1

if !exists("*ikiwiki#cmpl#IkiOmniCpl") " {{{1
  function ikiwiki#cmpl#IkiOmniCpl(findstart, base)
    if a:findstart == 1
      return s:FindCplStart()
    endif
    let mrl = matchlist(base, '^\(\([^/]*/\)*\)\([^/]*\)$')
    let baselink = mrl[1]
    let wk_partialpage = mr[3]
    let dirs_tocheck = ikiwiki#nav#GenPosLinkLoc(expand('%:p:h').'/'
                                       \ .fnameescape(expand('%:p:t:r')))
    if strlen(baselink) > 0
      let baselink = strpart(baselink, 0, strlen(baselink) - 1) " strip last /
      for _path in dirs_tocheck
        let plinkloc = s:BestLink2FName(_path, baselink)
        let exs_dir = plinkloc[0][0]
        if strlen(exs_dir) != strlen(_path) + strlen(baselink) + 1
          continue
        endif
        " check if path+baselink/wk_partialpage* exists
        " if it does, add it to the completion list
      endfor
    endif
    return [a:base."foo", a:base."bar", a:base."baz"]
  endfunction
endif "}}}1

