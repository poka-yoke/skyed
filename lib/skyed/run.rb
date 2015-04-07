module Skyed
  # This module encapsulates all the run command steps.
  module Run
    class << self
      def execute(global_options, options, args)
        run(global_options, options, args) unless Skyed::Settings.empty?
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

      def run(_global_options, _options, _args)
      end

      def execute_recipes(recipes)
        ow = Skyed::Init.ow_client
        command = { name: 'execute_recipes', args: { 'recipes' => recipes } }
        ow.create_deployment(
          stack_id: Skyed::Settings.stack_id,
          command: command)
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
