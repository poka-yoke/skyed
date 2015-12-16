module Skyed
  # This module encapsulates all the create command steps.
  module Check
    class << self
      def execute(_global_options, options, args)
        settings(options)
        elb = login('elb')
        original_health_check = Skyed::AWS::ELB.get_health_check(args[0], elb)
        reduce_health_check(args[0], original_health_check, elb)
        wait_for_backend_restart(args[0], args[1], options)
        Skyed::AWS::ELB.set_health_check(args[0], original_health_check, elb)
      end

      def wait_for_backend_restart(elb_name, instance_name, opts)
        ow = settings(opts)
        instance_id = instance_by_name(instance_name, ow)
                      .ec2_instance_id
        elb = login('elb')
        wait = opts[:wait_interval] || 0
        timeout = opts[:timeout] || 0
        [true, false].each do |op|
          wait_for_backend(elb_name, instance_id, elb, op, wait, timeout)
        end
      end

      def instance_by_name(name, ow)
        Skyed::AWS::OpsWorks
          .instance_by_name(name, Skyed::Settings.stack_id, ow)
      end

      def wait_for_backend(
        elb_name, instance_id, elb, *other_args)
        ok, wait, timeout = other_args
        time = 0
        until ok == Skyed::AWS::ELB.instance_ok?(elb_name, instance_id, elb) ||
              time >= timeout
          Kernel.sleep(wait)
          time += wait
        end
      end

      def reduce_health_check(elb_name, original_health_check, elb = nil)
        elb = login('elb') if elb.nil?
        new_health_check = original_health_check.clone
        new_health_check.timeout = 2
        new_health_check.interval = 5
        new_health_check.unhealthy_threshold = 2
        new_health_check.healthy_threshold = 2
        Skyed::AWS::ELB.set_health_check(elb_name, new_health_check, elb)
      end

      def settings(options)
        ow = login('ow')
        Skyed::Settings.stack_id = Skyed::AWS::OpsWorks.stack(
          options[:stack], ow)[:stack_id]
        Skyed::Settings.layer_id = Skyed::AWS::OpsWorks.layer(
          options[:layer], ow)[:layer_id]
        ow
      end

      def login(kind = 'elb')
        Skyed::Init.credentials if Skyed::Settings.empty?
        result = Skyed::AWS::ELB.login if kind == 'elb'
        result = Skyed::AWS::OpsWorks.login if kind == 'ow'
        result
      end
    end
  end
end
