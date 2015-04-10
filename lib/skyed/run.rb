module Skyed
  # This module encapsulates all the run command steps.
  module Run
    class << self
      def execute(global_options, options, args)
        puts options
        if !options.nil? && options.key?(:stack) && !options[:stack].nil?
          run(global_options, options, args)
        else
          recipes = check_recipes_exist(args)
          check_vagrant
          execute_recipes(Skyed::Init.ow_client, recipes)
        end
      end

      def run(_global_options, options, args)
        check_run_options(options)
        ow = login
        Skyed::Settings.stack_id = stack(ow, options)
        Skyed::Settings.layer_id = layer(ow, options)
        instances = running_instances(ow, Skyed::Settings.layer_id)
        update_custom_cookbooks(ow, Skyed::Settings.stack_id, instances,
                                options[:wait_interval])
        execute_recipes(ow, args, instances, options[:wait_interval])
      end

      def deploy_status(ow, id)
        deploy = ow.describe_deployments(deployment_ids: [id[:deployment_id]])
        deploy[:deployments].map do |s|
          s[:status]
        end.compact
      end

      def wait_for_deploy(ow, deploy_id, wait = 0)
        status = deploy_status(ow, deploy_id)
        while status[0] == 'running'
          sleep(wait)
          status = deploy_status(ow, deploy_id)
        end
        status
      end

      def update_custom_cookbooks(ow, stack_id, instances, wait = 0)
        command = { name: 'update_custom_cookbooks' }
        wait_for_deploy(ow, ow.create_deployment(
          stack_id: stack_id,
          instance_ids: instances,
          command: command), wait)
      end

      def running_instances(ow, layer_id)
        instances = ow.describe_instances(layer_id: layer_id)
        instances[:instances].map do |instance|
          instance[:instance_id] if instance[:status] != 'stopped'
        end.compact
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
        stacks = ow.describe_stacks[:stacks]
        stack = nil
        stacks.each do |stack_reply|
          id = stack_reply[:stack_id]
          stack = id if id == options[:stack]
        end
        msg = "There's no such stack with id #{options[:stack]}"
        fail msg unless stack
        stack
      end

      def login
        Skyed::Init.credentials
        Skyed::Init.ow_client
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

      def execute_recipes(ow, recipes, instances = nil, wait = 0)
        command = { name: 'execute_recipes', args: { recipes: recipes } }
        deploy_params = { stack_id: Skyed::Settings.stack_id, command: command }
        deploy_params[:instance_ids] = instances unless instances.nil?
        deploy_id = ow.create_deployment(deploy_params)
        wait_for_deploy(ow, deploy_id, wait)
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
