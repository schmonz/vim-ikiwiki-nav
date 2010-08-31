" vim: fdm=marker
" {{{1 LICENSE
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
" Last Updated: 2010-02-08
" URL: http://git.devnull.li/cgi-bin/gitweb.cgi?p=ikiwiki-nav.git;a=blob;f=ftplugin/ikiwiki_nav.vim;hb=HEAD
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

if exists("b:loaded_ikiwiki_nav")
  finish
endif
let b:loaded_ikiwiki_nav = 1

let s:save_cpo = &cpo
set cpo&vim

" command definitions {{{1
if !exists(":IkiJumpToPage")
  command IkiJumpToPage :call ikiwiki#nav#GoToWikiPage()
endif
if !exists(":IkiNextWikiLink")
  command -nargs=1 IkiNextWikiLink :call ikiwiki#nav#NextWikiLink(<args>)
endif
" }}}1

" mapping definitions {{{1
if !(hasmapto(':IkiJumpToPage'))
  noremap <unique> <buffer> <CR> :IkiJumpToPage<CR>
endif
if !(hasmapto(':IkiNextWikiLink'))
  noremap <buffer> <C-j> :IkiNextWikiLink 0<CR>
  noremap <buffer> <C-k> :IkiNextWikiLink 1<CR>
endif

noremap <buffer> <Backspace> <C-o>
" }}}1

let &cpo = s:save_cpo
