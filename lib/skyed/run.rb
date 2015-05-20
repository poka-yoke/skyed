module Skyed
  # This module encapsulates all the run command steps.
  module Run
    class << self
      def execute(global_options, options, args)
        if !options.nil? && options.key?(:stack) && !options[:stack].nil?
          run(global_options, options, args)
        else
          recipes = check_recipes_exist(args)
          check_vagrant
          execute_recipes(Skyed::AWS::OpsWorks.login, recipes)
        end
      end

      def run(_global_options, options, args)
        check_run_options(options)
        ow = login
        Skyed::Settings.stack_id = stack(ow, options)
        Skyed::Settings.layer_id = layer(ow, options)
        instances = Skyed::AWS::OpsWorks.running_instances(
          { layer_id: Skyed::Settings.layer_id },
          ow)
        update_custom_cookbooks(ow, Skyed::Settings.stack_id, instances,
                                options[:wait_interval])
        execute_recipes(ow, args, instances, options)
      end

      def update_custom_cookbooks(ow, stack_id, instances, wait = 0)
        status = Skyed::AWS::OpsWorks.deploy(
          stack_id: stack_id,
          command: { name: 'update_custom_cookbooks' },
          instance_ids: instances,
          client: ow,
          wait_interval: wait)
        fail 'Deployment failed' unless status[0] == 'successful'
      end

      def layer(ow, options)
        layer = Skyed::AWS::OpsWorks.layer_by_id(options[:layer], ow)
        msg = "There's no such layer with id #{options[:layer]}"
        fail msg unless layer
        layer[:layer_id]
      end

      def stack(ow, options)
        stack = Skyed::AWS::OpsWorks.stack_by_id(options[:stack], ow)
        msg = "There's no such stack with id #{options[:stack]}"
        fail msg unless stack
        stack[:stack_id]
      end

      def login
        Skyed::Init.credentials if Skyed::Settings.empty?
        Skyed::AWS::OpsWorks.login
      end

      def check_run_options(options)
        msg = 'Specify stack and layer or initialize for local management'
        fail msg unless options[:stack] && options[:layer]
      end

      def check_vagrant
        output = `cd #{Skyed::Settings.repo} && vagrant status`
        msg = 'Vagrant failed'
        fail msg unless $CHILD_STATUS.success?
        msg = 'Vagrant machine is not running'
        fail msg unless output =~ /running/
      end

      def check_recipes_exist(args)
        recipes = args.select { |recipe| recipe_in_cookbook(recipe) }
        msg = "Couldn't found #{args - recipes} recipes in repository"
        fail msg unless recipes == args
        recipes
      end

      def execute_recipes(ow, recipes, instances = nil, opts = {})
        args = {
          stack_id: Skyed::Settings.stack_id,
          command: { name: 'execute_recipes', recipes: recipes },
          instance_ids: instances,
          client: ow,
          wait_interval: opts[:wait_interval] || 0
        }
        args[:custom_json] = opts[:custom_json] if opts.key? :custom_json
        status = Skyed::AWS::OpsWorks.deploy(args)
        fail 'Deployment failed' unless status[0] == 'successful'
      end

      def recipe_in_cookbook(recipe)
        cookbook, recipe = recipe.split('::')
        recipe = 'default' if recipe.nil?
        File.exist?(
          File.join(
            Skyed::Settings.repo,
            cookbook,
            'recipes',
            "#{recipe}.rb"))
      end
    end
  end
end
