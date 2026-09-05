# Pre-built tree-sitter parsers and queries for neovim.
#
# LazyVim runs nvim-treesitter's `main` branch, which compiles every parser
# from source on install/update and therefore needs a C toolchain and the
# tree-sitter CLI in nvim's environment. Installing this package instead puts
# a ready-made parser set at /run/current-system/sw/share/nvim/site, which
# lua/plugins/treesitter.lua in ~/.dotfiles points nvim-treesitter at via
# `install_dir`, so nothing is ever compiled at runtime.
#
# The trade-off: that directory is read-only, so :TSInstall / :TSUpdate no
# longer work. Hence the default is every parser nvim-treesitter knows about
# -- the grammars come from cache.nixos.org, so the whole set costs a few
# hundred MiB of disk and almost no build time.
{
  lib,
  runCommandLocal,
  symlinkJoin,
  vimPlugins,

  # Defaults to all ~320 parsers. Override with a list to trade coverage for
  # disk; it must then cover everything LazyVim's `ensure_installed` resolves
  # to for the enabled extras (see ~/.dotfiles/cfgs/config/nvim/lazyvim.json).
  languages ? null,
}:

let
  ts = vimPlugins.nvim-treesitter;

  wanted = if languages == null then lib.attrNames ts.parsers else languages;

  unknown = lib.filter (lang: !(ts.parsers ? ${lang})) wanted;

  # Queries live in derivations separate from the parsers, and both pull in
  # further parsers/queries they inherit from (vue -> css, typescript -> ecma).
  selected = lib.concatMap (
    lang: [ ts.parsers.${lang} ] ++ lib.optional (ts.queries ? ${lang}) ts.queries.${lang}
  ) wanted;

  withDependencies =
    plugin: [ plugin ] ++ lib.concatMap withDependencies (plugin.dependencies or [ ]);

  site = symlinkJoin {
    name = "nvim-treesitter-site";
    paths = lib.unique (lib.concatMap withDependencies selected);
  };
in

lib.throwIf (unknown != [ ])
  "nvim-treesitter-parsers: no such parser: ${lib.concatStringsSep ", " unknown}"

  (
    runCommandLocal "nvim-treesitter-parsers"
      {
        passthru = {
          inherit site;
          languages = wanted;
        };
        meta = {
          description = "Pre-built tree-sitter parsers and queries on neovim's runtimepath";
          inherit (ts.meta) license;
        };
      }
      ''
        mkdir -p "$out/share/nvim"
        ln -s ${site} "$out/share/nvim/site"
      ''
  )
