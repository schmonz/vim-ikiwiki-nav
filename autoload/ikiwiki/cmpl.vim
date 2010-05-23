" vim: fdm=marker


" TODO see how does ikiwiki handle spaces in links, to define the policy to
" handle them here

"{{{1 find the initial point of the completion
"
" in other words, the position from which the omni-completion is allowed to
" modify the current line
"
" TODO account for the following:
"
" asdfasd af [[adfads]] adfads
"                         ^
" it should NOT do the completion, but as of now it tries, by passing in the
" second call the base text 'adfads]] adf' (for this example)
"
"}}}1
if !exists("s:FindCplStart") " {{{1
  function s:FindCplStart()
    let link_str = '[['
    let dir_str = '[[!'
    let li_loc = strridx(getline('.'), link_str, col('.'))
    if li_loc < 0
      return -1
    endif
    let di_loc = strridx(getline('.'), dir_str, col('.'))
    if di_loc == li_loc
      return -1
    endif
    return li_loc + strlen(link_str)
  endfunction
endif "}}}1


if !exists("*s:IntersectPaths") " {{{1
  function s:IntersectPaths(p1, p2)
    let i = 0
    let maxlen = min([strlen(a:p1), strlen(a:p2)])
    while i < maxlen && a:p1[i] == a:p2[i]
      let i = i + 1
    endwhile
    return strpart(a:p1, 0, i)
  endfunction
endif "}}}1

" calculate for how many folders two given paths differ
if !exists("*s:DirsDistance") " {{{1
  function s:DirsDistance(d1, d2)
    let d1 = substitute(fnameescape(a:d1), '/\+', '/', 'g')
    let d2 = substitute(fnameescape(a:d2), '/\+', '/', 'g')
    if strlen(d1) < strlen(d2)
      let tmp = d2
      let d2 = d1
      let d1 = tmp
    endif
    let dirs_left = substitute(d1, '^'.d2, '', '')
    return len(split(dirs_left, '/'))
  endfunction
endif "}}}1

" {{{1 format a filename with its full path for proper presentation in the
" omnicomp menu
"
" all the leading path components up to, and not including base/partialpage*$
" are removed from the filename string
"
" Besides of that:
"
"   * if the filename is a ikiwiki page (.mdwn) its extension is stripped
"   * if the filename is a directory, a '/' is added
"   * otherwise, it is left untouched
"
" }}}1
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
      let rv.menu = 'dir '
    elseif a:fsname =~? '\.mdwn$'
      " TODO once s:AddIdxLinks is written, account here for the index.mdwn case
      let rv.word = fnamemodify(rv.word, ':r')
      let rv.menu = 'page'
    else
      let rv.menu = 'file'
    endif
    let bufdir = expand('%:p:h')
    let cmpldir = fnamemodify(a:fsname, ':h')
    let common_dir = s:IntersectPaths(bufdir, cmpldir)
    let dirdist = s:DirsDistance(common_dir, bufdir) + s:DirsDistance(common_dir, cmpldir)
    let rv.menu = string(dirdist) ."-". rv.menu . " " . pathshorten(a:fsname)
    return rv
  endfunction
endif " }}}1


" {{{1 checks a list of files, and adds <pathname>/index.mdwn
" Intended to check which items of a given list are directories, and which of
" them contain a 'index.mdwn' file, to add those to the received list
" }}}1
if !exists("*s:AddIdxLinks") " {{{1
  function s:AddIdxLinks(path_list)
    " TODO WRITE ME!
    return a:path_list
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
                  \ map(s:AddIdxLinks(split(glob(_path . '/'.wk_partialpage.'*'), "\n")),
                      \ 's:FormatCmpl(v:val, baselink, wk_partialpage)'))
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
                \ map(s:AddIdxLinks(split(glob(exs_dir . '/'.wk_partialpage.'*'), "\n")),
                    \ 's:FormatCmpl(v:val, baselink, wk_partialpage)'))
    endfor
    return completions
  endfunction
endif "}}}1

