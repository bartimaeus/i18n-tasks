## 0.7.5

Dynamic key usage inference fixes by [Mikko Koski](https://github.com/rap1ds):

* Append `:` to keys ending with dot '.' (to scan `t('category.' + cat)` as `t('category.:')`)
* Consider keys ending with `:` as match expressions
* Make `@` a valid character for keys (to allow `t("category.#{@cat}"`)

## 0.7.4

* Fix `add-missing --help`
* Fix a minor issue with `health` [#88](https://github.com/glebm/i18n-tasks/issues/88)

## 0.7.3

* New task `translate-tree`
* Bugs fixed: [nil values and Google Translate](https://github.com/glebm/i18n-tasks/issues/85), [config file encoding issue](#82).

## 0.7.2

* i18n-tasks now analyses itself! `internal_locale` setting has been added, that controls i18n-tasks reporting language.
English and Russian are available in this release.

## 0.7.1

* 1.9.3 compatibility

## 0.7.0

New tasks:

* `i18n-tasks health` to display missing and unused keys along with other information
* `i18n-tasks tree-` to manipulate trees
* `i18n-tasks data-` to look up and manipulate locale data
* Better `help` for all commands
* Minor bug fixes

Internally:

* Refactored commands DSL
* `add-missing`, `remove-unused` implemented in terms of the new `tree-` commands

## 0.6.3

* Strict mode added for `unused` and `remove-unused`. When passed `-s` or `--strict`, these tasks will not attempt to infer dynamic key usages, such as `t("category.#{category.key}")`.
* Arrays are now supported as values for Google Translate [#77](https://github.com/glebm/i18n-tasks/issues/77)

## 0.6.2

* New task to show locale data: `i18n-tasks data`
* New output format: `keys`, e.g. `i18n-tasks data -fkeys`
* Fix an issue with a top-level dynamic key breaking unused detection [#75](https://github.com/glebm/i18n-tasks/issues/75)
* Document [magic comment hints](https://github.com/glebm/i18n-tasks#fine-tuning)

## 0.6.1

* Fix Google Translate issue with plural keys and missing billing info error

## 0.6.0

* New output format options for reports: yaml, json, and inspect.
* Templates for config and rspec.
* Keys with values same as base locale have been moved from `missing` into a separate task, `eq-base`.
* `missing` now also shows keys that are present in some locale but not in base locale.
* Terminal output: no more Type column in `missing`, first code usage shown for keys missing base value.
* `relative_roots` configuration key moved to `search.relative_roots`, deprecation warning (removed in the next minor).

## 0.5.4

* ActiveSupport 3 compatibility

## 0.5.3

* Fix Google translate regression
* More robust config output

## 0.5.2

* Ignore lines during search with `config.search.ignore_lines`. Ignores comments by default.
* Fixed minor issues with `i18-tasks config` output.

## 0.5.1

* Fix [conservative router](https://github.com/glebm/i18n-tasks#conservative-router).
* Conservative router is now the default.

## 0.5.0

* internals refactored to use trees everywhere
* type `guide` in `i18n-tasks irb` to learn more about the commands
* (remove-)unused tasks now work per locale
* `ignore` settings are shown on `i18n-tasks config`
* Rubinius 2.2.7 compatibility

## 0.4.5

* Respect tty color setting

## 0.4.4

* Fix google translate issues with plural keys and translating from non-base locale

## 0.4.3

* Ruby 1.9 compatibility

## 0.4.2

* Ruby 1.9.3-compatible again

## 0.4.1

* Improved error messages across the board
* Fixed google translate issue with _html keys [#67](https://github.com/glebm/i18n-tasks/issues/67).

## 0.4.0

* In addition to pattern router, a new conservative router that keeps the keys in place. (See [#57](https://github.com/glebm/i18n-tasks/issues/57))
* `i18n-tasks irb` for debugging
* This release is a major refactoring to use real trees internally (as opposed to nested hashes).
Real trees allow for much easier [traversal](/lib/i18n/tasks/data/tree/traversal.rb).
With these trees, information can be associated with each node, which allows for things like the conservative router.
* Accept keys with dashes (`-`) [#64](https://github.com/glebm/i18n-tasks/issues/64).

## 0.3.11

* Improve plural key handling

## 0.3.10

* New (de)serialization options in config
* `add-missing` placeholder argument can now use %{base_value}.

## 0.3.9

* Fix regression: Remove ActiveSupport::HashWithIndifferentAccess from locale data output

## 0.3.8

* Fix activesupport ~3.x compatibility issue (#45).

## 0.3.7

* Catch Errno::EPIPE to allow `i18n-tasks <command> | head` for large reports
* Improved i18n-tasks config output

## v0.3.6

* fix issue with Google Translate

## v0.3.5

* `config.locales` is now picked up by default from paths do data files. `base_locale` defaults to `en`.

## v0.3.3..v0.3.4

* Bugfixes

## v0.3.2

* Tasks that accept locales now accept them as the first argument(s)

## v0.3.0

* i18n-tasks is a binary now (instead of rake tasks). All tasks / commands now accept various options, and there is no need for as many of them as before.
* Works faster on Rails as it doesn't load anything but the gem, but now requires `base_locale` and `locales` to be set in config.

## v0.2.21..v0.2.22

* `rake i18n:usages[pattern]`
* performance regression fixes

## v0.2.20

* `rake i18n:usages` report

## v0.2.17..v0.2.19

* Bugfixes

## v0.2.16

* Key search extracted into its own class, and a custom scanner can now be provided.
* Removed support for deprecated settings

## v0.2.15

* More robust I18n.t call detection (detect I18n.translate and multiline calls)

## v0.2.14

* Google Translate fixes: preserve interpolations, set correct format based on the key (text or html).

## v0.2.13

* New setting relative_roots for relative key resolution (default: %w(app/views))
* fix google translation attempts to translate non-string keys

## v0.2.11 .. v0.2.12

* New task: `i18n:remove_unused`

## v0.2.5..0.2.10

* config/i18n-tasks.yml now processed with ERB
* can now be used with any ruby apps, not just Rails
* more locale formats are considered valid
* `i18n:missing` accepts locales
* `i18n:missing` supports plural keys

## v0.2.4

* more powerful key pattern matching with sets and backtracking

## v0.2.3

* spreadsheet report, tests run on rbx

## v0.2.2

* improved output with terminal-table

## v0.2.1

* fill tasks renamed, fix symbol key search

## v0.2.0

* 3 more prefill tasks, including Google Translate
* tasks renamed

## v0.1.8

* improved search: no longer uses grep, more robust detection (@natano)

## v0.1.7

* ability to route prefill output via data.write config
* multiple configuration variables renamed (still understands old syntax with deprecation warnings)

## v0.1.6

* New key pattern syntax for i18n-tasks.yml a la globbing

## v0.1.5

* Removed get_locale_data, added data configuration options

## v0.1.4

* Fix relative keys in partials (@paulfioravanti)
* Fix i18n:missing when nothing is missing (@tamtamchik)

## v0.1.3

* detect countable keys as used for unused task
* account for non-string keys coming from yaml (thanks @lichtamberg)

## v0.1.2

* added grep config options (thanks @dmke)
* improved terminal output
