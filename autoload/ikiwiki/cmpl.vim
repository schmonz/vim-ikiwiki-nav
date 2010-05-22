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
    let completions = []
    let mrl = matchlist(a:base, '^\(\([^/]*/\)*\)\([^/]*\)$')
    let baselink = mrl[1]
    let wk_partialpage = mrl[3]
    let dirs_tocheck = ikiwiki#nav#GenPosLinkLoc(expand('%:p:h').'/'
                                       \ .fnameescape(expand('%:p:t:r')))
    if strlen(baselink) == 0
      " TODO check for .mdwn files and strip their extension
      " TODO check for dirs and add a trailing /
      " TODO account for dir/index.mdwn
      call input('baselink 0')
      for _path in dirs_tocheck
        call extend(completions, split(glob(_path . '/'.wk_partialpage.'*'), "\n"))
      endfor
      return completions
    endif
    let baselink = strpart(baselink, 0, strlen(baselink) - 1) " strip last /
    call input('baselink '.baselink)
    for _path in dirs_tocheck
      call input('path '._path)
      let plinkloc = ikiwiki#nav#BestLink2FName(_path, baselink.'/dummy')
      echo plinkloc
      let exs_dir = plinkloc[0][0]
      call input('exs_dir '.exs_dir)
      if strlen(exs_dir) != strlen(_path) + strlen(baselink) + 1
        call input('skipped')
        continue
      endif
      " TODO check for .mdwn files and strip their extension
      " TODO check for dirs and add a trailing /
      " TODO account for dir/index.mdwn
      call extend(completions, split(glob(exs_dir . '/'.wk_partialpage.'*'), "\n"))
    endfor
    return completions
  endfunction
endif "}}}1

