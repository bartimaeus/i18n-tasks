module I18n::Tasks
  module Command
    module DSL
      def self.included(base)
        base.module_eval do
          @dsl = HashWithIndifferentAccess.new { |h, k|
            h[k] = HashWithIndifferentAccess.new
          }
          extend ClassMethods
        end
      end

      def t(*args)
        I18n.t(*args)
      end

      module ClassMethods
        def cmd(name, conf = nil)
          if conf
            conf        = conf.dup
            conf[:args] = (args = conf[:args]) ? args.map { |arg| Symbol === arg ? arg(arg) : arg } : []

            dsl(:cmds)[name] = conf
          else
            dsl(:cmds)[name]
          end
        end

        def arg(ref, *args)
          if args.present?
            dsl(:args)[ref] = args
          else
            dsl(:args)[ref]
          end
        end

        def cmds
          dsl(:cmds)
        end

        def dsl(key)
          @dsl[key]
        end

        # late-bound I18n.t for module bodies
        def t(*args)
          proc { I18n.t(*args) }
        end

        # if class is a module, merge DSL definitions when it is included
        def included(base)
          base.instance_variable_get(:@dsl).deep_merge!(@dsl)
        end
      end
    end
  end
end
