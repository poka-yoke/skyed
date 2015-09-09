module Skyed
  # This module encapsulates all the run command steps.
  module Run
    class << self
      def execute(global_options, options, args)
        recipes = check_recipes_exist(options, args)
        if !options.nil? && options.key?(:stack) && !options[:stack].nil?
          run(global_options, options, recipes)
        else
          check_vagrant
          execute_recipes(Skyed::AWS::OpsWorks.login, recipes)
        end
      end

      def run(_global_options, options, args)
        check_run_options(options)
        ow = settings(options)
        instances = Skyed::AWS::OpsWorks.running_instances(
          { layer_id: Skyed::Settings.layer_id },
          ow)
        update_custom_cookbooks(ow, Skyed::Settings.stack_id, instances,
                                options[:wait_interval])
        execute_recipes(ow, args, instances, options)
      end

      def settings(options)
        ow = login
        Skyed::Settings.stack_id = stack(ow, options)
        Skyed::Settings.layer_id = layer(ow, options)
        ow
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
        layer = Skyed::AWS::OpsWorks.layer(options[:layer], ow)
        msg = "There's no such layer with id #{options[:layer]}"
        fail msg unless layer
        layer[:layer_id]
      end

      def stack(ow, options)
        stack = Skyed::AWS::OpsWorks.stack(options[:stack], ow)
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

      def check_recipes_exist(options, args)
        settings(options)
        if !options.nil? && options.key?(:stack) && !options[:stack].nil?
          recipes = args.select { |recipe| recipe_in_remote(options, recipe) }
        else
          recipes = args.select { |recipe| recipe_in_cookbook(recipe) }
        end
        msg = "Couldn't find #{args - recipes} recipes in repository"
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

      def recipe_in_cookbook(recipe, path = nil)
        path ||= Skyed::Settings.repo
        cookbook, recipe = recipe.split('::')
        recipe = 'default' if recipe.nil?
        File.exist?(
          File.join(
            path,
            cookbook,
            'recipes',
            "#{recipe}.rb"))
      end

      def recipe_in_remote(options, recipe)
        clone = Skyed::Git.clone_stack_remote(
          Skyed::AWS::OpsWorks.stack(options[:stack], login),
          options)
        sleep 60
        puts Dir["#{clone}/*"]
        recipe_in_cookbook(recipe, clone)
      end
    end
  end
end
