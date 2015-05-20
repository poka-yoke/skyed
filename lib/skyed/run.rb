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
        status = Skyed::AWS::OpsWorks.wait_for_deploy(ow.create_deployment(
          Skyed::AWS::OpsWorks.generate_deploy_params(
            stack_id,
            { name: 'update_custom_cookbooks' },
            instance_ids: instances)), ow, wait)
        fail 'Deployment failed' unless status[0] == 'successful'
      end

      def layer(ow, options)
        layers = ow.describe_layers(stack_id: options[:stack])[:layers]
        layer = nil
        layers.each do |layer_reply|
          id = layer_reply[:layer_id]
          layer = id if id == options[:layer]
        end
        msg = "There's no such layer with id #{options[:layer]}"
        fail msg unless layer
        layer
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
        deploy_opts = {}
        deploy_opts[:custom_json] = opts[:custom_json] if opts.key? :custom_json
        deploy_opts[:instance_ids] = instances unless instances.nil?
        status = Skyed::AWS::OpsWorks.wait_for_deploy(ow.create_deployment(
          Skyed::AWS::OpsWorks.generate_deploy_params(
            Skyed::Settings.stack_id,
            { name: 'execute_recipes', recipes: recipes },
            deploy_opts)), ow, opts[:wait_interval] || 0)
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
