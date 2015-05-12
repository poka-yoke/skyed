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
        instances = running_instances(ow, Skyed::Settings.layer_id)
        update_custom_cookbooks(ow, Skyed::Settings.stack_id, instances,
                                options[:wait_interval])
        execute_recipes(ow, args, instances, options)
      end

      def wait_for_deploy(ow, deploy_id, wait = 0)
        status = Skyed::AWS::OpsWorks.deploy_status(deploy_id, ow)
        while status[0] == 'running'
          sleep(wait)
          status = Skyed::AWS::OpsWorks.deploy_status(deploy_id, ow)
        end
        fail 'Deployment failed' unless status[0] == 'successful'
        status
      end

      def update_custom_cookbooks(ow, stack_id, instances, wait = 0)
        command = Skyed::AWS::OpsWorks.generate_command_params(
          name: 'update_custom_cookbooks')
        wait_for_deploy(ow, ow.create_deployment(
          Skyed::AWS::OpsWorks.generate_deploy_params(
            stack_id,
            command,
            instance_ids: instances)), wait)
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

      def execute_recipes(
        ow,
        recipes,
        instances = nil,
        options = {})
        options[:wait_interval] ||= 0
        options[:custom_json] ||= ''
        deploy_id = ow.create_deployment(
          execute_params(recipes, instances, options[:custom_json]))
        wait_for_deploy(ow, deploy_id, options[:wait_interval])
      end

      def execute_params(recipes, instances, custom_json)
        command = Skyed::AWS::OpsWorks.generate_command_params(
          name: 'execute_recipes',
          recipes: recipes)
        options = {}
        options[:instance_ids] = instances unless instances.nil?
        options[:custom_json] = custom_json unless custom_json.empty?
        Skyed::AWS::OpsWorks.generate_deploy_params(
          Skyed::Settings.stack_id,
          command,
          options)
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
