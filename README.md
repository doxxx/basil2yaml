# basil2yaml

Converts Basil .recipe files to Paprika YAML format.

Basil .recipe files can be extracted using a zip program from a Basil export file that has been exported to Dropbox or email.

## Building

This project uses Swift 4 and the Swift Package Manager to build.

To compile:

```
swift build -c release --static-swift-stdlib
```

The compiled binary canbe found at  `.build/release/basil2yaml`.

## Usage

Execute `basil2yaml` on its own or with a subcommand and the `--help` option to get help. The application provides two subcommands:

* `convert`
* `combine`

Note that Paprika only accepts files with the extension `.yml`.

### convert command

The `convert` command converts one or more Basil .recipe files to Paprika YAML format. It supports the following options:

* `--output-dir` -- Output YAML files into the specified directory (default: current directory).
* `--use-recipe-name` -- Use the actual name of the recipe as the YAML file name, instead of simply appending `.yml` to the original `.recipe` file name.
* `--exclude-images` -- Don't include images in the YAML files.
* `--combine` -- Combine all the recipes into a single YAML file in list form, writing the output to the console.

Examples:

```
basil2yaml --output-dir converted/ --use-recipe-name basil/*.recipe
```

```
basil2yaml --combine basil/*.recipe > all.yml
```

### combine command

The `combine` command combines multiple Paprika YAML files into a single YAML file in list form. It supports the following options:

* `--output-file` -- The filename to write the combined recipes to (default: `all.yml`)

Examples:

```
basil2yaml combine converted/*.yml
```

