require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'
require 'i18n/tasks/scanners/ruby_ast_scanner'
require 'i18n/tasks/scanners/scanner_multiplexer'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'
require 'i18n/tasks/scanners/files/caching_file_reader'

module I18n::Tasks
  module UsedKeys
    SEARCH_DEFAULTS = {
        paths:          %w(app/).freeze,
        relative_roots: %w(app/controllers app/helpers app/mailers app/presenters app/views).freeze,
        scanners:       [['::I18n::Tasks::Scanners::RubyAstScanner', only: %w(*.rb)]],
        strict:         true,
    }.tap { |defaults|
      defaults[:scanners] << ['::I18n::Tasks::Scanners::PatternWithScopeScanner',
                              exclude:      defaults[:scanners].map { |(_, opts)| opts[:only] }.reduce(:+).freeze,
                              ignore_lines: {'opal'   => %q(^\s*#(?!\si18n-tasks-use)),
                                             'haml'   => %q(^\s*-\s*#(?!\si18n-tasks-use)),
                                             'slim'   => %q(^\s*(?:-#|/)(?!\si18n-tasks-use)),
                                             'coffee' => %q(^\s*#(?!\si18n-tasks-use)),
                                             'erb'    => %q(^\s*<%\s*#(?!\si18n-tasks-use))}.freeze] }


    ALWAYS_EXCLUDE = %w(*.jpg *.png *.gif *.svg *.ico *.eot *.otf *.ttf *.woff *.woff2 *.pdf *.css *.sass *.scss *.less
                        *.yml *.json *.zip *.tar.gz)

    # Find all keys in the source and return a forest with the keys in absolute form and their occurrences.
    #
    # @param key_filter [String] only return keys matching this pattern.
    # @param strict [Boolean] if true, dynamic keys are excluded (e.g. `t("category.#{ category.key }")`)
    # @return [Data::Tree::Siblings]
    def used_tree(key_filter: nil, strict: nil)
      keys = ((@used_tree ||= {})[strict?(strict)] ||= scanner(strict: strict).keys.freeze)
      if key_filter
        key_filter_re = compile_key_pattern(key_filter)
        keys          = keys.reject { |k| k.key !~ key_filter_re }
      end
      Data::Tree::Node.new(
          key:      'used',
          data:     {key_filter: key_filter},
          children: Data::Tree::Siblings.from_key_occurrences(keys)
      ).to_siblings
    end

    def scanner(strict: nil)
      (@scanner ||= {})[strict?(strict)] ||= begin
        shared_options = search_config.dup
        shared_options.delete(:scanners)
        shared_options[:strict] = strict unless strict.nil?
        log_verbose 'Scanners: '
        Scanners::ScannerMultiplexer.new(
            scanners: search_config[:scanners].map { |(class_name, args)|
              if args && args[:strict]
                fail CommandError.new('the strict option is global and cannot be applied on the scanner level')
              end

              ActiveSupport::Inflector.constantize(class_name).new(
                  config:               merge_scanner_configs(shared_options, args || {}),
                  file_finder_provider: caching_file_finder_provider,
                  file_reader:          caching_file_reader)
            }.tap { |scanners| log_verbose { scanners.map { |s| "  #{s.class.name} #{s.config.inspect}" } * "\n" } })
      end
    end

    def search_config
      @search_config ||= begin
        conf = (config[:search] || {}).deep_symbolize_keys
        if conf[:scanner]
          warn_deprecated 'search.scanner is now search.scanners, an array of [ScannerClass, options]'
          conf[:scanners] = [[conf.delete(:scanner)]]
        end
        if conf[:ignore_lines]
          warn_deprecated 'search.ignore_lines is no longer a global setting: pass it directly to the pattern scanner.'
          conf.delete(:ignore_lines)
        end
        if conf[:include]
          warn_deprecated 'search.include is now search.only'
          conf[:only] = conf.delete(:include)
        end
        merge_scanner_configs(SEARCH_DEFAULTS, conf).freeze
      end
    end

    def merge_scanner_configs(a, b)
      a.deep_merge(b).tap do |c|
        %i(scanners paths relative_roots).each do |key|
          c[key] = a[key] if b[key].blank?
        end
        %i(exclude).each do |key|
          merged = Array(a[key]) + Array(b[key])
          c[key] = merged unless merged.empty?
        end
      end
    end

    def caching_file_finder_provider
      @caching_file_finder_provider ||= Scanners::Files::CachingFileFinderProvider.new(exclude: ALWAYS_EXCLUDE)
    end

    def caching_file_reader
      @caching_file_reader ||= Scanners::Files::CachingFileReader.new
    end

    def used_key_names(strict: nil)
      (@used_key_names ||= {})[strict?(strict)] ||= used_tree(strict: strict).key_names
    end

    # whether the key is used in the source
    def used_key?(key)
      used_key_names(strict: true).include?(key)
    end

    # @return whether the key is potentially used in a code expression such as `t("category.#{ category_key }")`
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    private

    # @param strict [Boolean, nil]
    # @return [Boolean]
    def strict?(strict)
      strict.nil? ? search_config[:strict] : strict
    end

    # keys in the source that end with a ., e.g. t("category.#{ cat.i18n_key }") or t("category." + category.key)
    # @param [String] replacement for interpolated values.
    def expr_key_re(replacement: ':'.freeze)
      @expr_key_re ||= begin
        # disallow patterns with no keys
        ignore_pattern_re = /\A[\.#{replacement}]*\z/
        patterns = used_key_names(strict: false).select { |k|
          k.end_with?('.'.freeze) || k =~ /\#{/.freeze
        }.map { |k|
          pattern = "#{replace_key_exp(k, replacement)}#{replacement if k.end_with?('.'.freeze)}"
          next if pattern =~ ignore_pattern_re
          pattern
        }.compact
        compile_key_pattern "{#{patterns * ','}}"
      end
    end

    # Replace interpolations in dynamic keys such as "category.#{category.i18n_key}".
    # @param key [String]
    # @param replacement [String]
    # @return [String]
    def replace_key_exp(key, replacement)
      scanner = StringScanner.new(key)
      braces = []
      result = []
      while (match_until = scanner.scan_until(/(?:#?\{|})/.freeze) )
        if scanner.matched == '#{'.freeze
          braces << scanner.matched
          result << match_until[0..-3] if braces.length == 1
        elsif scanner.matched == '}'
          prev_brace = braces.pop
          result << replacement if braces.empty? && prev_brace == '#{'.freeze
        else
          braces << '{'.freeze
        end
      end
      result << key[scanner.pos..-1] unless scanner.eos?
      result.join
    end
  end
end
