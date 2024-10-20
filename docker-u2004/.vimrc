"静音
set t_vb=
set visualbell

set nocompatible
set backspace=indent,eol,start
"=====================================================  常用设置  ===========================================
set ignorecase
set hidden
set relativenumber number
set nowrap

"=====================================================  缩进  ===========================================
set expandtab
set tabstop=4
set shiftwidth=4

"=====================================================  tags  ===========================================
set tags=./tags,./../tags,./../../tags,./../../../tags,./../../../../tags


"let g:clang_library_path='/opt/homebrew/opt/llvm/lib'

"=====================================================  文件树占比  ===========================================
"" 设置 Lexp 窗口占据当前窗口宽度的百分比
"let g:Lexp_window_width = 30
"
"" 定义函数，用于在打开 Lexp 窗口后设置窗口大小和布局
"function! LexpResize()
"    " 打开 Lexp 窗口并分割为垂直窗口 
"    Lexp
"    resize g:Lexp_window_width
"
"    " 将 Lexp 窗口移到左边
"    wincmd H
"endfunction
"
"" 在 Lexp 打开后调用 LexpResize 函数设置窗口大小和布局
"autocmd FileType netrw :call LexpResize()


"=====================================================  jumps  ===========================================
function! GotoJump()
  jumps
  let j = input("Please select your jump: ")
  if j != ''
    let pattern = '\v\c^\+'
    if j =~ pattern
      let j = substitute(j, pattern, '', 'g')
      execute "normal " . j . "\<c-i>"
    else
      execute "normal " . j . "\<c-o>"
    endif
  endif
endfunction
nmap <Leader>j :call GotoJump()<CR>


"=====================================================  高亮  ===========================================
syntax on
set hlsearch
"set termguicolors

hi DiffAdd    ctermbg=235  ctermfg=108  guibg=#262626 guifg=#87af87 cterm=reverse gui=reverse
" 变化的行
hi DiffChange ctermbg=235  ctermfg=103  guibg=#262626 guifg=#8787af cterm=reverse gui=reverse
" 删除的行
hi DiffDelete ctermbg=235  ctermfg=131  guibg=#262626 guifg=#af5f5f cterm=reverse gui=reverse
" 变化的文字
hi DiffText   ctermbg=235  ctermfg=208  guibg=#262626 guifg=#ff8700 cterm=reverse gui=reverse

"set termguicolors

"=====================================================  状态栏  ===========================================
set ruler
set laststatus=2 

set statusline=%F\ Line:%l\ %P
set statusline=
set statusline+=%7*\[%n]                                  "buffernr
set statusline+=%1*\ %<%F\                                "File+path
set statusline+=%2*\ %y\                                  "FileType
set statusline+=%3*\ %{''.(&fenc!=''?&fenc:&enc).''}      "Encoding
set statusline+=%3*\ %{(&bomb?\",BOM\":\"\")}\            "Encoding2
set statusline+=%4*\ %{&ff}\                              "FileFormat (dos/unix..) 
set statusline+=%5*\ %{&spelllang}\%{HighlightSearch()}\  "Spellanguage & Highlight on?
set statusline+=%8*\ %=\ row:%l/%L\ (%03p%%)\             "Rownumber/total (%)
set statusline+=%9*\ col:%03c\                            "Colnr
set statusline+=%0*\ \ %m%r%w\ %P\ \                      "Modified? Readonly? Top/bot.

function! HighlightSearch()
    if &hls
        return 'H'
    else
        return ''
    endif
endfunction


hi User1 guifg=#ffdad8  guibg=#880c0e ctermfg=216 ctermbg=52
hi User2 guifg=#000000  guibg=#F4905C ctermfg=16 ctermbg=209
hi User3 guifg=#292b00  guibg=#f4f597 ctermfg=235 ctermbg=229
hi User4 guifg=#112605  guibg=#aefe7B ctermfg=58 ctermbg=119
hi User5 guifg=#051d00  guibg=#7dcc7d ctermfg=22 ctermbg=114
hi User7 guifg=#ffffff  guibg=#880c0e ctermfg=15 ctermbg=52 cterm=bold
hi User8 guifg=#ffffff  guibg=#5b7fbb ctermfg=15 ctermbg=67
hi User9 guifg=#ffffff  guibg=#810085 ctermfg=15 ctermbg=89
hi User0 guifg=#ffffff  guibg=#094afe ctermfg=15 ctermbg=33



"=====================================================  文件树  ===========================================
hi! link netrwMarkFile Search "高亮显示标记的文件
let g:netrw_localcopydircmd = 'cp -r' "复制目录时用的命令
let g:netrw_bufsettings = 'noma nomod nu relativenjmber  nobl nowrap ro'
let g:netrw_list_hide=''
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_liststyle=3
let g:netrw_keepdir = 0
"autocmd FileType netrw setlocal buflisted=0



if &diff
    let g:netrw_banner = 0
else
    let g:netrw_banner = 0
endif

function! NetrwExpandTree()
    if &ft != 'netrw'
        echo "not netrw filetype"
        return
    endif
    while 1
        let regex = '\v(^(\| )+)\w+\/$(.*\n^\1\|)@!'
        let result = search(regex)
        if result == 0
            return
        endif
        execute "normal \<CR>"
    endwhile
endfunction


function! Locat2parentDir()
    " 如果不是文件直接返回 \|[ ] 开头,文件名不是\/结尾
    let currentLine = getline(".")
    let pattern = '\v^(%(\| )+)'
    "echo currentLine
    if match(currentLine,pattern) <0
        return
    endif
    " 缩进
    let identation = matchlist(currentLine,pattern)[1]
    let parentDirIdentation = substitute(identation,'\v^(.{0,})\| $','\1','')
    "echo parentDirIdentation
    let parentDirPattern = '\v^'.  substitute(parentDirIdentation , '\v\|' , '\\|' , 'g') . '[^ \|]+\/'
    "echo parentDirPattern
    let jpParentResult = search(parentDirPattern,'b')
    return
endfunction

function! NetrwOpenFileToTab()
   echo "1111111"

    " 如果不是文件直接返回 \|[ ] 开头,文件名不是\/结尾
    let currentLine = getline(".")
    let pattern = '\v^(%(\| )+)(\S+)[^$]*%($%(\/)@<!)'
    "echo currentLine
    if match(currentLine,pattern) <0
    echo "not a file "
    return
    endif
    " 文件名
    let fileName = matchlist(currentLine,pattern)[2]
    " 如果是软连接，文件名去掉尾部的@
    let isSoftLink = match(fileName,'\v^.+\@') == 0
    if isSoftLink
    let fileName = substitute(fileName,'\v^(.+)\@','\1','')
    endif
    "echo fileName

    " 跳转到目录节点折叠再展开，keepdir=0的情况下，这个操作会改变pwd，展开后再跳回原来的位置 echo $line
    let ln = line(".")
    call Locat2parentDir()
    execute "normal \<CR>\<CR>"
    execute "normal :" . ln . "\<CR>"
    let fullfilename =  substitute(system("pwd"),'\v^(%(.\n@!)+.)','\1\/' . fileName ,'')
    "echo fullfilename

    " 如果已经有tab了，切换到tab垂直分割读路径，否则tabnew读路径文件， 最后切回来原来的tab
    let tabcount = tabpagenr('$')
    "echo "tabcont :" . tabcount
    if &diff
    let @/ = fileName
    execute "normal :match Search /" . fileName . "/\<CR>"
    if tabcount == 1
    execute "normal :tabnew " . fullfilename . "\<CR>"
    normal! gT
    else
    normal! gt
    execute "normal :vsp " . fullfilename . "\<CR>"
    execute "normal :windo diffthis" . "\<CR>"
    endif
    else
#execute "normal :tabnew " . fullfilename . "\<CR>"
    endif
endfunction

    " au FileType netrw   nnoremap <buffer> <silent> t: if &diff call NetrwOpenFileToTab()<CR> endif
    au FileType netrw nnoremap <buffer> <silent> et :call NetrwExpandTree()<CR>
    au FileType netrw nnoremap <buffer> <silent> zc :call Locat2parentDir()<CR>
    au FileType netrw hi CursorLine gui=underline 
    au FileType netrw au BufEnter <buffer> hi CursorLine gui=underline
    au FileType netrw au BufLeave <buffer> hi clear CursorLine

"=====================================================  git  ===========================================
function! MyDiffEnter()
    execute "normal :windo set noro \n"
    "进入git repostroy  根目录
    let g:GitRepoRoot = substitute(system('git rev-parse --show-toplevel'),'\v\\\/','/','g')
    let g:GitRepoRoot = substitute(g:GitRepoRoot,':','','g')
    let g:GitRepoRoot = substitute(g:GitRepoRoot,'\v^([\\/])@!','/','g')

    "创建补丁生成路径
    let g:diffLeftFile = expand('#:p')
    let g:diffRightFile = expand('%:p')
    let g:hbbGitRoot = expand('#:p:h') . '/hbbGit/'
    let g:diffOrigFile = expand('#:p:h') . '/hbbGit/a/' . fnamemodify(expand('%:p'),':~:.')
    let g:diffLeftFile2 = expand('#:p:h') . '/hbbGit/b/' . fnamemodify(expand('%:p'),':~:.')
    let g:diffPatchFile = expand('#:p:h') . '/hbbGit/patch/' . fnamemodify(expand('%:p'),':~:.') . '.patch'

    silent execute "normal :! mkdir -p " . g:hbbGitRoot . '/a/' . fnamemodify(expand('%:p:h'),':~:.') . "  \n"
    silent execute "normal :! mkdir -p " . g:hbbGitRoot . '/b/' . fnamemodify(expand('%:p:h'),':~:.') . "  \n"
    silent execute "normal :! mkdir -p " . g:hbbGitRoot . '/patch/' . fnamemodify(expand('%:p:h'),':~:.') . "  \n"

    "备份原来的文件
    let cmd =  'cp  "' . g:diffLeftFile . '" "' . g:diffOrigFile .'"'
    silent execute "normal :! " . cmd . " \n"
    "替换掉^M
    "silent! execute "normal :windo %s/$//g"
    "execute "normal :wa \n"

    "移动到top
    execute "normal gg"


    "if expand('%:r') == g:gitRepoRoot
    "    echo "%:r 与 git repostory根目录不对等"   
    "endif
    echo $GIT_EXTERNAL_DIFF



    endfunction
    " 定义 DiffEnter 事件
    autocmd VimEnter * if &diff | call MyDiffEnter() | endif


function! MyDiffLeave()
    if empty($GIT_EXTERNAL_DIFF) ==1
    return
    endif
    execute "normal :!rm -rf  \"" . g:hbbGitRoot . "\" \n"
    endfunction
    au VimLeave * if &diff | call MyDiffLeave() | endif


function! GitStageSelectedLines()
    if &diff
    "保存修改
    silent execute "normal :wa \<CR>"
    "复制修改后的左边文件到补丁生成目录
    let cpLeftCmd =  'yes|cp  -rf "' . g:diffLeftFile . '" "' . g:diffLeftFile2 .'"'
    silent execute "normal :!" . cpLeftCmd." \n"
    "echo cpLeftCmd



    "生成补丁
    let compA = expand(g:diffOrigFile)
let compB = expand(g:diffLeftFile2)
    let cmd = "git diff --no-ext-diff  --no-index \"" . compA . "\" \"" . compB . "\" > \"" . g:diffPatchFile ."\" "
    silent execute "normal :!" . cmd . " \n"
    "替换补丁文件路径
    silent execute 'tabnew '. g:diffPatchFile 
    "silent execute '%s/\v( [ab])(.(hbbGit)@<!)*..[ab]/\1/g'

    if search('\v([+-]{3} )(.(hbbGit)@<!)*..', 'n') > 0
    silent execute '%s/\v([+-]{3} )(.(hbbGit)@<!)*../\1/g'
    endif

    silent execute 'w'
    silent execute 'bd'

    "git stage
    execute "normal :!git apply --whitespace=fix --cached \"" . g:diffPatchFile . "\" \n"

    let cmd2 =  'cp  "' . g:diffLeftFile . '" "' . g:diffOrigFile .'"'
    silent execute "normal :! " . cmd2 . " \n"

    endif
    endfunction

    " 绑定快捷键
    noremap <leader>gs :call GitStageSelectedLines()<CR>

