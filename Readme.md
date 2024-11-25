# None_hicad_lsp

Is a attempt to bring some LSP Information into neovim using none-lsp.
The reason for not doing a real lsp is, that its easier to use none-lsp.
The drawback is, that it only ever will work within neovim.

The main feature is hover information from existing excel files.
In the init.lua one specifies as such:

```lua
require( 'none_hicad_lsp' ).setup({
    lsp = {
       source = {
        "absolutepathtosource",
       },
       table = "nameoftable_or_register_in_excel",
       name_column = "column_of_name",
       description_column = "column_of_description",
       }
})
```

For a start, there is the `./HiCAD_Builtin_2D3DVar.xlsx` file,
that can be used with the Test.mac file.

## Dependencies

I was unable to read a excel file from lua,
thats why it calls a nushell script, that gets the information as strings
into lua. So nushell is a dependency here.

## Current state

- Can get variable infos from a list of sources.
- Gives basic inlay hint info about malformed comments, which is opiniated of course.

Feedback and ideas for more usecases are highly apprecited.

![Demo](./Hover_and_hint.png "Demo")

## Todo

- [x] Get hard coded path to lsp_source.nu script as relative path to config/lua
- [x] Get the word to lookup from the tree-sitter node, so that `$VAR` and `VAR` can equaly be hovered over.
- [ ] Let user specify every column and table per source
- [ ] Make this a external plugin
- [ ] Get rid of nushell as a dependency maybe using nur packager.
- [ ] Get Diagnostics about comments from tree-sitter as well, because of fals-positivs
