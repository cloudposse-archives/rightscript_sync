# RightScript Sync

RightScript is a tool to synchronize all scripts in your RightScale account with your local file system. 

## Installation

Add this line to your application's Gemfile:

    gem 'rightscript_sync'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rightscript_sync

## Usage

    Usage: rightscript-sync options
            --dry-run                    Output the parsed files to STDOUT
            --output-path DIR            Use DIR as output directory
            --account-id ID              RightScale Account ID
            --username USERNAME          RightScale Username
            --password PASSWORD          RightScale Password
        -V, --version                    Display version information
        -h, --help                       Display this screen



## Limitations

Currently, this script only supports downloading of all RightScripts and corresponding attachments. It does not at this time support the ability to synchronize changes made locally to RightScale.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
