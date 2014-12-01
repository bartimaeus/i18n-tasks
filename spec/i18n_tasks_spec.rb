# coding: utf-8
require 'spec_helper'
require 'fileutils'

describe 'i18n-tasks' do
  delegate :run_cmd, :i18n_task, :in_test_app_dir, to: :TestCodebase

  describe 'health' do
    it 'outputs stats' do
      t     = i18n_task
      stats = in_test_app_dir { t.forest_stats(t.data_forest t.locales) }
      out   = capture_stderr { run_cmd :health }
      stats.values.each do |v|
        expect(out).to include(v.to_s)
      end
    end
  end

  describe 'missing' do
    let (:expected_missing_keys) {
      %w( en.used_but_missing.key en.relative.index.missing
          es.missing_in_es.a
          en.present_in_es_but_not_en.a
          en.hash.pattern_missing.a en.hash.pattern_missing.b
          en.missing_symbol_key en.missing_symbol.key_two en.missing_symbol.key_three
          es.missing_in_es_plural_1.a es.missing_in_es_plural_2.a
          en.missing-key-with-a-dash.key
          en.missing-key-question?.key
          en.fn_comment en.only_in_es
        )
    }
    it 'detects missing' do
      capture_stderr do
        expect(run_cmd :missing).to be_i18n_keys expected_missing_keys
        es_keys = expected_missing_keys.grep(/^es\./)
        # locale argument
        expect(run_cmd :missing, locales: %w(es)).to be_i18n_keys es_keys
        expect(run_cmd :missing, arguments: %w(es)).to be_i18n_keys es_keys
      end
    end
  end

  describe 'eq_base' do
    it 'detects eq_base' do
      capture_stderr do
        expect(run_cmd :eq_base).to be_i18n_keys %w(es.same_in_es.a)
      end
    end
  end

  let(:expected_unused_keys) { %w(unused.a unused.numeric unused.plural).map { |k| %w(en es).map { |l| "#{l}.#{k}" } }.reduce(:+) }
  let(:expected_unused_keys_strict) { expected_unused_keys + %w(hash.pattern.a hash.pattern2.a).map { |k| %w(en es).map { |l| "#{l}.#{k}" } }.reduce(:+) }
  describe 'unused' do
    it 'detects unused' do
      capture_stderr do
        expect(run_cmd :unused).to be_i18n_keys expected_unused_keys
      end
    end

    it 'detects unused (--strict)' do
      capture_stderr do
        expect(run_cmd :unused, strict: true).to be_i18n_keys expected_unused_keys_strict
      end
    end
  end

  describe 'remove_unused' do
    it 'removes unused' do
      in_test_app_dir do
        t = i18n_task
        unused = expected_unused_keys.map { |k| ::I18n::Tasks::SplitKey.split_key(k, 2)[1] }
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be true
          expect(t.key_value?(key, :es)).to be true
        end
        ENV['CONFIRM'] = '1'
        capture_stderr {
          run_cmd :remove_unused
        }
        t.data.reload
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be false
          expect(t.key_value?(key, :es)).to be false
        end
      end
    end
  end

  describe 'normalize' do
    it 'sorts the keys' do
      in_test_app_dir do
        run_cmd :normalize
        en_yml_data = i18n_task.data.reload['en'].select_keys { |_k, node|
          node.data[:path] == 'config/locales/en.yml'
        }
        expect(en_yml_data).to be_present
        en_yml_data.nodes { |nodes|
          next unless nodes.children
          keys = nodes.children.map(&:key)
          expect(keys).to eq keys.sort
        }
      end
    end

    it 'moves keys to the corresponding files as per data.write' do
      in_test_app_dir {
        expect(File).to_not exist 'config/locales/devise.en.yml'
        run_cmd :normalize, pattern_router: true
        expect(YAML.load_file('config/locales/devise.en.yml')['en']['devise']['a']).to eq 'EN_TEXT'
      }
    end
  end

  describe 'xlsx_report' do
    it 'saves' do
      in_test_app_dir {
        capture_stderr { run_cmd :xlsx_report }
        expect(File).to exist 'tmp/i18n-report.xlsx'
        FileUtils.cp('tmp/i18n-report.xlsx', '..')
      }
    end

  end

  describe 'add_missing' do
    it 'default placeholder: key.humanize for base_locale' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']).to be_nil
      }
      run_cmd :add_missing, locales: 'base'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']['key']).to eq I18n.t('i18n_tasks.common.key')
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'ES_TEXT'
      }
    end

    it 'default value: base_value for non-base locale' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :add_missing, locales: 'es'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'EN_TEXT'
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es_plural_1']['a']['one']).to eq 'EN_TEXT'
      }
    end

    it '--value' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :normalize, pattern_router: true
      run_cmd :add_missing, locales: 'all', value: 'TRME'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME'
        expect(YAML.load_file('config/locales/devise.es.yml')['es']['devise']['a']).to eq 'ES_TEXT'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'TRME'
      }
    end

    it '--value with %{value}' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :add_missing, locales: 'all', value: 'TRME %{value}'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME EN_TEXT'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'TRME ES_TEXT'
      }
    end
  end

  describe 'config' do
    it 'prints config' do
      expect(YAML.load(Term::ANSIColor.uncolor(run_cmd :config))).to(
          eq(in_test_app_dir { i18n_task.config_for_inspect })
      )
    end
  end

  describe 'find' do
    it 'prints usages' do
      capture_stderr do
        result = Term::ANSIColor.uncolor(run_cmd :find, arguments: ['used.*'])
        expect(result).to eq(<<-TXT)
used.a 2
  app/views/usages.html.slim:1 p = t 'used.a'
  app/views/usages.html.slim:2 b = t 'used.a'
        TXT
      end
    end
  end


  # --- setup ---
  BENCH_KEYS = 10
  before(:each) do
    gen_data = ->(v) {
      v_num = v.chars.map(&:ord).join('').to_i
      {
          'ca'                     => {'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}"},
          'cb'                     => {'a' => v, 'b' => "#{v}%{i}"},
          'hash'                   => {
              'pattern'  => {'a' => v},
              'pattern2' => {'a' => v},
          },
          'unused'                 => {'a' => v, 'numeric' => v_num, 'plural' => {'one' => v, 'other' => v}},
          'ignore_unused'          => {'a' => v},
          'missing_in_es'          => {'a' => v},
          'missing_in_es_plural_1' => {'a' => {'one' => v, 'other' => v}},
          'missing_in_es_plural_2' => {'a' => {'one' => v, 'other' => v}},
          'same_in_es'             => {'a' => v},
          'ignore_eq_base_all'     => {'a' => v},
          'ignore_eq_base_es'      => {'a' => v},
          'blank_in_es'            => {'a' => v},
          'relative'               => {
              'index' => {
                  'title'       => v,
                  'description' => v,
                  'summary'     => v,
              }
          },
          'numeric'                => {'a' => v_num},
          'plural'                 => {'a' => {'one' => v, 'other' => "%{count} #{v}s"}},
          'devise'                 => {'a' => v},
          'scoped'                 => {'x' => v},
          'very'                   => {'scoped' => {'x' => v}},
          'used'                   => {'a' => v}
      }.tap { |r|
        gen = r["bench"] = {}
        BENCH_KEYS.times { |i| gen["key#{i}"] = v }
      }
    }

    en_data                            = gen_data.('EN_TEXT')
    es_data                            = gen_data.('ES_TEXT').except(
        'missing_in_es', 'missing_in_es_plural_1', 'missing_in_es_plural_2')
    es_data['same_in_es']['a']         = 'EN_TEXT'
    es_data['blank_in_es']['a']        = ''
    es_data['ignore_eq_base_all']['a'] = 'EN_TEXT'
    es_data['ignore_eq_base_es']['a']  = 'EN_TEXT'
    es_data['only_in_es'] = 1
    es_data['present_in_es_but_not_en'] = {'a' => 'ES_TEXT'}

    fs = fixtures_contents.merge(
        'config/locales/en.yml' => {'en' => en_data}.to_yaml,
        'config/locales/es.yml' => {'es' => es_data}.to_yaml,
        # test that our algorithms can scale to the order of {BENCH_KEYS} keys.
        'vendor/heavy.file'     => BENCH_KEYS.times.map { |i| "t('bench.key#{i}') " }.join
    )

    TestCodebase.setup fs
  end

  after do
    TestCodebase.teardown
  end
end
