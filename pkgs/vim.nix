{vim_configurable, vimPlugins}:

vim_configurable.customize {
    name = "vim";
    vimrcConfig.customRC = ''
    syntax enable
    set smartindent
    set smartcase
    set cursorline
    set visualbell
    set hlsearch
    set incsearch
    set ruler
    set backspace=indent,eol,start
    '';
    vimrcConfig.packages.myVimPackage = with vimPlugins; {
        start = [ vim-nix ];

    };
}