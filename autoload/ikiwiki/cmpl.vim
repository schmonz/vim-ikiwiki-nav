" vim: fdm=marker

" find the initial point of the completion
"
" in other words, from which position should the omni-completion be allowed to
" modify the current line
if !exists("*ikiwiki#cmpl#IkiOmniCpl") " {{{1
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
    return [a:base."bomba", a:base."pato", a:base."mama"]
  endfunction
endif "}}}1

