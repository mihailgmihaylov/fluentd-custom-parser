# fluentd-custom-parser

## Summary and purpose

Since FluentD version 0.14 (td-agent3), the parser plugin is native to fluentd.
You can just use all the standard parsing formates described in:
http://docs.fluentd.org/v0.14/articles/parser-plugin-overview

However, if you have an odd case scenario in which you have to use a bit different behaviour of the parsers 
or entierly new parsing behaviour, you can write your own parser plugin as described:
http://docs.fluentd.org/v0.14/articles/api-plugin-parser

This repo shows and example of a custom fluentd parser plugin and gives tips how to create your own.

In the plugin `parser_json_no_nesting.rb`, the default parser json plugin has been tuned so that it does not perform nested parsin of JSON strings.

## How it was created

The `json_no_nesting` parser plugin is based on the default fluentd json parser plugin:
https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/parser_json.rb

The default plugin uses json ruby library and [JSON.parse](http://ruby-doc.org/stdlib-2.0.0/libdoc/json/rdoc/JSON.html) methood. 
If cannot be seen referenced directly in the plugin however this is how the actual JSON parsing is performed.
You can add different functionalities to your parser for example 
max_nesting (max_nesting: The maximum depth of nesting allowed in the data structures from which JSON is to be generated.)
indent (a string used to indent levels) and others.

In our case, we take the default parser and add a section in the code that sets the parsed json hash to simple string.

**Example:**

Parsed JSON:
```
{
   "sample": {
        "someitem": {
            "thesearecool": [
                {
                    "neat": "wow"
                },
                {
                    "neat": "tubular"
                }
            ]
        }
    }
}
```

After parsing with json_no_nesting:

```
{
   "sample": {
        "someitem": "{\"thesearecool\": [{ \"neat\": \"wow\" }, { \"neat\": \"tubular\" }] }" 
    } 
}
```

This may be useful in some cases in which you do not want to send to Elasticsearch (or other) a record with too many parsed data.

## How to use 

### Installation
The parser can be embedded in a gem or just used as a standard fluentd plugin and placed inside the plugin directory.

### Usage
Once installed on your system, just reference the parser in the source tag:

```
<source>
    @type tail
    format json_no_nesting
    tag sample_tag 
    path /var/log/logfile.log
    pos_file /var/lib/pos/logfile.log.pos
</source>
```

If the records inside your logfile are JSON records in a single line, they will be parsed without nesting.
