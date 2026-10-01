# frozen_string_literal: true

require 'singleton'

UNSUPPORTED_PLATFORMS = ['darwin', 'windows'].freeze

# Gives access to the Litmus helpers (run_shell, apply_manifest, ...) outside of examples.
class LitmusHelper
  include Singleton
  include PuppetLitmus
end

Dir[File.join(__dir__, 'support', 'acceptance', '**', '*.rb')].sort.each { |helper| require helper }

RSpec.configure do |c|
  c.include JavaAcceptanceHelpers

  c.before :suite do
    JavaAcceptanceHelpers.prepare_target
  end
end
