require 'fluent/plugin/parser'
require 'fluent/env'
require 'fluent/time'

require 'yajl'
require 'json'

module Fluent
  module Plugin
    class JSONParser < Parser
      Plugin.register_parser('json_no_nesting', self)

      config_set_default :time_key_no_nesting, 'time'
      config_param :json_parser_no_nesting, :enum, list: [:oj, :yajl, :json], default: :oj

      config_set_default :time_type_no_nesting, :float

      def configure(conf)
        if conf.has_key?('time_format')
          conf['time_type_no_nesting'] ||= 'string'
        end

        super
        @load_proc, @error_class = configure_json_parser(@json_parser_no_nesting)
      end

      def configure_json_parser(name)
        case name
        when :oj
          require 'oj'
          Oj.default_options = Fluent::DEFAULT_OJ_OPTIONS
          [Oj.method(:load), Oj::ParseError]
        when :json then [JSON.method(:load), JSON::ParserError]
        when :yajl then [Yajl.method(:load), Yajl::ParseError]
        else
          raise "BUG: unknown json parser specified: #{name}"
        end
      rescue LoadError
        name = :yajl
        log.info "Oj is not installed, and failing back to Yajl for json parser" if log
        retry
      end

      def parse(text)
        r = @load_proc.call(text)
        time, record = convert_values(parse_time(r), r)
        record.each do |key, value|
          record[key] = record[key].to_json if record[key].is_a?(Hash)
        end
        yield time, record
      rescue @error_class
        yield nil, nil
      end

      def parser_type
        :text
      end

      def parse_io(io, &block)
        y = Yajl::Parser.new
        y.on_parse_complete = ->(record){
          block.call(parse_time(record), record)
        }
        y.parse(io)
      end
    end
  end
end
