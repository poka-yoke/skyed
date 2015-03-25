module Skyed
  # This module encapsulates all the deploy command steps.
  module Run
    class << self
      def execute(_global_options, _options, args)
        recipes = args.select { |recipe| recipe_in_cookbook(recipe) }
        msg = "Couldn't found #{args - recipes} recipes in repository"
        fail msg unless recipes == args
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
