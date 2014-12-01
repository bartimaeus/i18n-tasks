module I18n::Tasks
  module Command
    module Commands
      module Missing
        include Command::Collection

        enum_opt :missing_types, I18n::Tasks::MissingKeys.missing_keys_types
        cmd_opt :missing_types, enum_list_opt_attr(
            :t, :types=, enum_opt(:missing_types),
            proc { |valid, default| t('i18n_tasks.cmd.args.desc.missing_types', valid: valid, default: default) },
            proc { |invalid, valid| t('i18n_tasks.cmd.errors.invalid_missing_type', invalid: invalid * ', ', valid: valid * ', ', count: invalid.length) })

        cmd :missing,
            args: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.missing'),
            opt:  cmd_opts(:locales, :out_format, :missing_types)

        def missing(opt = {})
          print_forest i18n.missing_keys(opt), opt, :missing_keys
        end

        cmd :translate_missing,
            args: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.translate_missing'),
            opt:  cmd_opts(:locales, :locale_to_translate_from) << cmd_opt(:out_format).except(:short)

        def translate_missing(opt = {})
          missing    = i18n.missing_diff_forest opt[:locales], opt[:from]
          translated = i18n.google_translate_forest missing, opt[:from]
          i18n.data.merge! translated
          log_stderr t('i18n_tasks.translate_missing.translated', count: translated.leaves.count)
          print_forest translated, opt
        end

        DEFAULT_ADD_MISSING_VALUE = '%{value_or_human_key}'

        cmd :add_missing,
            args: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.add_missing'),
            opt:  cmd_opts(:locales, :out_format) <<
                      cmd_opt(:value).merge(desc: proc { "#{cmd_opt(:value)[:desc].call}. #{t('i18n_tasks.cmd.args.default_text', value: DEFAULT_ADD_MISSING_VALUE)}" })

        def add_missing(opt = {})
          forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || DEFAULT_ADD_MISSING_VALUE)
          i18n.data.merge! forest
          log_stderr t('i18n_tasks.add_missing.added', count: forest.leaves.count)
          print_forest forest, opt
        end
      end
    end
  end
end
