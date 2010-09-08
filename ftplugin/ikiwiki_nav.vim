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

" {{{1 constants for choosing how to open the selected file
let g:IKI_BUFFER = 0
let g:IKI_HSPLIT = 1
let g:IKI_VSPLIT = 2
let g:IKI_TAB = 3
" command definitions {{{1
if !exists(":IkiJumpToPageCW")
  command IkiJumpToPageCW :call ikiwiki#nav#GoToWikiPage(0, g:IKI_BUFFER)
endif
if !exists(":IkiJumpToPageHW")
  command IkiJumpToPageHW :call ikiwiki#nav#GoToWikiPage(0, g:IKI_HSPLIT)
endif
if !exists(":IkiJumpToPageVW")
  command IkiJumpToPageVW :call ikiwiki#nav#GoToWikiPage(0, g:IKI_VSPLIT)
endif
if !exists(":IkiJumpToPageNT")
  command IkiJumpToPageNT :call ikiwiki#nav#GoToWikiPage(0, g:IKI_TAB)
endif
if !exists(":IkiJumpOrCreatePageCW")
  command IkiJumpOrCreatePageCW :call ikiwiki#nav#GoToWikiPage(1, g:IKI_BUFFER)
endif
if !exists(":IkiJumpOrCreatePageHW")
  command IkiJumpOrCreatePageHW :call ikiwiki#nav#GoToWikiPage(1, g:IKI_HSPLIT)
endif
if !exists(":IkiJumpOrCreatePageVW")
  command IkiJumpOrCreatePageVW :call ikiwiki#nav#GoToWikiPage(1, g:IKI_VSPLIT)
endif
if !exists(":IkiJumpOrCreatePageNT")
  command IkiJumpOrCreatePageNT :call ikiwiki#nav#GoToWikiPage(1, g:IKI_TAB)
endif
if !exists(":IkiNextWikiLink")
  command IkiNextWikiLink :call ikiwiki#nav#NextWikiLink(0)
endif
if !exists(":IkiPrevWikiLink")
  command IkiPrevWikiLink :call ikiwiki#nav#NextWikiLink(1)
endif
" }}}1

" mapping definitions {{{1
if !(hasmapto(':IkiJumpToPageCW'))
  noremap <unique> <buffer> <CR> :IkiJumpToPageCW<CR>
endif
if !(hasmapto(':IkiJumpOrCreatePage'))
  noremap <unique> <buffer> <Leader>n :IkiJumpOrCreatePage<CR>
endif
if !(hasmapto(':IkiNextWikiLink'))
  noremap <buffer> <C-j> :IkiNextWikiLink 0<CR>
  noremap <buffer> <C-k> :IkiNextWikiLink 1<CR>
endif

noremap <buffer> <Backspace> <C-o>
" }}}1

let &cpo = s:save_cpo
