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

if !exists("*s:FormatCmpl") " {{{1
  function s:FormatCmpl(fsname, base, partialpage)
    let base = fnameescape(a:base)
    let partialpage = fnameescape(a:partialpage)
    let pat = '\c' . base . '/' . partialpage . '[^/]*$'
    if strlen(base) == 0
      let pat = '\c' . partialpage . '[^/]*$'
    endif
    let rv = {'word': matchstr(a:fsname, pat)}
    if isdirectory(a:fsname)
      let rv.word = rv.word . '/'
      let rv.menu = 'dir'
    elseif a:fsname =~? '\.mdwn$'
      let rv.word = fnamemodify(rv.word, ':r')
      let rv.menu = 'page'
    else
      let rv.menu = 'file'
    endif
    return rv
  endfunction
endif " }}}1

" TODO add limits to the completion list size
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
      " TODO account for dir/index.mdwn
      for _path in dirs_tocheck
        call extend(completions,
                  \ map(split(glob(_path . '/'.wk_partialpage.'*'), "\n"),
                      \ 's:FormatCmpl(v:val, "'.baselink.'", "'.wk_partialpage.'")'))
      endfor
      return completions
    endif
    let baselink = strpart(baselink, 0, strlen(baselink) - 1) " strip last /
    for _path in dirs_tocheck
      let plinkloc = ikiwiki#nav#BestLink2FName(_path, baselink.'/dummy')
      let exs_dir = plinkloc[0][0]
      if strlen(exs_dir) != strlen(_path) + strlen(baselink) + 1
        continue
      endif
      " TODO account for dir/index.mdwn
      call extend(completions,
                \ map(split(glob(exs_dir . '/'.wk_partialpage.'*'), "\n"),
                    \ 's:FormatCmpl(v:val, "'.baselink.'", "'.wk_partialpage.'")'))
    endfor
    return completions
  endfunction
endif "}}}1

