module Skyed
  # This module encapsulates all the list command steps.
  module List
    class << self
      def execute(global_options, options, args)
        db_snapshots(global_options, options, args[1..args.length])
      end

      def db_snapshots(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        snapshots = Skyed::AWS::RDS.list_snapshots(
          options,
          args)
        snapshots.each do |snapshot|
          msg = "#{snapshot.db_snapshot_identifier}"
          msg += " #{snapshot.db_instance_identifier} #{snapshot.snapshot_type}"
          puts msg
        end
      end
    end
  end
end
