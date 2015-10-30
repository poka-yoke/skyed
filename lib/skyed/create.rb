module Skyed
  # This module encapsulates all the create command steps.
  module Create
    @non_rds_options = [:rds, :start, :stack, :layer]
    class << self
      def execute(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        execute_rds(options, args) if options[:rds]
        create_opsworks(options, args) unless options[:rds]
      end

      def start_opsworks(options, ow)
        stopped_instances = Skyed::AWS::OpsWorks.instances_by_status(
          options[:stack], options[:layer], 'stopped', ow)
        return false if stopped_instances.empty?
        Skyed::AWS::OpsWorks.start_instance(
          stopped_instances.first.instance_id,
          ow)
        true
      end

      def check_create_options(options)
        msg = 'Specify stack and layer or initialize for local management'
        fail msg unless options[:stack] && options[:layer]
      end

      def create_opsworks(options, _args)
        check_create_options(options)
        ow = settings(options)
        options[:start] = start_opsworks(options, ow) if options[:start]
        Skyed::AWS::OpsWorks.create_instance(
          Skyed::Settings.stack_id,
          Skyed::Settings.layer_id,
          options[:type],
          ow) unless options[:start]
      end

      def stack(ow, options)
        stack = Skyed::AWS::OpsWorks.stack(options[:stack], ow)
        msg = "There's no such stack with id #{options[:stack]}"
        fail msg unless stack
        stack[:stack_id]
      end

      def layer(ow, options)
        layer = Skyed::AWS::OpsWorks.layer(options[:layer], ow)
        msg = "There's no such layer with id #{options[:layer]}"
        fail msg unless layer
        layer[:layer_id]
      end

      def execute_rds(options, args)
        endpoint = create_new(options, args) if args.length == 1
        endpoint = restore_new(options, args) if args.length == 2
        puts endpoint
      end

      def restore_new(options, args)
        Skyed::AWS::RDS.create_instance_from_snapshot(
          args[0],
          args[1],
          options.select { |k| ! @non_rds_options.include? k })
      end

      def create_new(options, args)
        Skyed::AWS::RDS.create_instance(
          args[0],
          options.select { |k| ! @non_rds_options.include? k })
      end

      def settings(options)
        ow = login
        Skyed::Settings.stack_id = stack(ow, options)
        Skyed::Settings.layer_id = layer(ow, options)
        ow
      end

      def login
        Skyed::Init.credentials if Skyed::Settings.empty?
        Skyed::AWS::OpsWorks.login
      end
    end
  end
end
