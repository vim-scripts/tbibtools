" tbibtools.vim -- bibtex-related utilities (require ruby support)
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tbibtools)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-03-30.
" @Last Change: 2007-06-07.
" @Revision:    0.3.112

if &cp || exists("loaded_tbibtools")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 1
    echoerr 'tlib is required'
    finish
endif
if !has('ruby')
    echoerr 'tbibtools requires compiled-in ruby support'
    finish
end
let loaded_tbibtools = 3

let s:source = expand('<sfile>:p:h:h')

fun! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

" exec 'rubyfile '. s:source .'/ruby/tbibtools.rb'
" exec 'rubyfile '. s:source .'/ruby/tvimtools.rb'

ruby <<EOR
for f in ['tbibtools.rb', 'tvimtools.rb']
    ff = File.join(VIM::evaluate('s:source'), 'ruby', f)
    if File.exists?(ff)
        require ff
    else
        # begin
            require f
        # rescue Exception => e
        #     puts e
        # end
    end
end
EOR

fun! s:GotoItem(entry)
    let lineno = matchstr(a:entry, '\d\+')
    exec lineno
    exec 'norm! '. lineno .'zt'
endf

fun! s:AgentPreviewEntry(world, selected)
    let entry = a:selected[0]
    let bn = winnr()
    exec s:bib_win .'wincmd w'
    call s:GotoItem(entry)
    redraw
    exec bn .'wincmd w'
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:TBibList(args)
    let biblisting = []
    ruby <<EOR
    args = ['--ls', '-l', '"#4{_lineno}: #{author|editor|institution|organization}: #{title|booktitle}"'] + VIM::evaluate("a:args").split(/\s+/)
    lines = TVimTools.new.with_range(1, VIM::evaluate("line('$')").to_i) do |text|
        TBibTools.new.parse_command_line_args(args).bibtex_sort_by(nil, text)
    end
    lines.each do |l|
        l = l.chomp
        l = l[1..-2]
        l.gsub!(/'/, "''")
        VIM::evaluate("add(biblisting, '#{l}')")
    end
EOR
    let s:bib_win = winnr()
    let entry = tlib#InputList('s', 'Select entry', biblisting, [
                \ {'key': 16, 'agent': s:SNR().'AgentPreviewEntry', 'key_name': '<c-p>', 'help': 'Preview entry'},
                \ ])
    if !empty(entry)
        call s:GotoItem(entry)
    endif
endf

" Please see ~/.vim/ruby/tbibtools/index.html for details.
command! -range=% -nargs=? TBibTools ruby
            \ TVimTools.new.process_range(<line1>, <line2>)
            \ {|text| TBibTools.new.parse_command_line_args(<q-args>.split(/\s+/)).bibtex_sort_by(nil, text)}

" This command uses the --ls command line option
command! -nargs=? TBibList call s:TBibList(<q-args>)

