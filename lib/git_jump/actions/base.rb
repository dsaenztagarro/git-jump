# frozen_string_literal: true

module GitJump
  module Actions
    # Base class for all actions
    class Base
      attr_reader :config, :database, :repository, :output

      def initialize(config:, database:, repository:, output:)
        @config = config
        @database = database
        @repository = repository
        @output = output
      end

      def execute
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      private

      def project
        @project ||= database.find_or_create_project(
          repository.project_path,
          repository.project_basename
        )
      end

      def project_id
        project["id"]
      end
    end
  end
end
