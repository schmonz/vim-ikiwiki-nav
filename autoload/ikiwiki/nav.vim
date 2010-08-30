" vim: fdm=marker
" {{{1
" Copyright: 2010 Javier Rojas <jerojasro@devnull.li>
"
" License:
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 2 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" ftplugin to navigate ikiwiki links from within vim
"
" Author: Javier Rojas <jerojasro@devnull.li>
" Version:  1.0
" Last Updated: FIXME
" URL: TODO FIXME
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
"
" }}}1

let s:wl_pat = '\v\[\[[^\!\]][^\[\]]*\]\]'

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
function! s:WikiLinkText() " {{{1
  let NOT_FOUND = ''

  let ccol = col('.')
  let cline = line('.')
  let ikilink_ini = searchpos('\%(^\|[^\\]\)\zs\[\[\ze\($\|[^!]\)', 'bcnW')
  call cursor(cline, ccol - 1)
  let ikilink_end = searchpos('\]\]', 'cnW')
  call cursor(cline, ccol)
  let next_ikilink_ini = searchpos('\%(^\|[^\\]\)\zs\[\[', 'nW')
  call cursor(cline, ccol - 1)
  let prev_ikilink_end = searchpos('\]\]', 'bnW')
  call cursor(cline, ccol)

  " check that we are between some [[ ]]
  if (ikilink_ini[0] == 0 && ikilink_ini[1] == 0)
        \ || (ikilink_end[0] == 0 && ikilink_end[1] == 0)
    return NOT_FOUND
  endif

  " check that we are not confusing the ikilink opening with the one of a
  " previous ikilink
  "
  " [[yaddayadda]] blabla blaCURSOR_HERE
  if prev_ikilink_end[0] != 0 && prev_ikilink_end[1] != 0
        \ && ikilink_ini[0] < prev_ikilink_end[0]
        \ || (ikilink_ini[0] == prev_ikilink_end[0]
        \     && ikilink_ini[1] < prev_ikilink_end[1])
    return NOT_FOUND
  endif

  " check that we are not confusing the ikilink closing with the one of a
  " previous ikilink
  "
  " blaCURSOR_HERE blabla [[yaddayadda]]
  if next_ikilink_ini[0] != 0 && next_ikilink_ini[1] != 0
        \ && ikilink_end[0] > next_ikilink_ini[0]
        \ || (ikilink_end[0] == next_ikilink_ini[0]
        \     && ikilink_end[1] > next_ikilink_ini[1])
    return NOT_FOUND
  endif

  let st = 1
  if ikilink_end[0] == ikilink_ini[0]
    let st = ikilink_ini[1] + 1
  endif
  return matchlist(getline(ikilink_end[0]), '\([^|]\{-}\)]]', st)[1]
endfunction " }}}1

" {{{1 searches for the best conversion of link_text to a path in the
" filesystem, given the path 'real_path' as a prefix, and checking all the
" path elements in 'link_text' against the filesystem contents in a
" case-insensitive fashion
"
" returns a list of one or two 3-tuple, each one of them containing: the
" existing path, the path that needs to be created, and the filename
" corresponding to the wiki link
"
" when the file exists, its path is in the first position of the first tuple,
" and the second and third positions are empty. The function only returns one
" tuple in this case
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
"
" TODO FIXME XXX this thing is not checking for non-existent directories
" properly
function! ikiwiki#nav#BestLink2FName(real_path, link_text) " {{{1
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
      " we can't match the given link with the files in the current real path,
      " so return to ask caller to give us another real_path
      return [[existent_path, dirs, page_fname],
            \ [existent_path, dirs.'/'.page_dname, 'index.mdwn']]
    endif

    " cdir exists, put it into the existent path, remove it from the beggining
    " of the link (dirs)
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
  " 1. check for (dirs)/page
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
endfunction " }}}1

" {{{1 returns all the possible subpaths of base_path, as a list
"
" Example: GenPosLinkLoc('/home/a/wiki/dir1/dir2') would
" return ['/home/a/wiki/dir1/dir2', '/home/a/wiki/dir1', '/home/a/wiki',
" '/home/a', '/home', '/']
function! ikiwiki#nav#GenPosLinkLoc(base_path) " {{{1
  let base_path = a:base_path
  let pos_locs = []
  call add(pos_locs, base_path)
  while base_path != '/'
    let base_path = fnamemodify(base_path, ':h')
    call add(pos_locs, base_path)
  endwhile
  return pos_locs
endfunction " }}}1

" {{{1 Opens the file associated with the WikiLink currently under the cursor
"
" If no file can be found, prints a messages, and does nothing
"
function! ikiwiki#nav#GoToWikiPage() " {{{1
  let wl_text = s:WikiLinkText()
  if wl_text == ''
    echo "No wikilink found under the cursor"
    return
  endif
  if wl_text =~ '^/'
    let wl_text = strpart(wl_text, 1)
    let dirs_tocheck = reverse(ikiwiki#nav#GenPosLinkLoc(expand('%:p:h')))
  else
    let dirs_tocheck = ikiwiki#nav#GenPosLinkLoc(expand('%:p:h').'/'
                                     \ .fnameescape(expand('%:p:t:r')))
  endif
  for _path in dirs_tocheck
    let plinkloc = ikiwiki#nav#BestLink2FName(_path, wl_text)
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
endfunction " }}}1

" {{{1 Moves the cursor to the nearest WikiLink in the buffer
"
" Arguments:
"
"   backwards: an int flag that determines the direction of the wikilink
"   search.
"
"     backwards == 0: look forward
"     backwards == 1: look backwards (surprise!)
"
function! ikiwiki#nav#NextWikiLink(backwards) " {{{1
  let flags = 'W'
  if (a:backwards)
    let flags = flags . 'b'
  endif
  call search(s:wl_pat, flags)
endfunction " }}}1


