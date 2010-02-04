" vim: fdm=marker
"
" ftplugin to navigate ikiwiki links from within vim
"
" Author: Javier Rojas <jerojasro@devnull.li>
" Version:  1.0
" Last Updated: 2010-01-30
" URL: http://git.devnull.li/cgi-bin/gitweb.cgi?p=vim-jerojasro.git;a=blob;f=.vim/ftplugin/ikiwiki_nav.vim;hb=HEAD
"
" Usage: Hitting <CR> over a wikilink makes vim load the file associated with
" it, if the file exists. To find the file associated with the wikilink, this
" plugin uses the ikiwiki linking rules described in
"
" http://ikiwiki.info/ikiwiki/subpage/linkingrules/
"
" Bugs: it only works with wikilinks contained in only one line. E.g.,
" [[hi there|hi_there]] works, but [[hi
" there|hi_there]] doesn't

" {{{1 returns the directory which can be considered the root of the wiki the
" current buffer belongs to, or an empty string if we are not inside an
" ikiwiki wiki
"
" NOTE: the root of the wiki is considered the first directory that contains a
" .ikiwiki folder, and is not $HOME/.ikiwiki (the usual ikiwiki libdir)
"
" if you can think of a better heuristic to get ikiwiki's root, let me know!
if !exists("*s:GetWikiRootDir") " {{{1
  function! s:GetWikiRootDir()
    let check_str = '%:p:h'
    let pos_wiki_root = expand(check_str)
    while pos_wiki_root != '/'
      if isdirectory(pos_wiki_root . '/.ikiwiki') && pos_wiki_root != $HOME
        return pos_wiki_root
      endif
      let check_str = check_str . ':h'
      let pos_wiki_root = expand(check_str)
    endwhile
    if isdirectory('/.ikiwiki')
      return '/'
    endif
    return ''
  endfunction
endif " }}}1

" {{{1 Searches the current line of the current buffer (where the cursor is
" located) for anything that looks like a wikilink and that has the cursor
" placed on it, and returns its link text
"
" if the cursor isn't over a wikilink, returns an empty string
"
" Examples:
"
" * WikiLinkText(), when the cursor is over '[[hi_there]]' will return 'hi_there'
" * WikiLinkText(), when the cursor is over 'hi_there' will return ''
" (it ain't surrounded by [[]])
" * WikiLinkText(), when the cursor is over '[[Hi There|hi_there]]' will
"   return 'hi_there'
"
" Problems:
" This doesn't work over multiline wikilinks, like [[hi
" there|hi_there]]
if !exists("*s:WikiLinkText") " {{{1
  function s:WikiLinkText()
    let wl_pat = '\v\[\[[^\!\]][^\[\]]*\]\]'
    let start = 0
    let cpos = col(".") - 1
    let wl_ftext = ''
    while 1
      let left_i = match(getline("."), wl_pat, start)
      if left_i < 0
        return ''
      endif
      if left_i > cpos
        return ''
      endif 
      let right_i = matchend(getline("."), wl_pat, start)
      if cpos < right_i
        let wl_ftext = matchstr(getline("."), wl_pat, start)
        break
      endif
      let start = right_i
    endwhile
    if match(wl_ftext, '|') >= 0
      return matchlist(wl_ftext, '\v(\[)*[^\[\| ]*\|([^\] ]+)(\])*')[2]
    endif
    return matchlist(wl_ftext, '\v(\[)*([^\[\] ]+)(\])*')[2]
  endfunction
endif "}}}1

" {{{1 searches for the best conversion of link_text to a path in the
" filesystem, given the path 'real_path' as a prefix, and checking all the
" path elements in 'link_text' against the filesystem contents in a
" case-insensitive fashion
"
" returns a list of one or two 3-tuple, each one of them containing: the
" existing path, the path that needs to be created, and the filename
" corresponding to the wiki link
"
" when the file exists, its path is in the first position of the tuple, and
" the second and third positions are empty
"
" it checks for the existence of a normal page ((dirs)/page.mdwn) and for the
" alternate form of a page ((dirs)/page/index.mdwn), hence the one-or-two
" 3-tuples returned: one for each page alternative
"
" Examples:
" Suposse '/home/user/wiki/dir1/dir2' exists and is empty
" suposse '/home/user/wiki/dir1/mypage.mdwn' exists too
"
" BestLink2FName('/home/user/wiki/dir1', 'dir2/a/b') will return
" [['/home/user/wiki/dir1/dir2', 'a', 'b.mdwn'], ['/home/user/wiki/dir1/dir2', 'a/b', 'index.mdwn']]
"
" BestLink2FName('/home/user/wiki/dir1', 'Dir2/a/b') will return
" [['/home/user/wiki/dir1/dir2', 'a', 'b.mdwn'], ['/home/user/wiki/dir1/dir2', 'a/b', 'index.mdwn']] (case-insensitiviness)
"
" BestLink2FName('/home/user/wiki', 'dir1/MyPage') will return
" [['/home/user/wiki/dir1/mypage.mdwn', '', '']] (all the dirs and the page
" exists)
"
" BestLink2FName('/home/user/wiki', 'dir1/otherdir/MyPage') will return
" [['/home/user/wiki/dir1/', 'otherdir', 'MyPage.mdwn'], ['/home/user/wiki/dir1/', 'otherdir/MyPage', 'index.mdwn']] 
if !exists("*s:BestLink2FName") " {{{1
  function s:BestLink2FName(real_path, link_text)
    let link_text = a:link_text
    let existent_path = a:real_path
    if match(link_text, '^/\|/$\|^$') >= 0
      throw 'IWNAV:INVALID_LINK('.link_text
          \ .'): has a leading or trailing /, or is empty'
    endif
    let page_name = matchstr(link_text, '[^/]\+$')
    let page_fname = fnameescape(page_name.'.mdwn')
    let page_dname = fnameescape(page_name)
    let dirs = substitute(link_text, '/\?'.page_name.'$', '', '')
    " check the existence of all the dirs (parents of) of the page
    while dirs != ''
      let cdir = matchstr(dirs, '^[^/]\+')

      let poss_files = split(glob(existent_path . '/*'), "\n")
      let matches = filter(poss_files,
                         \ 'v:val ==? "'.existent_path.'/'.fnameescape(cdir).'"')
      if len(matches) == 0
        return [[existent_path, dirs, page_fname],
              \ [existent_path, dirs.'/'.page_dname, 'index.mdwn']]
      endif

      let existent_path = matches[0]
      let dirs = substitute(dirs, '^'.cdir.'/\?', '', '')
    endwhile

    " check existence of (dirs)/page.mdwn
    let poss_files = split(glob(existent_path . '/*'), "\n")
    let matches = filter(poss_files,
                       \ 'v:val ==? "'.existent_path.'/'.page_fname.'"')
    if len(matches) > 0
      return [[matches[0], '', '']]
    endif

    " check existence of (dirs)/page/index.mdwn
    " 
    let poss_files = split(glob(existent_path . '/*'), "\n")
    let matches = filter(poss_files,
                       \ 'v:val ==? "'.existent_path.'/'.page_dname.'"')
    if len(matches) > 0
      let existent_path = matches[0]
      let poss_files = split(glob(existent_path . '/*'), "\n")
      let matches = filter(poss_files,
                         \ 'v:val ==? "'.existent_path.'/index.mdwn"')
      if len(matches) > 0
        return [[matches[0], '', '']]
      else
        " page_dname exists, but page_dname/index.mdwn doesn't. WTF is wrong
        " with you?!

        return [[existent_path, '', page_fname],
              \ [existent_path, '', 'index.mdwn']]
      endif
    endif
    " nothing exists, return both possible locations
    return [[existent_path, '', page_fname],
          \ [existent_path, page_dname, 'index.mdwn']]
  endfunction
endif "}}}1

" {{{1 returns all the possible subpaths existing between base_path and
" wiki_root, as a list
"
" Example: GenPosLinkLoc('/home/a/wiki', '/home/a/wiki/dir1/dir2') would
" return ['/home/a/wiki/dir1/dir2', '/home/a/wiki/dir1', '/home/a/wiki']
"
" base_path must have wiki_root as a prefix; an exception is raised otherwise
"
if !exists("*s:GenPosLinkLoc") " {{{1
  function s:GenPosLinkLoc(wiki_root, base_path)
    let wiki_root = a:wiki_root
    let base_path = a:base_path
    let bpo = base_path
    let base_path = substitute(base_path, wiki_root . '/\|' . wiki_root . '$', '', '')
    if base_path == bpo
      throw 'IWNAV:INVALID_BASE('.base_path.', '.wiki_root.')'
    endif
    let pos_locs = []
    while base_path != ''
      call add(pos_locs, wiki_root . '/' . base_path)

      " remove rightmost path element, including its /
      let base_path = substitute(base_path, '/\?[^/]\+$', '', '')
    endwhile
    call add(pos_locs, wiki_root)
    return pos_locs
  endfunction
endif " }}}1

" {{{1 Opens the file associated with the WikiLink currently under the cursor
"
" If no file can be found, prints a messages, and does nothing
"
if !exists("*s:GoToWikiPage") " {{{1
  function s:GoToWikiPage()
    let wl_text = s:WikiLinkText()
    if wl_text == ''
      echo "No wikilink found under the cursor"
      return
    endif
    let ini_path = ''
    let wiki_root = s:GetWikiRootDir()
    if strlen(wiki_root) == 0
      echo "Could not find wiki root dir - aborting"
      return
    endif
    if wl_text =~ '^/'
      let ini_path = wiki_root
      let wl_text = strpart(wl_text, 1)
    else
      let ini_path = expand('%:p:h').'/'.fnameescape(expand('%:p:t:r'))
    endif
    for _path in s:GenPosLinkLoc(wiki_root, ini_path)
      let plinkloc = s:BestLink2FName(_path, wl_text)
      let stdlinkform = plinkloc[0] " (dirs)/page.mdwn
      if strlen(stdlinkform[1]) == 0 && strlen(stdlinkform[2]) == 0
        " yay, the file exists
        exec 'e ' .stdlinkform[0]
        return
      endif
      let altlinkform = plinkloc[0] " (dirs)/page/index.mdwn
      if strlen(altlinkform[1]) == 0 && strlen(altlinkform[2]) == 0
        " yay, the file exists
        exec 'e '.altlinkform[0]
        return
      endif
    endfor
    echo "File does not exist - '".wl_text."'"
  endfunction
endif " }}}1

map <buffer> <CR> :call <SID>GoToWikiPage()<CR>


