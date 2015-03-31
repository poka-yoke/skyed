module Skyed
  # This module encapsulates all the run command steps.
  module Run
    class << self
      def execute(_global_options, _options, args)
        recipes = args.select { |recipe| recipe_in_cookbook(recipe) }
        msg = "Couldn't found #{args - recipes} recipes in repository"
        fail msg unless recipes == args
        output = `cd #{Skyed::Settings.repo} && vagrant status`
        msg = 'Vagrant failed'
        fail msg unless $CHILD_STATUS.success?
        msg = 'Vagrant machine is not running'
        fail msg unless output =~ /running/
        execute_recipes(recipes)
      end

      def execute_recipes(recipes)
        ow = ow_client
        command = { name: 'execute_recipes', args: { 'recipes' => recipes } }
        ow.create_deployment(
          stack_id: Skyed::Settings.stack_id,
          command: command)
      end

      def ow_client(
        access = Skyed::Settings.access_key,
        secret = Skyed::Settings.secret_key)
        AWS::OpsWorks::Client.new(
          access_key_id: access,
          secret_access_key: secret)
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
