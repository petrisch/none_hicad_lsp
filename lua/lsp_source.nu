def main [
    --json # To get the name and description as value pairs
    --names # To request a list of names only
    --description # To request a list of descritions only
    --sources: string = "" # A list of sources with the lsp information in a json format
    --table: string = "" # When source is an excel file, this is the table register
    --column: string = "" # Required when asking for the column only
    --name_column: string = "" # Required when asking for a json
    --description_column: string = "" # Required when asking for a json
    --version
    ] {

if $version {
  "0.0.4" } else {
  let sourceslist = get_sources_list $sources 
  if $json {
      get_entries_as_json $sourceslist $table $name_column $description_column | to json -r | into string
    } else if $names {
      let lsps = get_entries_as_list $sourceslist $table $column
      if $names {
        $lsps|  wrap 'Names' | to csv -n | into string
      } else if $description {
        $lsps|  wrap 'Description' | to csv -n | into string
      } else {
        echo "Please define what you want to get"
   }
  }
  }
}

def get_sources_list [sources] {
      $sources | from json | get sources
}

def get_key_value_pairs_from_source [source table name_column description_column] {
    let t = {}
    let td = {}
    let tab = (open $source | get $table | skip 2)
    let list = ($tab | each {|e| ($t | insert ($e | get $name_column) ($e | get $description_column))} | flatten)
    $list
}

def get_entries_as_json [sourceslist table name_column description_column] {
      # In form 
      # let lsp_source = '{
      #     "ATYP": "Antriebskasten",
      #     "MNAM": "",
      #  }'
      let lsp_source = []
      $lsp_source | append ($sourceslist | each {|source| (get_key_value_pairs_from_source $source $table $name_column $description_column)}) | flatten
}

def get_entries_as_list [sourceslist table column] {
      let lsp_source = []
      let lsps = ($lsp_source | append ( $sourceslist | each {|source| get_list_from_source $source $table $column}) | flatten)
      $lsps
}

def get_list_from_source [source table column] {
    let list = (open $source | get $table | get $column | skip 2)
  # print $list
    $list
}
